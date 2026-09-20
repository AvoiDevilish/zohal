import '../storage/local_store.dart';
import 'cost_allocation.dart';

class CostAllocationStore {
  CostAllocationStore._();

  static final CostAllocationStore instance = CostAllocationStore._();

  static const String _storageKey = 'cost_allocations';

  Future<List<CostAllocation>> getAllocations({
    String? referenceId,
    String? materialId,
  }) async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final allocations = rows.map(CostAllocation.fromMap).toList();

    final filtered = allocations.where((allocation) {
      if (referenceId != null && allocation.referenceId != referenceId) {
        return false;
      }

      if (materialId != null && allocation.materialId != materialId) {
        return false;
      }

      return true;
    }).toList();

    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return filtered;
  }

  Future<CostAllocation?> getById(String id) async {
    final allocations = await getAllocations();

    for (final allocation in allocations) {
      if (allocation.id == id) {
        return allocation;
      }
    }

    return null;
  }

  Future<void> add(CostAllocation allocation) async {
    final allocations = await getAllocations();

    if (allocations.any((item) => item.id == allocation.id)) {
      throw StateError(
        'Cost allocation with id "${allocation.id}" already exists.',
      );
    }

    allocations.add(allocation);

    await LocalStore.instance.writeList(
      _storageKey,
      allocations.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
