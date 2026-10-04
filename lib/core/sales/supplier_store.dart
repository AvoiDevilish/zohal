import '../storage/local_store.dart';
import 'supplier.dart';

class SupplierStore {
  SupplierStore._();

  static final SupplierStore instance = SupplierStore._();

  static const String _storageKey = 'suppliers';

  Future<List<Supplier>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(Supplier.fromMap).toList();
  }

  Future<void> upsert(Supplier supplier) async {
    final suppliers = await getAll();
    final index = suppliers.indexWhere((item) => item.id == supplier.id);

    if (index == -1) {
      suppliers.add(supplier);
    } else {
      suppliers[index] = supplier;
    }

    await LocalStore.instance.writeList(
      _storageKey,
      suppliers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> deactivate(String id) async {
    final suppliers = await getAll();
    final index = suppliers.indexWhere((item) => item.id == id);
    if (index == -1) return;
    suppliers[index] = Supplier(
      id: suppliers[index].id,
      name: suppliers[index].name,
      phone: suppliers[index].phone,
      notes: suppliers[index].notes,
      isActive: false,
    );
    await LocalStore.instance.writeList(
      _storageKey,
      suppliers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
