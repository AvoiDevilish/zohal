import '../storage/local_store.dart';
import 'customer.dart';
import 'customer_validator.dart';

class CustomerStore {
  CustomerStore._();

  static final CustomerStore instance = CustomerStore._();

  static const String _storageKey = 'customers';

  Future<List<Customer>> getCustomers({bool includeInactive = true}) async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final customers = rows
        .map(Customer.fromMap)
        .where((customer) => includeInactive || customer.active)
        .toList();

    customers.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    return customers;
  }

  Future<Customer?> getById(String id) async {
    final customers = await getCustomers();
    for (final customer in customers) {
      if (customer.id == id) {
        return customer;
      }
    }
    return null;
  }

  Future<void> add(Customer customer) async {
    const validator = CustomerValidator();
    validator.validate(customer);

    final customers = await getCustomers();

    if (customers.any((item) => item.id == customer.id)) {
      throw StateError('Customer with id "${customer.id}" already exists.');
    }

    customers.add(customer);

    await LocalStore.instance.writeList(
      _storageKey,
      customers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> update(Customer customer) async {
    const validator = CustomerValidator();
    validator.validate(customer);

    final customers = await getCustomers();
    final index = customers.indexWhere((item) => item.id == customer.id);

    if (index == -1) {
      throw StateError('Customer with id "${customer.id}" does not exist.');
    }

    customers[index] = customer;

    await LocalStore.instance.writeList(
      _storageKey,
      customers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> deactivate(String id) async {
    final customer = await getById(id);

    if (customer == null) {
      throw StateError('Customer with id "$id" does not exist.');
    }

    await update(customer.copyWith(active: false));
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
