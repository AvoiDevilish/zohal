import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/purchase.dart';
import 'package:zohal_android_test/core/purchase_service.dart';
import 'package:zohal_android_test/core/purchase_store.dart';
import 'package:zohal_android_test/core/purchase_return_store.dart';
import 'package:zohal_android_test/core/purchase/supplier_credit_allocation_store.dart';
import 'package:zohal_android_test/core/purchase/supplier_credit_entry_store.dart';
import 'package:zohal_android_test/core/purchase/supplier_credit_settlement_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventory = InventoryStore.instance;
  final purchases = PurchaseStore.instance;
  final finance = FinancialStore.instance;
  final purchaseReturns = PurchaseReturnStore.instance;
  final creditEntries = SupplierCreditEntryStore.instance;
  final creditAllocations = SupplierCreditAllocationStore.instance;
  final creditSettlements = SupplierCreditSettlementStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inventory.clear();
    await purchases.clear();
    await finance.clear();
    await purchaseReturns.clear();
    await creditEntries.clear();
    await creditAllocations.clear();
    await creditSettlements.clear();
  });

  Purchase purchase({
    String id = 'purchase-1',
    int totalAmount = 5000000,
    double quantity = 10,
  }) => Purchase(
    id: id,
    supplierId: 'supplier-1',
    supplierName: 'تأمین‌کننده آزمایشی',
    createdAt: DateTime(2026, 10, 5),
    lines: [
      PurchaseLine(
        itemId: 'raw_date_khesht',
        itemName: 'خرما خشت',
        itemType: 'rawMaterial',
        quantity: quantity,
        unit: 'کیلوگرم',
        unitCost: 500000,
      ),
    ],
    totalAmount: totalAmount,
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

  test('reconciles a purchase after inventory and finance were persisted first', () async {
    final item = purchase();

    await inventory.addMovement(
      InventoryMovement(
        id: 'purchase-${item.id}-raw_date_khesht',
        itemId: 'raw_date_khesht',
        itemName: 'خرما خشت',
        itemType: 'rawMaterial',
        quantity: 10,
        unit: 'کیلوگرم',
        movementType: InventoryMovementType.purchase,
        timestamp: item.createdAt,
        unitCost: 500000,
        referenceId: item.id,
      ),
    );

    await finance.ensureAccount(FinancialAccount(
      id: 'supplier-${item.supplierId}',
      name: item.supplierName,
      type: FinancialAccountType.supplier,
    ));
    await finance.ensureAccount(const FinancialAccount(
      id: 'inventory-asset',
      name: 'موجودی کالا و مواد',
      type: FinancialAccountType.inventoryAsset,
    ));
    await finance.addTransaction(
      FinancialTransaction(
        id: 'purchase-${item.id}',
        createdAt: item.createdAt,
        type: 'purchase',
        referenceId: item.id,
        entries: [
          FinancialEntry(
            accountId: 'inventory-asset',
            amount: item.totalAmount,
            isDebit: true,
          ),
          FinancialEntry(
            accountId: 'supplier-${item.supplierId}',
            amount: item.totalAmount,
            isDebit: false,
          ),
        ],
      ),
    );

    await service().recordPurchase(item);

    expect((await purchases.getAll()).single.id, item.id);
    expect(await inventory.getStock('raw_date_khesht'), 10);
    expect((await finance.getTransactions()).length, 1);
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

  test('paid purchase return creates reusable supplier credit', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-full',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 5000000,
    );

    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-credit',
      quantities: {'raw_date_khesht': 4},
    );

    expect(await finance.getBalance('supplier-supplier-1'), 2000000);
    expect(await service().getSupplierCredit('supplier-1'), 2000000);
    expect((await creditEntries.getBySupplierId('supplier-1')).single.amount, 2000000);
  });

  test('unpaid purchase return does not create supplier credit', () async {
    await service().recordPurchase(purchase());

    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-no-credit',
      quantities: {'raw_date_khesht': 2},
    );

    expect(await finance.getBalance('supplier-supplier-1'), -4000000);
    expect(await service().getSupplierCredit('supplier-1'), 0);
    expect(await creditEntries.getAll(), isEmpty);
  });

  test('partial return after partial payment creates only excess supplier credit', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-partial',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 4500000,
    );

    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-partial-credit',
      quantities: {'raw_date_khesht': 2},
    );

    expect(await finance.getBalance('supplier-supplier-1'), 500000);
    expect(await service().getSupplierCredit('supplier-1'), 500000);
  });

  test('supplier credit can be allocated to a later purchase without a financial movement', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-full',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 5000000,
    );
    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-credit',
      quantities: {'raw_date_khesht': 4},
    );

    final laterPurchase = purchase(
      id: 'purchase-2',
      totalAmount: 3000000,
      quantity: 6,
    );
    await service().recordPurchase(laterPurchase);

    final beforeTransactions = (await finance.getTransactions()).length;
    final allocation = await service().applySupplierCredit(
      allocationId: 'allocation-1',
      purchaseId: laterPurchase.id,
      supplierId: 'supplier-1',
      amount: 1500000,
    );

    expect(allocation.amount, 1500000);
    expect(await service().getSupplierCredit('supplier-1'), 500000);
    expect(
      await service().getPurchaseOutstanding(
        purchaseId: laterPurchase.id,
        supplierId: 'supplier-1',
      ),
      1500000,
    );
    expect((await finance.getTransactions()).length, beforeTransactions);
  });

  test('supplier credit allocation is idempotent', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-full',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 5000000,
    );
    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-credit',
      quantities: {'raw_date_khesht': 4},
    );

    final laterPurchase = purchase(
      id: 'purchase-2',
      totalAmount: 3000000,
      quantity: 6,
    );
    await service().recordPurchase(laterPurchase);

    final first = await service().applySupplierCredit(
      allocationId: 'allocation-1',
      purchaseId: laterPurchase.id,
      supplierId: 'supplier-1',
      amount: 1500000,
    );
    final second = await service().applySupplierCredit(
      allocationId: 'allocation-1',
      purchaseId: laterPurchase.id,
      supplierId: 'supplier-1',
      amount: 500000,
    );

    expect(second.id, first.id);
    expect(await service().getSupplierCredit('supplier-1'), 500000);
    expect((await creditAllocations.getAll()).length, 1);
  });

  test('supplier credit can be settled back as cash', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-full',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 5000000,
    );
    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-credit',
      quantities: {'raw_date_khesht': 4},
    );

    await service().settleSupplierCredit(
      settlementId: 'settlement-1',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 1000000,
    );

    expect(await service().getSupplierCredit('supplier-1'), 1000000);
    expect(await finance.getBalance('supplier-supplier-1'), 1000000);
    expect(await finance.getBalance('cash'), -4000000);
    expect((await creditSettlements.getAll()).single.amount, 1000000);
  });

  test('supplier credit settlement cannot exceed available credit', () async {
    await service().recordPurchase(purchase());
    await service().recordSupplierPayment(
      paymentId: 'payment-full',
      supplierId: 'supplier-1',
      supplierName: 'تأمین‌کننده آزمایشی',
      amount: 5000000,
    );
    await service().returnPurchase(
      purchase: purchase(),
      returnId: 'return-credit',
      quantities: {'raw_date_khesht': 4},
    );

    expect(
      () => service().settleSupplierCredit(
        settlementId: 'settlement-over',
        supplierId: 'supplier-1',
        supplierName: 'تأمین‌کننده آزمایشی',
        amount: 2000001,
      ),
      throwsA(isA<StateError>()),
    );
  });
}
