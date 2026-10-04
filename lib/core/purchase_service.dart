import 'finance/financial_account.dart';
import 'finance/financial_entry.dart';
import 'finance/financial_store.dart';
import 'inventory/inventory_movement.dart';
import 'inventory/inventory_store.dart';
import 'purchase.dart';
import 'purchase_store.dart';

class PurchaseService {
  final InventoryStore inventoryStore;
  final PurchaseStore purchaseStore;
  final FinancialStore financialStore;

  const PurchaseService({
    required this.inventoryStore,
    required this.purchaseStore,
    required this.financialStore,
  });

  Future<Purchase> recordPurchase(Purchase purchase) async {
    if (purchase.lines.isEmpty) throw ArgumentError('خرید باید حداقل یک قلم داشته باشد.');
    if (purchase.totalAmount <= 0) throw ArgumentError('مبلغ خرید باید بیشتر از صفر باشد.');
    final existing = await purchaseStore.getById(purchase.id);
    if (existing != null) return existing;

    final calculatedTotal = purchase.lines.fold<int>(0, (sum, line) => sum + line.totalCost);
    if (calculatedTotal != purchase.totalAmount) {
      throw StateError('مبلغ خرید با جمع اقلام همخوانی ندارد.');
    }

    final movements = purchase.lines.map((line) => InventoryMovement(
      id: 'purchase-' + purchase.id + '-' + line.itemId,
      itemId: line.itemId,
      itemName: line.itemName,
      itemType: line.itemType,
      quantity: line.quantity,
      unit: line.unit,
      movementType: InventoryMovementType.purchase,
      timestamp: purchase.createdAt,
      referenceId: purchase.id,
      unitCost: line.unitCost.toDouble(),
      note: 'خرید از ' + purchase.supplierName,
    )).toList();

    final existingMovements = await inventoryStore.getMovements();
    final byId = {for (final m in existingMovements) m.id: m};
    for (final movement in movements) {
      final current = byId[movement.id];
      if (current != null &&
          (current.itemId != movement.itemId ||
           current.movementType != movement.movementType ||
           (current.quantity - movement.quantity).abs() > 0.000001 ||
           (current.unitCost ?? 0) != (movement.unitCost ?? 0))) {
        throw StateError('حرکت خرید با اطلاعات مورد انتظار همخوانی ندارد.');
      }
    }
    final missing = movements.where((m) => !byId.containsKey(m.id)).toList();
    if (missing.isNotEmpty) await inventoryStore.addMovements(missing);

    await financialStore.ensureAccount(FinancialAccount(
      id: 'supplier-' + purchase.supplierId,
      name: purchase.supplierName,
      type: FinancialAccountType.supplier,
    ));
    await financialStore.ensureAccount(const FinancialAccount(
      id: 'inventory-asset',
      name: 'موجودی کالا و مواد',
      type: FinancialAccountType.inventoryAsset,
    ));

    final transaction = FinancialTransaction(
      id: 'purchase-' + purchase.id,
      createdAt: purchase.createdAt,
      type: 'purchase',
      referenceId: purchase.id,
      note: 'ثبت خرید ' + purchase.id,
      entries: [
        FinancialEntry(
          accountId: 'inventory-asset',
          amount: purchase.totalAmount,
          isDebit: true,
          note: 'افزایش ارزش موجودی',
        ),
        FinancialEntry(
          accountId: 'supplier-' + purchase.supplierId,
          amount: purchase.totalAmount,
          isDebit: false,
          note: 'بدهی به تأمین‌کننده',
        ),
      ],
    );
    await financialStore.addTransaction(transaction);
    await purchaseStore.add(purchase);
    return purchase;
  }

  Future<FinancialTransaction> recordSupplierPayment({
    required String paymentId,
    required String supplierId,
    required String supplierName,
    required int amount,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('مبلغ پرداخت باید بیشتر از صفر باشد.');
    final transactionId = 'supplier-payment-' + paymentId;
    final existing = await financialStore.getTransaction(transactionId);
    if (existing != null) return existing;

    final supplierAccountId = 'supplier-' + supplierId;
    final outstanding = -await financialStore.getBalance(supplierAccountId);
    if (outstanding <= 0) {
      throw StateError('این تأمین‌کننده بدهی قابل پرداخت ندارد.');
    }
    if (amount > outstanding) {
      throw StateError('مبلغ پرداخت نمی‌تواند بیشتر از بدهی تأمین‌کننده باشد.');
    }

    await financialStore.ensureAccount(FinancialAccount(
      id: supplierAccountId,
      name: supplierName,
      type: FinancialAccountType.supplier,
    ));
    await financialStore.ensureAccount(const FinancialAccount(
      id: 'cash',
      name: 'صندوق',
      type: FinancialAccountType.cash,
    ));

    final transaction = FinancialTransaction(
      id: transactionId,
      createdAt: DateTime.now(),
      type: 'supplierPayment',
      referenceId: paymentId,
      note: note,
      entries: [
        FinancialEntry(
          accountId: supplierAccountId,
          amount: amount,
          isDebit: true,
          note: 'کاهش بدهی تأمین‌کننده',
        ),
        FinancialEntry(
          accountId: 'cash',
          amount: amount,
          isDebit: false,
          note: 'پرداخت به تأمین‌کننده',
        ),
      ],
    );
    await financialStore.addTransaction(transaction);
    return transaction;
  }
}
