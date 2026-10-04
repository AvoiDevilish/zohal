import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_reservation.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/workshop/production_order_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryStore = InventoryStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventoryStore.clear();
  });

  SalesOrder order({int quantity = 10}) {
    return SalesOrder(
      id: 'order-analysis-1',
      customerId: 'customer-1',
      customerName: 'مشتری آزمایشی',
      orderDate: DateTime(2026, 10, 5),
      lines: [
        SalesOrderLine(
          productVariantId: 'energy-bar-100g-ginger',
          productName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
          flavor: 'زنجبیلی',
          packageLabel: '۱۰۰ گرمی',
          quantity: quantity,
          unitSellingPrice: 100000,
          lineTotal: quantity * 100000,
        ),
      ],
      totalAmount: quantity * 100000,
    );
  }

  Future<void> stock(String itemId, String itemName, double quantity, String unit) {
    return inventoryStore.addMovement(
      InventoryMovement(
        id: 'purchase-$itemId',
        itemId: itemId,
        itemName: itemName,
        itemType: itemId.startsWith('pack_') ? 'packaging' : 'rawMaterial',
        quantity: quantity,
        unit: unit,
        movementType: InventoryMovementType.purchase,
        timestamp: DateTime(2026, 10, 5),
      ),
    );
  }

  test('analyzes order and reports date pit as usable byproduct', () async {
    final analyzer = ProductionOrderAnalyzer(inventoryStore: inventoryStore);

    await stock('raw_date_khesht', 'خرما خشت', 1000, 'گرم');
    await stock('raw_walnut_iranian', 'گردو ایرانی', 1000, 'گرم');
    await stock('raw_almond', 'بادام درختی', 1000, 'گرم');
    await stock('raw_peanut', 'بادام زمینی', 1000, 'گرم');
    await stock('raw_sesame', 'کنجد', 1000, 'گرم');
    await stock('raw_ground_ginger', 'پودر زنجبیل', 100, 'گرم');
    await stock('pack_container_100g', 'ظرف ۱۰۰ گرمی', 20, 'piece');
    await stock('pack_label', 'لیبل', 20, 'piece');

    final result = await analyzer.analyze(order());

    expect(result.orderId, 'order-analysis-1');
    expect(result.lines, hasLength(1));
    expect(result.canProduce, isTrue);

    final date = result.lines.single.calculation.findMaterial('raw_date_khesht');
    final pit = result.byproducts.single;

    expect(date, isNotNull);
    expect(date!.quantity, closeTo(773.888889, 0.000001));
    expect(pit.itemId, 'raw_date_pit');
    expect(pit.quantity, closeTo(77.388889, 0.000001));
  });

  test('respects active reservations when checking production readiness', () async {
    final analyzer = ProductionOrderAnalyzer(inventoryStore: inventoryStore);

    await stock('raw_date_khesht', 'خرما خشت', 1000, 'گرم');
    await stock('raw_walnut_iranian', 'گردو ایرانی', 1000, 'گرم');
    await stock('raw_almond', 'بادام درختی', 1000, 'گرم');
    await stock('raw_peanut', 'بادام زمینی', 1000, 'گرم');
    await stock('raw_sesame', 'کنجد', 1000, 'گرم');
    await stock('raw_ground_ginger', 'پودر زنجبیل', 100, 'گرم');
    await stock('pack_container_100g', 'ظرف ۱۰۰ گرمی', 20, 'piece');
    await stock('pack_label', 'لیبل', 20, 'piece');

    await inventoryStore.reserve(
      InventoryReservation(
        id: 'reservation-date',
        itemId: 'raw_date_khesht',
        itemName: 'خرما خشت',
        quantity: 900,
        unit: 'گرم',
        referenceType: 'sales-order',
        referenceId: 'another-order',
        createdAt: DateTime(2026, 10, 5),
      ),
    );

    final result = await analyzer.analyze(order());

    expect(result.canProduce, isFalse);
    expect(
      result.stockCheck.shortages.any(
        (item) => item.materialId == 'raw_date_khesht',
      ),
      isTrue,
    );
  });
}
