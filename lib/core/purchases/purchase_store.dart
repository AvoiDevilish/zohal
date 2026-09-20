import '../storage/local_store.dart';
import 'purchase.dart';
import 'purchase_validator.dart';

class PurchaseStore {
  PurchaseStore._();

  static final PurchaseStore instance = PurchaseStore._();

  static const String _storageKey = 'purchases';

  Future<List<Purchase>> getPurchases() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    return rows.map(Purchase.fromMap).toList()
      ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
  }

  Future<Purchase?> getById(String id) async {
    final purchases = await getPurchases();

    for (final purchase in purchases) {
      if (purchase.id == id) {
        return purchase;
      }
    }

    return null;
  }

  Future<void> add(Purchase purchase) async {
    const validator = PurchaseValidator();
    validator.validate(purchase);

    final purchases = await getPurchases();
    purchases.add(purchase);

    await LocalStore.instance.writeList(
      _storageKey,
      purchases.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
