import '../storage/local_store.dart';
import 'person.dart';

class PersonStore {
  PersonStore._();
  static final PersonStore instance = PersonStore._();
  static const _storageKey = 'people';

  Future<List<Person>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(Person.fromMap).toList();
  }

  Future<Person?> getById(String id) async {
    for (final person in await getAll()) {
      if (person.id == id) return person;
    }
    return null;
  }

  Future<void> upsert(Person person) async {
    if (person.roles.isEmpty) throw StateError('شخص باید حداقل یک نقش داشته باشد.');
    final people = await getAll();
    final index = people.indexWhere((item) => item.id == person.id);
    if (index == -1) {
      people.add(person);
    } else {
      people[index] = person;
    }
    await LocalStore.instance.writeList(
      _storageKey,
      people.map((item) => item.toMap()).toList(),
    );
  }

  Future<List<Person>> getCustomers() async {
    return (await getAll()).where((person) => person.isCustomer).toList();
  }

  Future<List<Person>> getSuppliers() async {
    return (await getAll()).where((person) => person.isSupplier).toList();
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
