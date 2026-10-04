import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/sales/sales_order_store.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';
import 'package:zohal_android_test/core/workshop/production_order_analyzer.dart';
import 'package:zohal_android_test/core/workshop/production_order_execution_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryStore = InventoryStore.instance;
  final orderStore = SalesOrderStore.instance;
  final batchStore = ProductionBatchStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventoryStore.clear();
    await orderStore.clear();
    await batchStore.clear();
  });

  SalesOrder order({SalesOrderStatus status = SalesOrderStatus.readyForProduction}) {
    return SalesOrder(
      id: 'order-execution-1',
      customerId: 'customer-1',
      customerName: 'مشتری آزمایشی',
      orderDate: DateTime(2026, 10, 5),
      lines: [
        SalesOrderLine(
          productVariantId: 'energy-bar-100g-ginger',
          productName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
          flavor: 'زنجبیلی',
          packageLabel: '۱۰۰ گرمی',
          quantity: 10,
          unitSellingPrice: 100000,
          lineTotal: 1000000,
        ),
      ],
      totalAmount: 1000000,
      status: status,
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

  Future<void> seedStock() async {
    await stock('raw_date_khesht', 'خرما خشت', 2000, 'گرم');
    await stock('raw_walnut_iranian', 'گردو ایرانی', 1000, 'گرم');
    await stock('raw_almond', 'بادام درختی', 1000, 'گرم');
    await stock('raw_peanut', 'بادام زمینی', 1000, 'گرم');
    await stock('raw_sesame', 'کنجد', 1000, 'گرم');
    await stock('raw_ground_ginger', 'پودر زنجبیل', 100, 'گرم');
    await stock('pack_container_100g', 'ظرف ۱۰۰ گرمی', 20, 'piece');
    await stock('pack_label', 'لیبل', 20, 'piece');
  }

  Future<ProductionOrderAnalysis> analysis() async {
    return ProductionOrderAnalyzer(
      inventoryStore: inventoryStore,
    ).analyze(order());
  }

  ProductionOrderExecutionService service() {
    return ProductionOrderExecutionService(
      inventoryStore: inventoryStore,
      orderStore: orderStore,
      batchStore: batchStore,
    );
  }

  test('reserves production materials exactly once', () async {
    await seedStock();
    final currentOrder = order();
    final analysisResult = await analysis();

    final first = await service().reserve(currentOrder, analysisResult);
    final second = await service().reserve(currentOrder, analysisResult);

    expect(first.changed, isTrue);
    expect(second.changed, isFalse);
    expect(await inventoryStore.getReservedStock('raw_date_khesht'), closeTo(773.888889, 0.000001));
    expect(await inventoryStore.getReservedStock('pack_container_100g'), 10);

    final reservations = await inventoryStore.getReservations(activeOnly: true);
    expect(
      reservations.where((item) => item.referenceId == currentOrder.id),
      hasLength(8),
    );
  });

  test('consumes reserved materials and creates product plus pit output', () async {
    await seedStock();
    final currentOrder = order();
    final analysisResult = await analysis();

    await service().reserve(currentOrder, analysisResult);
    final result = await service().startProduction(
      order(status: SalesOrderStatus.inProduction),
      analysisResult,
    );

    expect(result.changed, isTrue);
    expect(result.order.status, SalesOrderStatus.productionCompleted);
    expect(await inventoryStore.getReservedStock('raw_date_khesht'), 0);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 10);
    expect(await inventoryStore.getStock('raw_date_pit'), closeTo(77.388889, 0.000001));

    final movements = await inventoryStore.getMovements();
    expect(
      movements.where((item) => item.referenceId == currentOrder.id),
      hasLength(10),
    );
  });

  test('repeating production does not duplicate movements or output', () async {
    await seedStock();
    final currentOrder = order();
    final analysisResult = await analysis();

    await service().reserve(currentOrder, analysisResult);

    final first = await service().startProduction(
      order(status: SalesOrderStatus.inProduction),
      analysisResult,
    );

    final afterFirst = await inventoryStore.getMovements();

    final second = await service().startProduction(
      first.order,
      analysisResult,
    );

    final afterSecond = await inventoryStore.getMovements();

    expect(first.changed, isTrue);
    expect(second.alreadyCompleted, isTrue);
    expect(afterSecond.length, afterFirst.length);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 10);
    expect(await inventoryStore.getStock('raw_date_pit'), closeTo(77.388889, 0.000001));
  });

  test('does not reserve when stock is insufficient', () async {
    await stock('raw_date_khesht', 'خرما خشت', 100, 'گرم');

    final currentOrder = order();
    final analysisResult = await analysis();

    expect(analysisResult.canProduce, isFalse);
    expect(
      () => service().reserve(currentOrder, analysisResult),
      throwsA(isA<StateError>()),
    );
    expect(await inventoryStore.getReservations(activeOnly: true), isEmpty);
  });
}
