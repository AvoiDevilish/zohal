import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../lib/core/suppliers/supplier.dart';
import '../../../lib/core/suppliers/supplier_store.dart';
import '../../../lib/core/suppliers/supplier_validator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SupplierStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = SupplierStore.instance;
    await store.clear();
  });

  test('stores and retrieves supplier', () async {
    const supplier = Supplier(
      id: 'supplier-001',
      name: 'تأمین‌کننده خرما',
      phone: '09120000000',
      address: 'دشتستان',
    );

    await store.add(supplier);

    final result = await store.getById('supplier-001');

    expect(result, isNotNull);
    expect(result!.name, 'تأمین‌کننده خرما');
    expect(result.phone, '09120000000');
    expect(result.address, 'دشتستان');
    expect(result.active, isTrue);
  });

  test('persists supplier data', () async {
    await store.add(
      const Supplier(id: 'supplier-002', name: 'تأمین‌کننده مغزها'),
    );

    final suppliers = await store.getSuppliers();

    expect(suppliers.length, 1);
    expect(suppliers.single.id, 'supplier-002');
  });

  test('rejects duplicate supplier id', () async {
    const supplier = Supplier(id: 'supplier-003', name: 'تأمین‌کننده');

    await store.add(supplier);

    expect(() => store.add(supplier), throwsA(isA<StateError>()));
  });

  test('updates supplier', () async {
    await store.add(const Supplier(id: 'supplier-004', name: 'نام اولیه'));

    await store.update(
      const Supplier(
        id: 'supplier-004',
        name: 'نام جدید',
        phone: '09121111111',
      ),
    );

    final supplier = await store.getById('supplier-004');

    expect(supplier!.name, 'نام جدید');
    expect(supplier.phone, '09121111111');
  });

  test('deactivates supplier without deleting history', () async {
    await store.add(
      const Supplier(id: 'supplier-005', name: 'تأمین‌کننده قدیمی'),
    );

    await store.deactivate('supplier-005');

    final all = await store.getSuppliers();
    final activeOnly = await store.getSuppliers(includeInactive: false);

    expect(all.length, 1);
    expect(all.single.active, isFalse);
    expect(activeOnly, isEmpty);
  });

  test('rejects invalid supplier', () {
    const supplier = Supplier(id: '', name: '');

    expect(
      () => const SupplierValidator().validate(supplier),
      throwsA(isA<SupplierValidationException>()),
    );
  });
}
