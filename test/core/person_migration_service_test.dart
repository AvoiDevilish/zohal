import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/people/person.dart';
import 'package:zohal_android_test/core/people/person_migration_service.dart';
import 'package:zohal_android_test/core/people/person_store.dart';
import 'package:zohal_android_test/core/sales/customer.dart';
import 'package:zohal_android_test/core/sales/customer_store.dart';
import 'package:zohal_android_test/core/sales/supplier.dart';
import 'package:zohal_android_test/core/sales/supplier_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final people = PersonStore.instance;
  final customers = CustomerStore.instance;
  final suppliers = SupplierStore.instance;
  final finance = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await people.clear();
    await customers.clear();
    await suppliers.clear();
    await finance.clear();
  });

  PersonMigrationService service() => PersonMigrationService(
    personStore: people,
    customerStore: customers,
    supplierStore: suppliers,
    financialStore: finance,
  );

  test('migrates legacy customer into unified person and financial account', () async {
    await customers.upsert(const Customer(
      id: 'p1',
      name: 'مشتری یک',
      phone: '0912',
    ));

    final result = await service().migrateLegacyPeople();
    final person = await people.getById('p1');

    expect(result.length, 1);
    expect(person, isNotNull);
    expect(person!.isCustomer, isTrue);
    expect(person.isSupplier, isFalse);
    expect(person.phone, '0912');
    expect((await finance.getAccount('customer-p1'))!.type,
        FinancialAccountType.customer);
  });

  test('merges customer and supplier roles for the same person id', () async {
    await customers.upsert(const Customer(
      id: 'p1',
      name: 'شخص مشترک',
    ));
    await suppliers.upsert(const Supplier(
      id: 'p1',
      name: 'شخص مشترک',
    ));

    await service().migrateLegacyPeople();
    final person = await people.getById('p1');

    expect(person!.roles, containsAll([PersonRole.customer, PersonRole.supplier]));
    expect(await finance.getAccount('customer-p1'), isNotNull);
    expect(await finance.getAccount('supplier-p1'), isNotNull);
  });

  test('existing person identity is preserved while adding a legacy role', () async {
    await people.upsert(const Person(
      id: 'p1',
      name: 'نام اصلی',
      roles: {PersonRole.customer},
      phone: '0900',
    ));
    await suppliers.upsert(const Supplier(
      id: 'p1',
      name: 'نام تأمین‌کننده',
      phone: '0911',
    ));

    await service().migrateLegacyPeople();
    final person = await people.getById('p1');

    expect(person!.roles, containsAll([PersonRole.customer, PersonRole.supplier]));
    expect(person.phone, '0911');
    expect(person.name, 'نام تأمین‌کننده');
  });

  test('person store rejects a person without roles', () async {
    expect(
      () => people.upsert(const Person(
        id: 'empty',
        name: 'بدون نقش',
        roles: {},
      )),
      throwsA(isA<StateError>()),
    );
  });
}
