import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/purchase.dart';
import 'package:zohal_android_test/core/purchase_service.dart';
import 'package:zohal_android_test/core/purchase_store.dart';
import 'package:zohal_android_test/core/purchase_return_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventory = InventoryStore.instance;
  final purchases = PurchaseStore.instance;
  final finance = FinancialStore.instance;
  final purchaseReturns = PurchaseReturnStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventory.clear();
    await purchases.clear();
    await finance.clear();
    await purchaseReturns.clear();
  });

  Purchase purchase() => Purchase(
    id: 'purchase-1',
    supplierId: 'supplier-1',
    supplierName: 'تأمین‌کننده آزمایشی',
    createdAt: DateTime(2026, 10, 5),
    lines: const [
      PurchaseLine(
        itemId: 'raw_date_khesht',
        itemName: 'خرما خشت',
        itemType: 'rawMaterial',
        quantity: 10,
        unit: 'کیلوگرم',
        unitCost: 500000,
      ),
    ],
    totalAmount: 5000000,
  );

  PurchaseService service() => PurchaseService(
    inventoryStore: inventory,
    purchaseStore: purchases,
    financialStore: finance,
    purchaseReturnStore: purchaseReturns,
  );

  test('purchase increases stock and creates supplier payable', () async {
    await service().recordPurchase(purchase());

    expect(await inventory.getStock('raw_date_khesht'), 10);
    expect(await finance.getBalance('supplier-supplier-1'), -5000000);
    expect(await finance.getBalance('inventory-asset'), 5000000);
  });

  test('same purchase id is idempotent', () async {
    final first = await service().recordPurchase(purchase());
    final second = await service().recordPurchase(purchase());

    expect(second.id, first.id);
    expect(await inventory.getStock('raw_date_khesht'), 10);
    expect((await finance.getTransactions()).length, 1);
    expect((await purchases.getAll()).length, 1);
  });

  test('purchase return reverses stock and supplier payable', () async {
    await service().recordPurchase(purchase());

    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-purchase-1',
      quantities: {'raw_date_khesht': 2},
    );

    expect(await inventory.getStock('raw_date_khesht'), 8);
    expect(await finance.getBalance('supplier-supplier-1'), -4000000);
    expect(await finance.getBalance('inventory-asset'), 4000000);
  });

  test('same purchase return id is idempotent', () async {
    await service().recordPurchase(purchase());

    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-purchase-1',
      quantities: {'raw_date_khesht': 2},
    );
    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-purchase-1',
      quantities: {'raw_date_khesht': 5},
    );

    expect(await inventory.getStock('raw_date_khesht'), 8);
    expect((await purchaseReturns.getAll()).length, 1);
    expect((await finance.getTransactions()).length, 2);
  });

  test('supplier payment reduces payable and increases cash', () async {
    await service().recordPurchase(purchase());

    await service().recordSupplierPayment(
      paymentId: 'payment-1',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 2000000,
    );

    expect(await finance.getBalance('supplier-supplier-1'), -3000000);
    expect(await finance.getBalance('cash'), -2000000);
  });

  test('supplier payment is idempotent', () async {
    await service().recordPurchase(purchase());

    final first = await service().recordSupplierPayment(
      paymentId: 'payment-1',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 2000000,
    );
    final second = await service().recordSupplierPayment(
      paymentId: 'payment-1',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 500000,
    );

    expect(second.id, first.id);
    expect(await finance.getBalance('supplier-supplier-1'), -3000000);
    expect(await finance.getBalance('cash'), -2000000);
    expect((await finance.getTransactions()).length, 2);
  });

  test('supplier payment cannot exceed payable', () async {
    await service().recordPurchase(purchase());

    expect(
      () => service().recordSupplierPayment(
        paymentId: 'payment-over',
        supplierId: 'supplier-1',
        supplierName: 'تأمین‌کننده آزمایشی',
        amount: 5000001,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('purchase return cannot exceed purchased quantity', () async {
    await service().recordPurchase(purchase());

    expect(
      () => service().returnPurchase(
        purchase: purchase(),
        returnId: 'return-over',
        quantities: {'raw_date_khesht': 11},
      ),
      throwsA(isA<StateError>()),
    );
    expect(await inventory.getStock('raw_date_khesht'), 10);
    expect(await purchaseReturns.getAll(), isEmpty);
  });

  test('supplier payment without payable is rejected', () async {
    expect(
      () => service().recordSupplierPayment(
        paymentId: 'payment-none',
        supplierId: 'supplier-1',
        supplierName: 'تأمین‌کننده آزمایشی',
        amount: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
