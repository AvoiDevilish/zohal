import '../storage/local_store.dart';
import 'sales_credit_entry.dart';

class SalesCreditEntryStore {
  SalesCreditEntryStore._();

  static final SalesCreditEntryStore instance = SalesCreditEntryStore._();
  static const _storageKey = 'sales_credit_entries';

  Future<List<SalesCreditEntry>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesCreditEntry.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SalesCreditEntry?> getById(String id) async {
    for (final item in await getAll()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<List<SalesCreditEntry>> getByCustomerId(String customerId) async {
    return (await getAll()).where((item) => item.customerId == customerId).toList();
  }

  Future<void> add(SalesCreditEntry entry) async {
    if (entry.amount <= 0) {
      throw ArgumentError('مبلغ اعتبار باید بیشتر از صفر باشد.');
    }
    if (await getById(entry.id) != null) {
      throw StateError('اعتبار قبلاً ثبت شده است.');
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
