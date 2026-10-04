import 'storage/local_store.dart';
import 'purchase.dart';

class PurchaseStore {
  PurchaseStore._();
  static final PurchaseStore instance = PurchaseStore._();
  static const _storageKey = 'purchases';

  Future<List<Purchase>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(Purchase.fromMap).toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Purchase?> getById(String id) async {
    final rows = await getAll();
    for (final item in rows) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> add(Purchase purchase) async {
    if (await getById(purchase.id) != null) {
      throw StateError('خرید قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(purchase);
    await LocalStore.instance.writeList(_storageKey, rows.map((e)=>e.toMap()).toList());
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
