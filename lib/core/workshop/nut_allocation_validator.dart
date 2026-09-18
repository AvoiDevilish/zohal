import 'nut_allocation.dart';

class NutAllocationValidator {
  const NutAllocationValidator();

  bool isValid(List<NutAllocation> allocations) {
    if (allocations.length != 3) {
      return false;
    }

    final ids = allocations.map((item) => item.materialId).toSet();

    if (ids.length != 3) {
      return false;
    }

    if (allocations.any((item) => item.percentage <= 0)) {
      return false;
    }

    final total = allocations.fold<double>(
      0,
      (sum, item) => sum + item.percentage,
    );

    return (total - 100).abs() < 0.0001;
  }
}
