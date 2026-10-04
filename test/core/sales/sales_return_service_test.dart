import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';
import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/sales/sales_delivery.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_store.dart';
import 'package:zohal_android_test/core/sales/sales_return_service.dart';
import 'package:zohal_android_test/core/sales/sales_return_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryStore = InventoryStore.instance;
  final deliveryStore = SalesDeliveryStore.instance;
  final returnStore = SalesReturnStore.instance;
  final financialStore = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventoryStore.clear();
    await deliveryStore.clear();
    await returnStore.clear();
    await financialStore.clear();
  });

  SalesDelivery delivery() => SalesDelivery(
    id: 'delivery-return-1',
    orderId: 'order-return-1',
    customerId: 'customer-1',
    createdAt: DateTime(2026, 10, 5),
    lines: const [
      SalesDeliveryLine(
        productVariantId: 'energy-bar-100g-ginger',
        productName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        quantity: 10,
        unitSellingPrice: 100000,
        totalAmount: 1000000,
      ),
    ],
    totalAmount: 1000000,
  );

  SalesReturnService service() => SalesReturnService(
    inventoryStore: inventoryStore,
    deliveryStore: deliveryStore,
    returnStore: returnStore,
    financialService: SalesFinancialService(store: financialStore),
  );

  Future<void> seedDeliveryAndSale() async {
    final current = delivery();
    await deliveryStore.add(current);
    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'production-output-return',
        itemId: 'energy-bar-100g-ginger',
        itemName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 10,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 10, 5),
      ),
    );
    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'sale-delivery-return',
        itemId: 'energy-bar-100g-ginger',
        itemName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 4,
        unit: 'عدد',
        movementType: InventoryMovementType.sale,
        timestamp: DateTime(2026, 10, 5),
        referenceId: current.id,
      ),
    );
    await SalesFinancialService(store: financialStore).postSaleReceivable(
      current,
      customerName: 'مشتری آزمایشی',
    );
  }

  test('return increases stock and reverses customer receivable', () async {
    await seedDeliveryAndSale();

    final result = await service().returnItems(
      delivery: delivery(),
      returnId: 'return-1',
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 2},
    );

    expect(result.changed, isTrue);
    expect(result.salesReturn.totalAmount, 200000);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 8);
    expect(await financialStore.getBalance('customer-customer-1'), 800000);
    expect(await financialStore.getBalance('sales-revenue'), -800000);
  });

  test('same return id is idempotent', () async {
    await seedDeliveryAndSale();

    final first = await service().returnItems(
      delivery: delivery(),
      returnId: 'return-1',
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 2},
    );
    final second = await service().returnItems(
      delivery: delivery(),
      returnId: 'return-1',
      customerName: 'مشتری دیگر',
      quantities: {'energy-bar-100g-ginger': 5},
    );

    expect(second.changed, isFalse);
    expect(second.salesReturn.id, first.salesReturn.id);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 8);
    expect((await returnStore.getAll()).length, 1);
    expect((await financialStore.getTransactions()).length, 2);
  });

  test('retries an existing return and repairs missing financial posting', () async {
    await seedDeliveryAndSale();

    final salesReturn = SalesReturn(
      id: 'return-recovery',
      deliveryId: delivery().id,
      orderId: delivery().orderId,
      customerId: delivery().customerId,
      customerName: 'مشتری آزمایشی',
      createdAt: DateTime(2026, 10, 5),
      lines: const [
        SalesReturnLine(
          productVariantId: 'energy-bar-100g-ginger',
          quantity: 2,
          unitSellingPrice: 100000,
          totalAmount: 200000,
        ),
      ],
      totalAmount: 200000,
    );
    await returnStore.add(salesReturn);

    final result = await service().returnItems(
      delivery: delivery(),
      returnId: salesReturn.id,
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 99},
    );

    expect(result.changed, isFalse);
    expect(await financialStore.getBalance('customer-customer-1'), 800000);
    expect((await financialStore.getTransactions()).length, 2);
  });

  test('cannot return more than delivered quantity', () async {
    await seedDeliveryAndSale();

    expect(
      () => service().returnItems(
        delivery: delivery(),
        returnId: 'return-over',
        customerName: 'مشتری آزمایشی',
        quantities: {'energy-bar-100g-ginger': 11},
      ),
      throwsA(isA<StateError>()),
    );

    expect(await returnStore.getAll(), isEmpty);
    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 6);
    expect(await financialStore.getBalance('customer-customer-1'), 1000000);
  });

  test('multiple returns cannot exceed the original delivery', () async {
    await seedDeliveryAndSale();

    await service().returnItems(
      delivery: delivery(),
      returnId: 'return-1',
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 6},
    );

    await service().returnItems(
      delivery: delivery(),
      returnId: 'return-2',
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 4},
    );

    expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 16);
    expect(await financialStore.getBalance('customer-customer-1'), 0);

    expect(
      () => service().returnItems(
        delivery: delivery(),
        returnId: 'return-3',
        customerName: 'مشتری آزمایشی',
        quantities: {'energy-bar-100g-ginger': 1},
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('return after full payment creates customer credit', () async {
    await seedDeliveryAndSale();

    final finance = SalesFinancialService(store: financialStore);
    await finance.recordReceipt(
      receiptId: 'receipt-return-1',
      customerId: 'customer-1',
      customerName: 'مشتری آزمایشی',
      amount: 1000000,
    );

    await service().returnItems(
      delivery: delivery(),
      returnId: 'return-paid',
      customerName: 'مشتری آزمایشی',
      quantities: {'energy-bar-100g-ginger': 2},
    );

    expect(await financialStore.getBalance('customer-customer-1'), -200000);
    expect(await financialStore.getBalance('cash'), 1000000);
    expect(await financialStore.getBalance('sales-revenue'), -800000);
  });
}
