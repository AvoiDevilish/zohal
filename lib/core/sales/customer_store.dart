import '../storage/local_store.dart';
import 'customer.dart';

class CustomerStore {
  CustomerStore._();

  static final CustomerStore instance = CustomerStore._();
  static const String _storageKey = 'customers';

  Future<List<Customer>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(Customer.fromMap).toList();
  }

  Future<void> upsert(Customer customer) async {
    final customers = await getAll();
    final index = customers.indexWhere((item) => item.id == customer.id);
    if (index == -1) {
      customers.add(customer);
    } else {
      customers[index] = customer;
    }
    await LocalStore.instance.writeList(
      _storageKey,
      customers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> setActive(String id, bool active) async {
    final customers = await getAll();
    final index = customers.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = customers[index];
    customers[index] = Customer(
      id: current.id,
      name: current.name,
      phone: current.phone,
      notes: current.notes,
      isActive: active,
    );
    await LocalStore.instance.writeList(
      _storageKey,
      customers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
