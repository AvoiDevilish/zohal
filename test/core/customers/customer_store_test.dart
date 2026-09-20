import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/customers/customer.dart';
import 'package:zohal_android_test/core/customers/customer_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await CustomerStore.instance.clear();
  });

  test('stores and retrieves customer', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      note: 'خریدار محصولات زحل و تأمین‌کننده آجیل',
      createdAt: DateTime(2026, 1, 1),
    );

    await CustomerStore.instance.add(customer);

    final result = await CustomerStore.instance.getById('customer-gholami');

    expect(result, isNotNull);
    expect(result!.name, 'آقای غلامی');
    expect(result.note, contains('آجیل'));
  });

  test('persists customer data', () async {
    final customer = Customer(
      id: 'customer-1',
      name: 'مشتری تست',
      phone: '09120000000',
      createdAt: DateTime(2026, 1, 1),
    );

    await CustomerStore.instance.add(customer);

    final customers = await CustomerStore.instance.getCustomers();

    expect(customers, hasLength(1));
    expect(customers.first.phone, '09120000000');
  });

  test('rejects duplicate customer id', () async {
    final customer = Customer(
      id: 'customer-1',
      name: 'مشتری تست',
      createdAt: DateTime(2026, 1, 1),
    );

    await CustomerStore.instance.add(customer);

    expect(
      () => CustomerStore.instance.add(customer),
      throwsA(isA<StateError>()),
    );
  });

  test('updates customer', () async {
    final customer = Customer(
      id: 'customer-1',
      name: 'مشتری اولیه',
      createdAt: DateTime(2026, 1, 1),
    );

    await CustomerStore.instance.add(customer);

    await CustomerStore.instance.update(
      customer.copyWith(name: 'مشتری به‌روزشده', phone: '09121111111'),
    );

    final result = await CustomerStore.instance.getById('customer-1');

    expect(result!.name, 'مشتری به‌روزشده');
    expect(result.phone, '09121111111');
  });

  test('deactivates customer without deleting history', () async {
    final customer = Customer(
      id: 'customer-1',
      name: 'مشتری تست',
      createdAt: DateTime(2026, 1, 1),
    );

    await CustomerStore.instance.add(customer);
    await CustomerStore.instance.deactivate('customer-1');

    final all = await CustomerStore.instance.getCustomers();
    final activeOnly = await CustomerStore.instance.getCustomers(
      includeInactive: false,
    );

    expect(all, hasLength(1));
    expect(all.first.active, isFalse);
    expect(activeOnly, isEmpty);
  });

  test('rejects invalid customer', () async {
    final invalid = Customer(
      id: '',
      name: 'مشتری تست',
      createdAt: DateTime(2026, 1, 1),
    );

    expect(
      () => CustomerStore.instance.add(invalid),
      throwsA(isA<ArgumentError>()),
    );
  });
}
