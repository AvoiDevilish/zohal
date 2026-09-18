import 'nut_allocation.dart';

class NutRecommendation {
  final List<NutAllocation> allocations;

  /// 0..100
  final double score;

  final String reason;

  const NutRecommendation({
    required this.allocations,
    required this.score,
    required this.reason,
  });
}
