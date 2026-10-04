import 'financial_account.dart';
import 'financial_entry.dart';
import 'financial_store.dart';
import '../sales/sales_delivery.dart';
import '../sales/sales_return.dart';
import '../sales/sales_delivery_store.dart';
import '../sales/sales_return_store.dart';
import '../sales/sales_receipt.dart';
import '../sales/sales_receipt_store.dart';
import '../sales/sales_credit_allocation.dart';
import '../sales/sales_credit_allocation_store.dart';
import '../sales/customer_store.dart';

class SalesFinancialService {
  final FinancialStore store;

  const SalesFinancialService({required this.store});

  Future<FinancialTransaction> postSaleReceivable(
    SalesDelivery delivery, {
    required String customerName,
  }) async {
    final transactionId = 'sale-' + delivery.id;
    final existing = await store.getTransaction(transactionId);
    if (existing != null) return existing;

    final customerAccountId = 'customer-' + delivery.customerId;
    await store.ensureAccount(FinancialAccount(
      id: customerAccountId,
      name: customerName,
      type: FinancialAccountType.customer,
    ));
    await store.ensureAccount(const FinancialAccount(
      id: 'sales-revenue',
      name: 'فروش',
      type: FinancialAccountType.salesRevenue,
    ));

    final transaction = FinancialTransaction(
      id: transactionId,
      createdAt: delivery.createdAt,
      type: 'sale',
      referenceId: delivery.id,
      note: 'ثبت فروش تحویل ' + delivery.id,
      entries: [
        FinancialEntry(
          accountId: customerAccountId,
          amount: delivery.totalAmount,
          isDebit: true,
          note: 'بدهی مشتری بابت تحویل',
        ),
        FinancialEntry(
          accountId: 'sales-revenue',
          amount: delivery.totalAmount,
          isDebit: false,
          note: 'درآمد فروش',
        ),
      ],
    );
    await store.addTransaction(transaction);
    return transaction;
  }

  Future<FinancialTransaction> postSaleReturn(
    SalesReturn salesReturn, {
    required String customerName,
  }) async {
    final transactionId = 'sale-return-' + salesReturn.id;
    final existing = await store.getTransaction(transactionId);
    if (existing != null) return existing;

    final customerAccountId = 'customer-' + salesReturn.customerId;
    await store.ensureAccount(FinancialAccount(
      id: customerAccountId,
      name: customerName,
      type: FinancialAccountType.customer,
    ));
    await store.ensureAccount(const FinancialAccount(
      id: 'sales-revenue',
      name: 'فروش',
      type: FinancialAccountType.salesRevenue,
    ));

    final transaction = FinancialTransaction(
      id: transactionId,
      createdAt: salesReturn.createdAt,
      type: 'saleReturn',
      referenceId: salesReturn.id,
      note: 'برگشت فروش ' + salesReturn.id,
      entries: [
        FinancialEntry(
          accountId: 'sales-revenue',
          amount: salesReturn.totalAmount,
          isDebit: true,
          note: 'کاهش درآمد فروش بابت برگشت',
        ),
        FinancialEntry(
          accountId: customerAccountId,
          amount: salesReturn.totalAmount,
          isDebit: false,
          note: 'ثبت اعتبار مشتری بابت برگشت',
        ),
      ],
    );
    await store.addTransaction(transaction);
    return transaction;
  }

  Future<int> getInvoiceOutstanding({
    required String orderId,
    required String customerId,
  }) async {
    final deliveries = await SalesDeliveryStore.instance.getByOrderId(orderId);
    if (deliveries.isEmpty) {
      throw StateError('فاکتور موردنظر پیدا نشد یا هنوز تحویلی برای آن ثبت نشده است.');
    }
    if (deliveries.any((delivery) => delivery.customerId != customerId)) {
      throw StateError('فاکتور متعلق به این مشتری نیست.');
    }

    var invoiceTotal = 0;
    for (final delivery in deliveries) {
      invoiceTotal += delivery.totalAmount;
      final returns = await SalesReturnStore.instance.getByDeliveryId(delivery.id);
      invoiceTotal -= returns.fold<int>(0, (sum, item) => sum + item.totalAmount);
    }

    final receipts = await SalesReceiptStore.instance.getByOrderId(orderId);
    final receiptsTotal = receipts.fold<int>(0, (sum, item) => sum + item.amount);
    final credits = await SalesCreditAllocationStore.instance.getByOrderId(orderId);
    final creditsTotal = credits.fold<int>(0, (sum, item) => sum + item.amount);

    return invoiceTotal - receiptsTotal - creditsTotal;
  }

  Future<SalesCreditAllocation> applyCustomerCredit({
    required String allocationId,
    required String orderId,
    required String customerId,
    required int amount,
    String? note,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('مبلغ استفاده از اعتبار باید بیشتر از صفر باشد.');
    }

    final allocationStore = SalesCreditAllocationStore.instance;
    final existing = await allocationStore.getById(allocationId);
    if (existing != null) {
      if (existing.orderId != orderId || existing.customerId != customerId) {
        throw StateError('شناسه تخصیص اعتبار برای مورد دیگری استفاده شده است.');
      }
      return existing;
    }

    final customerBalance = await store.getBalance('customer-' + customerId);
    final availableCredit = customerBalance < 0 ? -customerBalance : 0;
    if (availableCredit <= 0) {
      throw StateError('این مشتری اعتبار قابل استفاده ندارد.');
    }

    final invoiceOutstanding = await getInvoiceOutstanding(
      orderId: orderId,
      customerId: customerId,
    );
    if (invoiceOutstanding <= 0) {
      throw StateError('این فاکتور مانده قابل تسویه ندارد.');
    }
    if (amount > availableCredit) {
      throw StateError('مبلغ استفاده از اعتبار بیشتر از اعتبار مشتری است.');
    }
    if (amount > invoiceOutstanding) {
      throw StateError('مبلغ استفاده از اعتبار بیشتر از مانده فاکتور است.');
    }

    final allocation = SalesCreditAllocation(
      id: allocationId,
      orderId: orderId,
      customerId: customerId,
      amount: amount,
      createdAt: DateTime.now(),
      note: note,
    );
    await allocationStore.add(allocation);
    return allocation;
  }

  Future<FinancialTransaction> recordReceipt({
    required String receiptId,
    required String customerId,
    required String customerName,
    required int amount,
    String? orderId,
    String? payerId,
    String? payerName,
    String? note,
  }) async {
    if (amount <= 0) throw ArgumentError('مبلغ دریافت باید بیشتر از صفر باشد.');

    final transactionId = 'receipt-' + receiptId;
    final existing = await store.getTransaction(transactionId);
    if (existing != null) return existing;

    final customerAccountId = 'customer-' + customerId;
    final receiptStore = SalesReceiptStore.instance;
    var invoiceOutstanding = await store.getBalance(customerAccountId);
    if (orderId != null) {
      invoiceOutstanding = await getInvoiceOutstanding(
        orderId: orderId,
        customerId: customerId,
      );
      if (invoiceOutstanding <= 0) {
        throw StateError('این فاکتور بدهی قابل تسویه ندارد.');
      }
      if (amount > invoiceOutstanding) {
        throw StateError('مبلغ دریافت نمی‌تواند بیشتر از مانده فاکتور باشد.');
      }
    } else {
      if (invoiceOutstanding <= 0) {
        throw StateError('این مشتری بدهی قابل تسویه ندارد.');
      }
      if (amount > invoiceOutstanding) {
        throw StateError('مبلغ دریافت نمی‌تواند بیشتر از بدهی مشتری باشد.');
      }
    }

    final effectivePayerId = payerId ?? customerId;
    final effectivePayerName = payerName ?? customerName;
    if (effectivePayerId != customerId) {
      final payer = await CustomerStore.instance.getAll();
      final payerMatch = payer.where((item) => item.id == effectivePayerId);
      if (payerMatch.isEmpty) {
        throw StateError('پرداخت‌کننده باید قبلاً به عنوان مشتری ثبت شده باشد.');
      }
    }

    await store.ensureAccount(FinancialAccount(
      id: customerAccountId,
      name: customerName,
      type: FinancialAccountType.customer,
    ));
    await store.ensureAccount(const FinancialAccount(
      id: 'cash',
      name: 'صندوق',
      type: FinancialAccountType.cash,
    ));

    final transaction = FinancialTransaction(
      id: transactionId,
      createdAt: DateTime.now(),
      type: 'receipt',
      referenceId: receiptId,
      note: note,
      entries: [
        FinancialEntry(
          accountId: 'cash',
          amount: amount,
          isDebit: true,
          note: 'دریافت وجه از ' + effectivePayerName,
        ),
        FinancialEntry(
          accountId: customerAccountId,
          amount: amount,
          isDebit: false,
          note: 'تسویه بدهی مشتری ' + customerName,
        ),
      ],
    );
    await store.addTransaction(transaction);

    await receiptStore.add(SalesReceipt(
      id: receiptId,
      orderId: orderId,
      customerId: customerId,
      customerName: customerName,
      payerId: effectivePayerId,
      payerName: effectivePayerName,
      amount: amount,
      createdAt: transaction.createdAt,
      note: note,
    ));
    return transaction;
  }
}
