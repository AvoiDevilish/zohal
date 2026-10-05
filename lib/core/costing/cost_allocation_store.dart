import '../storage/local_store.dart';
import 'cost_allocation.dart';

class CostAllocationStore {
  CostAllocationStore._();
  static final CostAllocationStore instance = CostAllocationStore._();
  static const String _storageKey = 'cost_allocations';

  Future<List<CostAllocation>> getAllocations({
    String? referenceId,
    String? materialId,
    String? costLayerId,
  }) async {
    final rows = await LocalStore.instance.readList(_storageKey);
    final allocations = rows.map(CostAllocation.fromMap).toList();
    final filtered = allocations.where((allocation) {
      if (referenceId != null && allocation.referenceId != referenceId) return false;
      if (materialId != null && allocation.materialId != materialId) return false;
      if (costLayerId != null && allocation.costLayerId != costLayerId) return false;
      return true;
    }).toList();
    filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return filtered;
  }

  Future<CostAllocation?> getById(String id) async {
    final allocations = await getAllocations();
    for (final allocation in allocations) {
      if (allocation.id == id) return allocation;
    }
    return null;
  }

  Future<void> add(CostAllocation allocation) async => addAll([allocation]);

  Future<void> addAll(List<CostAllocation> newAllocations) async {
    if (newAllocations.isEmpty) return;
    final duplicateIds = <String>{};
    for (final allocation in newAllocations) {
      if (!duplicateIds.add(allocation.id)) {
        throw StateError('Duplicate cost allocation id "${allocation.id}" in batch.');
      }
    }

    final allocations = await getAllocations();
    final existingById = {for (final allocation in allocations) allocation.id: allocation};

    for (final allocation in newAllocations) {
      final existing = existingById[allocation.id];
      if (existing == null) continue;
      if (existing.materialId != allocation.materialId ||
          existing.materialName != allocation.materialName ||
          existing.costLayerId != allocation.costLayerId ||
          (existing.quantity - allocation.quantity).abs() > 0.000001 ||
          (existing.unitCost - allocation.unitCost).abs() > 0.000001 ||
          (existing.totalCost - allocation.totalCost).abs() > 0.000001 ||
          existing.referenceId != allocation.referenceId ||
          existing.sourceLotNumber != allocation.sourceLotNumber ||
          existing.sourceExpiryDate != allocation.sourceExpiryDate) {
        throw StateError(
          'Cost allocation "${allocation.id}" already exists with different data.',
        );
      }
    }

    final missing = newAllocations
        .where((allocation) => !existingById.containsKey(allocation.id))
        .toList();
    if (missing.isEmpty) return;

    allocations.addAll(missing);
    await LocalStore.instance.writeList(
      _storageKey,
      allocations.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async => LocalStore.instance.remove(_storageKey);
}
