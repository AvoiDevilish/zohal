import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';
import 'package:zohal_android_test/core/sales/sales_delivery.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_store.dart';
import 'package:zohal_android_test/core/sales/sales_receipt_store.dart';
import 'package:zohal_android_test/core/sales/sales_return_store.dart';
import 'package:zohal_android_test/core/sales/customer.dart';
import 'package:zohal_android_test/core/sales/customer_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.clear();
    await SalesDeliveryStore.instance.clear();
    await SalesReceiptStore.instance.clear();
    await SalesReturnStore.instance.clear();
    await CustomerStore.instance.clear();
  });

  SalesDelivery delivery() => SalesDelivery(
    id: 'delivery-finance-1',
    orderId: 'order-finance-1',
    customerId: 'customer-1',
    createdAt: DateTime(2026, 10, 5),
    lines: const [],
    totalAmount: 400000,
  );

  test('posts delivered sale as customer receivable and revenue', () async {
    final service = SalesFinancialService(store: store);
    final transaction = await service.postSaleReceivable(
      delivery(),
      customerName: 'مشتری آزمایشی',
    );
    expect(transaction.isBalanced, isTrue);
    expect(await store.getBalance('customer-customer-1'), 400000);
    expect(await store.getBalance('sales-revenue'), -400000);
  });

  test('posting the same delivery twice is idempotent', () async {
    final service = SalesFinancialService(store: store);
    final first = await service.postSaleReceivable(delivery(), customerName: 'مشتری آزمایشی');
    final second = await service.postSaleReceivable(delivery(), customerName: 'مشتری آزمایشی');
    expect(second.id, first.id);
    expect((await store.getTransactions()).length, 1);
  });

  test('receipt reduces customer balance and increases cash', () async {
    final service = SalesFinancialService(store: store);
    await service.postSaleReceivable(delivery(), customerName: 'مشتری آزمایشی');
    await service.recordReceipt(
      receiptId: 'receipt-1',
      customerId: 'customer-1',
      customerName: 'مشتری آزمایشی',
      amount: 150000,
    );
    expect(await store.getBalance('customer-customer-1'), 250000);
    expect(await store.getBalance('cash'), 150000);
  });
  test('rejects receipt greater than outstanding balance', () async {
    final service = SalesFinancialService(store: store);
    await service.postSaleReceivable(delivery(), customerName: 'مشتری آزمایشی');

    expect(
      () => service.recordReceipt(
        receiptId: 'receipt-over',
        customerId: 'customer-1',
        customerName: 'مشتری آزمایشی',
        amount: 400001,
      ),
      throwsA(isA<StateError>()),
    );
    expect(await store.getBalance('customer-customer-1'), 400000);
  });

  test('rejects receipt when customer has no outstanding balance', () async {
    final service = SalesFinancialService(store: store);

    expect(
      () => service.recordReceipt(
        receiptId: 'receipt-none',
        customerId: 'customer-1',
        customerName: 'مشتری آزمایشی',
        amount: 1,
      ),
      throwsA(isA<StateError>()),
    );
  });


  test('invoice payment by another customer reduces the invoice owner only', () async {
    final service = SalesFinancialService(store: store);
    await CustomerStore.instance.upsert(const Customer(
      id: 'payer-1',
      name: 'عضو باشگاه',
    ));

    final invoiceDelivery = SalesDelivery(
      id: 'delivery-club-1',
      orderId: 'club-invoice-1',
      customerId: 'club-1',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 400000,
    );
    await SalesDeliveryStore.instance.add(invoiceDelivery);
    await service.postSaleReceivable(
      invoiceDelivery,
      customerName: 'باشگاه ورزشی',
    );

    await service.recordReceipt(
      receiptId: 'receipt-club-1',
      customerId: 'club-1',
      customerName: 'باشگاه ورزشی',
      orderId: 'club-invoice-1',
      payerId: 'payer-1',
      payerName: 'عضو باشگاه',
      amount: 150000,
      note: 'پرداخت عضو بابت فاکتور باشگاه',
    );

    expect(await store.getBalance('customer-club-1'), 250000);
    expect(await store.getBalance('customer-payer-1'), 0);

    final receipts = await SalesReceiptStore.instance.getByPayerId('payer-1');
    expect(receipts, hasLength(1));
    expect(receipts.single.orderId, 'club-invoice-1');
    expect(receipts.single.customerId, 'club-1');
    expect(receipts.single.amount, 150000);
  });

  test('invoice cannot receive more than its remaining balance', () async {
    final service = SalesFinancialService(store: store);
    final invoiceDelivery = SalesDelivery(
      id: 'delivery-club-2',
      orderId: 'club-invoice-2',
      customerId: 'club-2',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 200000,
    );
    await SalesDeliveryStore.instance.add(invoiceDelivery);
    await service.postSaleReceivable(invoiceDelivery, customerName: 'باشگاه دو');

    expect(
      () => service.recordReceipt(
        receiptId: 'receipt-club-over',
        customerId: 'club-2',
        customerName: 'باشگاه دو',
        orderId: 'club-invoice-2',
        amount: 200001,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('same receipt id remains idempotent with payer attribution', () async {
    final service = SalesFinancialService(store: store);
    await CustomerStore.instance.upsert(const Customer(
      id: 'payer-2',
      name: 'عضو دوم',
    ));
    final invoiceDelivery = SalesDelivery(
      id: 'delivery-club-3',
      orderId: 'club-invoice-3',
      customerId: 'club-3',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 300000,
    );
    await SalesDeliveryStore.instance.add(invoiceDelivery);
    await service.postSaleReceivable(invoiceDelivery, customerName: 'باشگاه سه');

    final first = await service.recordReceipt(
      receiptId: 'receipt-club-idempotent',
      customerId: 'club-3',
      customerName: 'باشگاه سه',
      orderId: 'club-invoice-3',
      payerId: 'payer-2',
      payerName: 'عضو دوم',
      amount: 100000,
    );
    final second = await service.recordReceipt(
      receiptId: 'receipt-club-idempotent',
      customerId: 'club-3',
      customerName: 'باشگاه سه',
      orderId: 'club-invoice-3',
      payerId: 'payer-2',
      payerName: 'عضو دوم',
      amount: 100000,
    );

    expect(second.id, first.id);
    expect(await store.getBalance('customer-club-3'), 200000);
    expect((await SalesReceiptStore.instance.getByPayerId('payer-2')), hasLength(1));
  });
}
