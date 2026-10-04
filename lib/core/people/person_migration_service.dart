import '../finance/financial_account.dart';
import '../finance/financial_store.dart';
import '../sales/customer_store.dart';
import '../sales/supplier_store.dart';
import 'person.dart';
import 'person_store.dart';

class PersonMigrationService {
  final PersonStore personStore;
  final CustomerStore customerStore;
  final SupplierStore supplierStore;
  final FinancialStore financialStore;

  const PersonMigrationService({
    required this.personStore,
    required this.customerStore,
    required this.supplierStore,
    required this.financialStore,
  });

  Future<List<Person>> migrateLegacyPeople() async {
    final existing = {for (final person in await personStore.getAll()) person.id: person};

    for (final customer in await customerStore.getAll()) {
      final current = existing[customer.id];
      final person = Person(
        id: customer.id,
        name: customer.name,
        roles: {...?current?.roles, PersonRole.customer},
        phone: customer.phone,
        notes: customer.notes,
        isActive: customer.isActive,
      );
      await personStore.upsert(person);
      existing[person.id] = person;
      await financialStore.ensureAccount(FinancialAccount(
        id: 'customer-' + customer.id,
        name: customer.name,
        type: FinancialAccountType.customer,
      ));
    }

    for (final supplier in await supplierStore.getAll()) {
      final current = existing[supplier.id];
      final person = Person(
        id: supplier.id,
        name: supplier.name,
        roles: {...?current?.roles, PersonRole.supplier},
        phone: supplier.phone,
        notes: supplier.notes,
        isActive: supplier.isActive,
      );
      await personStore.upsert(person);
      existing[person.id] = person;
      await financialStore.ensureAccount(FinancialAccount(
        id: 'supplier-' + supplier.id,
        name: supplier.name,
        type: FinancialAccountType.supplier,
      ));
    }

    return personStore.getAll();
  }
}
