import '../storage/local_store.dart';
import 'sales_delivery.dart';

class SalesDeliveryStore {
  SalesDeliveryStore._();

  static final SalesDeliveryStore instance = SalesDeliveryStore._();
  static const String _storageKey = 'sales_deliveries';

  Future<List<SalesDelivery>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesDelivery.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<SalesDelivery>> getByOrderId(String orderId) async {
    final rows = await getAll();
    return rows.where((item) => item.orderId == orderId).toList();
  }

  Future<SalesDelivery?> getById(String id) async {
    final rows = await getAll();
    for (final delivery in rows) {
      if (delivery.id == id) return delivery;
    }
    return null;
  }

  Future<void> add(SalesDelivery delivery) async {
    if (await getById(delivery.id) != null) {
      throw StateError('تحویل قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(delivery);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
