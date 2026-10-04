import '../storage/local_store.dart';
import '../people/person.dart';
import '../people/person_store.dart';
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
    final person = await PersonStore.instance.getById(supplier.id);
    await PersonStore.instance.upsert(Person(
      id: supplier.id,
      name: supplier.name,
      roles: {...(person?.roles ?? const <PersonRole>{}), PersonRole.supplier},
      phone: supplier.phone,
      notes: supplier.notes,
      isActive: supplier.isActive,
    ));
  }

  Future<void> setActive(String id, bool active) async {
    final suppliers = await getAll();
    final index = suppliers.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = suppliers[index];
    suppliers[index] = Supplier(
      id: current.id,
      name: current.name,
      phone: current.phone,
      notes: current.notes,
      isActive: active,
    );
    await LocalStore.instance.writeList(
      _storageKey,
      suppliers.map((item) => item.toMap()).toList(),
    );
    final person = await PersonStore.instance.getById(id);
    if (person != null) {
      await PersonStore.instance.upsert(person.copyWith(isActive: active));
    }
  }

  Future<void> deactivate(String id) async {
    await setActive(id, false);
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
