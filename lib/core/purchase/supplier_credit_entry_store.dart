import '../storage/local_store.dart';
import 'supplier_credit_entry.dart';

class SupplierCreditEntryStore {
  SupplierCreditEntryStore._();
  static final SupplierCreditEntryStore instance = SupplierCreditEntryStore._();
  static const _storageKey = 'supplier_credit_entries';

  Future<List<SupplierCreditEntry>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SupplierCreditEntry.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SupplierCreditEntry?> getById(String id) async {
    for (final entry in await getAll()) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  Future<List<SupplierCreditEntry>> getBySupplierId(String supplierId) async =>
      (await getAll()).where((entry) => entry.supplierId == supplierId).toList();

  Future<void> add(SupplierCreditEntry entry) async {
    if (await getById(entry.id) != null) {
      throw StateError('اعتبار تأمین‌کننده قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(entry);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
