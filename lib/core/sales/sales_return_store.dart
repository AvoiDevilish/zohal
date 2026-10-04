import '../storage/local_store.dart';
import 'sales_return.dart';

class SalesReturnStore {
  SalesReturnStore._();

  static final SalesReturnStore instance = SalesReturnStore._();
  static const String _storageKey = 'sales_returns';

  Future<List<SalesReturn>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesReturn.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<SalesReturn>> getByDeliveryId(String deliveryId) async {
    final rows = await getAll();
    return rows.where((item) => item.deliveryId == deliveryId).toList();
  }

  Future<SalesReturn?> getById(String id) async {
    final rows = await getAll();
    for (final item in rows) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> add(SalesReturn salesReturn) async {
    if (await getById(salesReturn.id) != null) {
      throw StateError('برگشت فروش قبلاً ثبت شده است.');
    }

    final rows = await getAll();
    rows.add(salesReturn);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
