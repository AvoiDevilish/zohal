import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/customers/customer.dart';
import 'package:zohal_android_test/core/customers/customer_store.dart';
import 'package:zohal_android_test/core/finance/finance_service.dart';
import 'package:zohal_android_test/core/finance/receivable.dart';
import 'package:zohal_android_test/core/finance/payment.dart';
import 'package:zohal_android_test/core/finance/payment_store.dart';
import 'package:zohal_android_test/core/finance/receivable_store.dart';
import 'package:zohal_android_test/core/sales/sale.dart';
import 'package:zohal_android_test/core/sales/sale_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CustomerStore customerStore;
  late ReceivableStore receivableStore;
  late PaymentStore paymentStore;
  late FinanceService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    customerStore = CustomerStore.instance;
    receivableStore = ReceivableStore.instance;
    paymentStore = PaymentStore.instance;

    await customerStore.clear();
    await receivableStore.clear();
    await paymentStore.clear();

    service = FinanceService(
      receivableStore: receivableStore,
      paymentStore: paymentStore,
      customerStore: customerStore,
    );
  });

  test('creates receivable from sale', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    expect(receivable.totalAmount, 5000000);
    expect(receivable.paidAmount, 0);
    expect(receivable.remainingAmount, 5000000);
    expect(receivable.status, ReceivableStatus.open);
  });

  test('registers partial payment and updates receivable', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    final result = await service.registerPayment(
      Payment(
        id: 'payment-1',
        receivableId: receivable.id,
        customerId: customer.id,
        customerName: customer.name,
        amount: 2000000,
        method: PaymentMethod.bankTransfer,
        paymentDate: DateTime(2026, 1, 3),
      ),
    );

    expect(result.receivable.paidAmount, 2000000);
    expect(result.remainingAmount, 3000000);
    expect(result.receivable.status, ReceivableStatus.partiallyPaid);
  });

  test('fully settles receivable', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    final result = await service.registerPayment(
      Payment(
        id: 'payment-1',
        receivableId: receivable.id,
        customerId: customer.id,
        customerName: customer.name,
        amount: 5000000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 1, 3),
      ),
    );

    expect(result.receivable.remainingAmount, 0);
    expect(result.receivable.status, ReceivableStatus.paid);
  });

  test('supports multiple payments', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    await service.registerPayment(
      Payment(
        id: 'payment-1',
        receivableId: receivable.id,
        customerId: customer.id,
        customerName: customer.name,
        amount: 1000000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 1, 3),
      ),
    );

    final second = await service.registerPayment(
      Payment(
        id: 'payment-2',
        receivableId: receivable.id,
        customerId: customer.id,
        customerName: customer.name,
        amount: 1500000,
        method: PaymentMethod.card,
        paymentDate: DateTime(2026, 1, 4),
      ),
    );

    expect(second.receivable.paidAmount, 2500000);
    expect(second.receivable.remainingAmount, 2500000);
    expect(second.receivable.status, ReceivableStatus.partiallyPaid);

    expect(await paymentStore.getPayments(), hasLength(2));
  });

  test('rejects payment above remaining amount', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    expect(
      () => service.registerPayment(
        Payment(
          id: 'payment-1',
          receivableId: receivable.id,
          customerId: customer.id,
          customerName: customer.name,
          amount: 6000000,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 1, 3),
        ),
      ),
      throwsA(isA<StateError>()),
    );

    final stored = await receivableStore.getById(receivable.id);

    expect(stored!.paidAmount, 0);
    expect(stored.status, ReceivableStatus.open);
    expect(await paymentStore.getPayments(), isEmpty);
  });

  test('does not register the same payment twice', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 10,
          unitPrice: 500000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final receivable = await service.createReceivableFromSale(sale);

    final payment = Payment(
      id: 'payment-1',
      receivableId: receivable.id,
      customerId: customer.id,
      customerName: customer.name,
      amount: 2000000,
      method: PaymentMethod.bankTransfer,
      paymentDate: DateTime(2026, 1, 3),
    );

    final first = await service.registerPayment(payment);
    final second = await service.registerPayment(payment);

    expect(first.remainingAmount, 3000000);
    expect(second.remainingAmount, 3000000);

    final stored = await receivableStore.getById(receivable.id);

    expect(stored!.paidAmount, 2000000);
    expect(await paymentStore.getPayments(), hasLength(1));
  });
}
