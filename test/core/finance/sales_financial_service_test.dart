import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';
import 'package:zohal_android_test/core/sales/sales_delivery.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_store.dart';
import 'package:zohal_android_test/core/sales/sales_receipt_store.dart';
import 'package:zohal_android_test/core/sales/sales_return_store.dart';
import 'package:zohal_android_test/core/sales/sales_return.dart';
import 'package:zohal_android_test/core/sales/sales_credit_allocation_store.dart';
import 'package:zohal_android_test/core/sales/sales_credit_entry_store.dart';
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
    await SalesCreditAllocationStore.instance.clear();
    await SalesCreditEntryStore.instance.clear();
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

  test('multiple payments by different payers settle the same invoice independently', () async {
    final service = SalesFinancialService(store: store);
    await CustomerStore.instance.upsert(const Customer(
      id: 'payer-a',
      name: 'پرداخت‌کننده اول',
    ));
    await CustomerStore.instance.upsert(const Customer(
      id: 'payer-b',
      name: 'پرداخت‌کننده دوم',
    ));

    final invoiceDelivery = SalesDelivery(
      id: 'delivery-multi-payer',
      orderId: 'invoice-multi-payer',
      customerId: 'club-multi',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 500000,
    );
    await SalesDeliveryStore.instance.add(invoiceDelivery);
    await service.postSaleReceivable(invoiceDelivery, customerName: 'باشگاه چند پرداختی');

    await service.recordReceipt(
      receiptId: 'receipt-payer-a',
      customerId: 'club-multi',
      customerName: 'باشگاه چند پرداختی',
      orderId: 'invoice-multi-payer',
      payerId: 'payer-a',
      payerName: 'پرداخت‌کننده اول',
      amount: 200000,
    );
    await service.recordReceipt(
      receiptId: 'receipt-payer-b',
      customerId: 'club-multi',
      customerName: 'باشگاه چند پرداختی',
      orderId: 'invoice-multi-payer',
      payerId: 'payer-b',
      payerName: 'پرداخت‌کننده دوم',
      amount: 300000,
    );

    expect(await service.getInvoiceOutstanding(
      orderId: 'invoice-multi-payer',
      customerId: 'club-multi',
    ), 0);
    expect(await store.getBalance('customer-club-multi'), 0);
    expect(await store.getBalance('customer-payer-a'), 0);
    expect(await store.getBalance('customer-payer-b'), 0);
    expect(await store.getBalance('cash'), 500000);
    expect(await SalesReceiptStore.instance.getByPayerId('payer-a'), hasLength(1));
    expect(await SalesReceiptStore.instance.getByPayerId('payer-b'), hasLength(1));
  });

  test('return after full payment creates customer credit', () async {
    final service = SalesFinancialService(store: store);
    final firstDelivery = SalesDelivery(
      id: 'delivery-credit-source',
      orderId: 'invoice-credit-source',
      customerId: 'customer-credit',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 400000,
    );
    await SalesDeliveryStore.instance.add(firstDelivery);
    await service.postSaleReceivable(firstDelivery, customerName: 'مشتری بستانکار');

    await service.recordReceipt(
      receiptId: 'receipt-credit-source',
      customerId: 'customer-credit',
      customerName: 'مشتری بستانکار',
      orderId: 'invoice-credit-source',
      amount: 400000,
    );

    final salesReturn = SalesReturn(
      id: 'return-credit-source',
      deliveryId: firstDelivery.id,
      orderId: firstDelivery.orderId,
      customerId: firstDelivery.customerId,
      customerName: 'مشتری بستانکار',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 100000,
    );
    await SalesReturnStore.instance.add(salesReturn);
    await service.postSaleReturn(salesReturn, customerName: 'مشتری بستانکار');

    expect(await store.getBalance('customer-customer-credit'), -100000);
    expect(await service.getCustomerCredit('customer-credit'), 100000);
    expect(await service.getInvoiceOutstanding(
      orderId: 'invoice-credit-source',
      customerId: 'customer-credit',
    ), -100000);
  });

  test('customer credit can be allocated to a later invoice without changing the payer account', () async {
    final service = SalesFinancialService(store: store);

    final sourceDelivery = SalesDelivery(
      id: 'delivery-credit-source-2',
      orderId: 'invoice-credit-source-2',
      customerId: 'customer-credit-2',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 300000,
    );
    await SalesDeliveryStore.instance.add(sourceDelivery);
    await service.postSaleReceivable(sourceDelivery, customerName: 'مشتری اعتبار دوم');
    await service.recordReceipt(
      receiptId: 'receipt-credit-source-2',
      customerId: 'customer-credit-2',
      customerName: 'مشتری اعتبار دوم',
      orderId: 'invoice-credit-source-2',
      amount: 300000,
    );

    final salesReturn = SalesReturn(
      id: 'return-credit-source-2',
      deliveryId: sourceDelivery.id,
      orderId: sourceDelivery.orderId,
      customerId: sourceDelivery.customerId,
      customerName: 'مشتری اعتبار دوم',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 100000,
    );
    await SalesReturnStore.instance.add(salesReturn);
    await service.postSaleReturn(salesReturn, customerName: 'مشتری اعتبار دوم');

    final nextDelivery = SalesDelivery(
      id: 'delivery-credit-target',
      orderId: 'invoice-credit-target',
      customerId: 'customer-credit-2',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 250000,
    );
    await SalesDeliveryStore.instance.add(nextDelivery);
    await service.postSaleReceivable(nextDelivery, customerName: 'مشتری اعتبار دوم');

    final allocation = await service.applyCustomerCredit(
      allocationId: 'credit-allocation-1',
      orderId: 'invoice-credit-target',
      customerId: 'customer-credit-2',
      amount: 100000,
      note: 'استفاده از بستانکاری برگشت قبلی',
    );

    expect(allocation.amount, 100000);
    expect(await service.getInvoiceOutstanding(
      orderId: 'invoice-credit-target',
      customerId: 'customer-credit-2',
    ), 150000);
    expect(await store.getBalance('customer-customer-credit-2'), 150000);
    expect(await SalesCreditAllocationStore.instance.getByOrderId('invoice-credit-target'), hasLength(1));
  });

  test('return on an unpaid invoice does not create reusable customer credit', () async {
    final service = SalesFinancialService(store: store);
    final delivery = SalesDelivery(
      id: 'delivery-unpaid-return',
      orderId: 'invoice-unpaid-return',
      customerId: 'customer-unpaid-return',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 200000,
    );
    await SalesDeliveryStore.instance.add(delivery);
    await service.postSaleReceivable(delivery, customerName: 'مشتری نسیه');
    final salesReturn = SalesReturn(
      id: 'return-unpaid-return',
      deliveryId: delivery.id,
      orderId: delivery.orderId,
      customerId: delivery.customerId,
      customerName: 'مشتری نسیه',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 50000,
    );
    await SalesReturnStore.instance.add(salesReturn);
    await service.postSaleReturn(salesReturn, customerName: 'مشتری نسیه');

    expect(await service.getCustomerCredit('customer-unpaid-return'), 0);
    expect(await store.getBalance('customer-customer-unpaid-return'), 150000);
  });


  test('customer credit allocation cannot exceed available credit or invoice balance', () async {
    final service = SalesFinancialService(store: store);
    final sourceDelivery = SalesDelivery(
      id: 'delivery-credit-limit',
      orderId: 'invoice-credit-limit-source',
      customerId: 'customer-credit-limit',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 100000,
    );
    await SalesDeliveryStore.instance.add(sourceDelivery);
    await service.postSaleReceivable(sourceDelivery, customerName: 'مشتری محدود');
    await service.recordReceipt(
      receiptId: 'receipt-credit-limit',
      customerId: 'customer-credit-limit',
      customerName: 'مشتری محدود',
      orderId: 'invoice-credit-limit-source',
      amount: 100000,
    );
    final salesReturn = SalesReturn(
      id: 'return-credit-limit',
      deliveryId: sourceDelivery.id,
      orderId: sourceDelivery.orderId,
      customerId: sourceDelivery.customerId,
      customerName: 'مشتری محدود',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 50000,
    );
    await SalesReturnStore.instance.add(salesReturn);
    await service.postSaleReturn(salesReturn, customerName: 'مشتری محدود');

    final targetDelivery = SalesDelivery(
      id: 'delivery-credit-limit-target',
      orderId: 'invoice-credit-limit-target',
      customerId: 'customer-credit-limit',
      createdAt: DateTime(2026, 10, 5),
      lines: const [],
      totalAmount: 30000,
    );
    await SalesDeliveryStore.instance.add(targetDelivery);
    await service.postSaleReceivable(targetDelivery, customerName: 'مشتری محدود');

    expect(
      () => service.applyCustomerCredit(
        allocationId: 'credit-too-much',
        orderId: 'invoice-credit-limit-target',
        customerId: 'customer-credit-limit',
        amount: 50001,
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      () => service.applyCustomerCredit(
        allocationId: 'credit-too-much-invoice',
        orderId: 'invoice-credit-limit-target',
        customerId: 'customer-credit-limit',
        amount: 30001,
      ),
      throwsA(isA<StateError>()),
    );
  });

}
