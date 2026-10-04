import '../storage/local_store.dart';
import 'sales_receipt.dart';

class SalesReceiptStore {
  SalesReceiptStore._();

  static final SalesReceiptStore instance = SalesReceiptStore._();
  static const _storageKey = 'sales_receipts';

  Future<List<SalesReceipt>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesReceipt.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SalesReceipt?> getById(String id) async {
    for (final receipt in await getAll()) {
      if (receipt.id == id) return receipt;
    }
    return null;
  }

  Future<List<SalesReceipt>> getByOrderId(String orderId) async {
    return (await getAll()).where((receipt) => receipt.orderId == orderId).toList();
  }

  Future<List<SalesReceipt>> getByPayerId(String payerId) async {
    return (await getAll()).where((receipt) => receipt.payerId == payerId).toList();
  }

  Future<void> add(SalesReceipt receipt) async {
    if (await getById(receipt.id) != null) {
      throw StateError('دریافت قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(receipt);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
