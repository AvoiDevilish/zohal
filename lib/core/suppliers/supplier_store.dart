import '../storage/local_store.dart';
import 'supplier.dart';
import 'supplier_validator.dart';

class SupplierStore {
  SupplierStore._();

  static final SupplierStore instance = SupplierStore._();

  static const String _storageKey = 'suppliers';

  Future<List<Supplier>> getSuppliers({bool includeInactive = true}) async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final suppliers = rows.map(Supplier.fromMap).toList();

    if (!includeInactive) {
      suppliers.removeWhere((supplier) => !supplier.active);
    }

    suppliers.sort((a, b) => a.name.compareTo(b.name));

    return suppliers;
  }

  Future<Supplier?> getById(String id) async {
    final suppliers = await getSuppliers();

    for (final supplier in suppliers) {
      if (supplier.id == id) {
        return supplier;
      }
    }

    return null;
  }

  Future<void> add(Supplier supplier) async {
    const validator = SupplierValidator();
    validator.validate(supplier);

    final existing = await getById(supplier.id);

    if (existing != null) {
      throw StateError(
        'تأمین‌کننده با شناسه ${supplier.id} قبلاً ثبت شده است.',
      );
    }

    final suppliers = await getSuppliers();
    suppliers.add(supplier);

    await _save(suppliers);
  }

  Future<void> update(Supplier supplier) async {
    const validator = SupplierValidator();
    validator.validate(supplier);

    final suppliers = await getSuppliers();

    final index = suppliers.indexWhere((item) => item.id == supplier.id);

    if (index == -1) {
      throw StateError('تأمین‌کننده با شناسه ${supplier.id} پیدا نشد.');
    }

    suppliers[index] = supplier;

    await _save(suppliers);
  }

  Future<void> deactivate(String id) async {
    final supplier = await getById(id);

    if (supplier == null) {
      throw StateError('تأمین‌کننده با شناسه $id پیدا نشد.');
    }

    await update(supplier.copyWith(active: false));
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }

  Future<void> _save(List<Supplier> suppliers) async {
    await LocalStore.instance.writeList(
      _storageKey,
      suppliers.map((supplier) => supplier.toMap()).toList(),
    );
  }
}
