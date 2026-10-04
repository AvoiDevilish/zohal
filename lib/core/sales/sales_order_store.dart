import '../storage/local_store.dart';
import 'sales_order.dart';

class SalesOrderStore {
  SalesOrderStore._();

  static final SalesOrderStore instance = SalesOrderStore._();

  static const String _storageKey = 'sales_orders';

  Future<List<SalesOrder>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesOrder.fromMap).toList()
      ..sort((a, b) => b.orderDate.compareTo(a.orderDate));
  }

  Future<void> create(SalesOrder order) async {
    final orders = await getAll();
    if (orders.any((item) => item.id == order.id)) {
      throw StateError('شماره سفارش تکراری است.');
    }

    orders.add(order);
    await LocalStore.instance.writeList(
      _storageKey,
      orders.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> update(SalesOrder order) async {
    final orders = await getAll();
    final index = orders.indexWhere((item) => item.id == order.id);
    if (index == -1) {
      throw StateError('سفارش پیدا نشد.');
    }

    orders[index] = order;
    await LocalStore.instance.writeList(
      _storageKey,
      orders.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
