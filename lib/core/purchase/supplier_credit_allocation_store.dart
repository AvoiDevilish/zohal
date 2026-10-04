import '../storage/local_store.dart';
import 'supplier_credit_allocation.dart';

class SupplierCreditAllocationStore {
  SupplierCreditAllocationStore._();
  static final SupplierCreditAllocationStore instance =
      SupplierCreditAllocationStore._();
  static const _storageKey = 'supplier_credit_allocations';

  Future<List<SupplierCreditAllocation>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SupplierCreditAllocation.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SupplierCreditAllocation?> getById(String id) async {
    for (final item in await getAll()) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<List<SupplierCreditAllocation>> getByPurchaseId(String purchaseId) async =>
      (await getAll()).where((item) => item.purchaseId == purchaseId).toList();

  Future<List<SupplierCreditAllocation>> getBySupplierId(String supplierId) async =>
      (await getAll()).where((item) => item.supplierId == supplierId).toList();

  Future<void> add(SupplierCreditAllocation allocation) async {
    if (await getById(allocation.id) != null) {
      throw StateError('تخصیص اعتبار تأمین‌کننده قبلاً ثبت شده است.');
    }
    final rows = await getAll();
    rows.add(allocation);
    await LocalStore.instance.writeList(
      _storageKey,
      rows.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() => LocalStore.instance.remove(_storageKey);
}
