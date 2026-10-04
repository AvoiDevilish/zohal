import '../storage/local_store.dart';
import 'supplier_credit_settlement.dart';

class SupplierCreditSettlementStore {
  SupplierCreditSettlementStore._();
  static final SupplierCreditSettlementStore instance =
      SupplierCreditSettlementStore._();
  static const _storageKey = 'supplier_credit_settlements';

  Future<List<SupplierCreditSettlement>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SupplierCreditSettlement.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SupplierCreditSettlement?> getById(String id) async {
    for (final item in await getAll()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<List<SupplierCreditSettlement>> getBySupplierId(String supplierId) async =>
      (await getAll()).where((item) => item.supplierId == supplierId).toList();

  Future<void> add(SupplierCreditSettlement settlement) async {
    if (await getById(settlement.id) != null) {
      throw StateError('تسویه اعتبار تأمین‌کننده قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(settlement);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
