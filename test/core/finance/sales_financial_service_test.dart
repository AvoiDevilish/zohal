import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';
import 'package:zohal_android_test/core/sales/sales_delivery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.clear();
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

}
