import '../storage/local_store.dart';
import 'sales_credit_allocation.dart';

class SalesCreditAllocationStore {
  SalesCreditAllocationStore._();

  static final SalesCreditAllocationStore instance = SalesCreditAllocationStore._();
  static const _storageKey = 'sales_credit_allocations';

  Future<List<SalesCreditAllocation>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(SalesCreditAllocation.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<SalesCreditAllocation?> getById(String id) async {
    for (final allocation in await getAll()) {
      if (allocation.id == id) return allocation;
    }
    return null;
  }

  Future<List<SalesCreditAllocation>> getByOrderId(String orderId) async {
    return (await getAll()).where((item) => item.orderId == orderId).toList();
  }

  Future<List<SalesCreditAllocation>> getByCustomerId(String customerId) async {
    return (await getAll()).where((item) => item.customerId == customerId).toList();
  }

  Future<void> add(SalesCreditAllocation allocation) async {
    if (allocation.amount <= 0) {
      throw ArgumentError('مبلغ تخصیص اعتبار باید بیشتر از صفر باشد.');
    }
    if (await getById(allocation.id) != null) {
      throw StateError('تخصیص اعتبار قبلاً ثبت شده است.');
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
