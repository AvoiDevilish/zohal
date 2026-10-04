import 'storage/local_store.dart';
import 'purchase.dart';

class PurchaseReturnStore {
  PurchaseReturnStore._();
  static final PurchaseReturnStore instance = PurchaseReturnStore._();
  static const _storageKey = 'purchase_returns';

  Future<List<PurchaseReturn>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(PurchaseReturn.fromMap).toList()
      ..sort((a,b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<PurchaseReturn>> getByPurchaseId(String purchaseId) async {
    return (await getAll()).where((item) => item.purchaseId == purchaseId).toList();
  }

  Future<PurchaseReturn?> getById(String id) async {
    for (final item in await getAll()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> add(PurchaseReturn item) async {
    if (await getById(item.id) != null) {
      throw StateError('برگشت خرید قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(item);
    await LocalStore.instance.writeList(_storageKey, rows.map((e)=>e.toMap()).toList());
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
