import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_service.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_store.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/sales/sales_order_store.dart';
import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryStore = InventoryStore.instance;
  final orderStore = SalesOrderStore.instance;
  final deliveryStore = SalesDeliveryStore.instance;
  final financialStore = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventoryStore.clear();
    await orderStore.clear();
    await deliveryStore.clear();
    await financialStore.clear();
  });

  SalesOrder order({SalesOrderStatus status = SalesOrderStatus.productionCompleted}) {
    return SalesOrder(
      id: 'order-delivery-1',
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

  Future<void> finishedStock(int quantity) {
    return inventoryStore.addMovement(
      InventoryMovement(
        id: 'production-output-delivery',
        itemId: 'energy-bar-100g-ginger',
        itemName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        itemType: 'finishedProduct',
        quantity: quantity.toDouble(),
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 10, 5),
      ),
    );
  }

  SalesDeliveryService service() => SalesDeliveryService(
    inventoryStore: inventoryStore,
    orderStore: orderStore,
    deliveryStore: deliveryStore,
    financialService: SalesFinancialService(store: financialStore),
  );

  test('moves completed production to ready for delivery', () async {
    final current = order();
    await orderStore.create(current);
    final updated = await service().markReadyForDelivery(current);
    expect(updated.status, SalesOrderStatus.readyForDelivery);
  });

  test('partial delivery decrements finished stock and is idempotent', () async {
    await finishedStock(10);
    final current = order(status: SalesOrderStatus.readyForDelivery);
    await orderStore.create(current);

    final first = await service().deliver(
      order: current,
      deliveryId: 'delivery-1',
      quantities: {'energy-bar-100g-ginger': 4},
    );
    expect(first.order.status, SalesOrderStatus.partiallyDelivered);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 6);
    expect(first.delivery.totalAmount, 400000);
    expect(await financialStore.getBalance('customer-customer-1'), 400000);

    final second = await service().deliver(
      order: first.order,
      deliveryId: 'delivery-1',
      quantities: {'energy-bar-100g-ginger': 4},
    );
    expect(second.changed, isFalse);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 6);

    final third = await service().deliver(
      order: first.order,
      deliveryId: 'delivery-2',
      quantities: {'energy-bar-100g-ginger': 6},
    );
    expect(third.order.status, SalesOrderStatus.delivered);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 0);
    expect(await financialStore.getBalance('customer-customer-1'), 1000000);
  });

  test('does not deliver more than remaining order quantity', () async {
    await finishedStock(10);
    final current = order(status: SalesOrderStatus.readyForDelivery);
    await orderStore.create(current);

    await service().deliver(
      order: current,
      deliveryId: 'delivery-1',
      quantities: {'energy-bar-100g-ginger': 6},
    );

    final stored = (await orderStore.getAll()).single;
    expect(
      () => service().deliver(
        order: stored,
        deliveryId: 'delivery-2',
        quantities: {'energy-bar-100g-ginger': 5},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('does not deliver when finished stock is insufficient', () async {
    await finishedStock(3);
    final current = order(status: SalesOrderStatus.readyForDelivery);
    await orderStore.create(current);

    expect(
      () => service().deliver(
        order: current,
        deliveryId: 'delivery-short',
        quantities: {'energy-bar-100g-ginger': 4},
      ),
      throwsA(isA<StateError>()),
    );
    expect(await deliveryStore.getAll(), isEmpty);
  });
}
