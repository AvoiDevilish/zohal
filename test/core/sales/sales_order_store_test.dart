import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/sales/sales_order_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SalesOrderStore.instance.clear();
  });

  test('creates an order with a price snapshot and workshop-pending status', () async {
    final store = SalesOrderStore.instance;
    final order = SalesOrder(
      id: 'order-1',
      customerId: 'customer-1',
      customerName: 'مشتری تست',
      orderDate: DateTime(2026, 10, 5),
      lines: [
        const SalesOrderLine(
          productVariantId: 'product-100',
          productName: 'خرمای آجیلی',
          flavor: 'زنجبیل',
          packageLabel: '۱۰۰ گرم',
          quantity: 4,
          unitSellingPrice: 150000,
          lineTotal: 600000,
        ),
      ],
      totalAmount: 600000,
    );

    await store.create(order);
    final saved = (await store.getAll()).single;

    expect(saved.status, SalesOrderStatus.workshopPending);
    expect(saved.customerId, 'customer-1');
    expect(saved.lines.single.unitSellingPrice, 150000);
    expect(saved.lines.single.lineTotal, 600000);
    expect(saved.totalAmount, 600000);
  });

  test('order keeps its original price after current price changes', () async {
    final store = SalesOrderStore.instance;
    final order = SalesOrder(
      id: 'order-2',
      customerId: 'customer-1',
      customerName: 'مشتری تست',
      orderDate: DateTime(2026, 10, 5),
      lines: [
        const SalesOrderLine(
          productVariantId: 'product-100',
          productName: 'خرمای آجیلی',
          flavor: 'آرد نخودچی',
          packageLabel: '۱۰۰ گرم',
          quantity: 2,
          unitSellingPrice: 150000,
          lineTotal: 300000,
        ),
      ],
      totalAmount: 300000,
    );

    await store.create(order);
    final saved = (await store.getAll()).single;

    expect(saved.lines.single.unitSellingPrice, 150000);
    expect(saved.totalAmount, 300000);
  });
}
