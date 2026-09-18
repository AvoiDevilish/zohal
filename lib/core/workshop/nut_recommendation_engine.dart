import 'nut_allocation.dart';
import 'nut_candidate.dart';
import 'nut_recommendation.dart';

class NutRecommendationEngine {
  const NutRecommendationEngine();

  NutRecommendation? recommend({
    required List<NutCandidate> candidates,
    required double requiredNutWeightGrams,
  }) {
    if (requiredNutWeightGrams <= 0) {
      return null;
    }

    final available = candidates
        .where((candidate) => candidate.stock > 0)
        .toList();

    if (available.length < 3) {
      return null;
    }

    final prices = available
        .map((candidate) => candidate.purchasePrice)
        .where((price) => price > 0)
        .toList();

    final minPrice = prices.isEmpty
        ? 0.0
        : prices.reduce((a, b) => a < b ? a : b);

    final maxPrice = prices.isEmpty
        ? 0.0
        : prices.reduce((a, b) => a > b ? a : b);

    final scored = available
        .map(
          (candidate) => _scoreCandidate(
            candidate,
            minPrice,
            maxPrice,
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final selected = scored.take(3).toList();

    if (selected.length != 3) {
      return null;
    }

    final allocations = _buildAllocations(selected);

    final score = selected.fold<double>(
          0,
          (sum, item) => sum + item.score,
        ) /
        selected.length;

    return NutRecommendation(
      allocations: allocations,
      score: score.clamp(0, 100).toDouble(),
      reason: _buildReason(selected),
    );
  }

  _ScoredCandidate _scoreCandidate(
    NutCandidate candidate,
    double minPrice,
    double maxPrice,
  ) {
    final priceScore = _priceScore(
      candidate.purchasePrice,
      minPrice,
      maxPrice,
    );

    final stockScore = _stockScore(candidate);

    final totalScore =
        (priceScore * 0.55) +
        (stockScore * 0.45);

    return _ScoredCandidate(
      candidate: candidate,
      score: totalScore,
    );
  }

  double _priceScore(
    double price,
    double minPrice,
    double maxPrice,
  ) {
    if (price <= 0) {
      return 50;
    }

    if (maxPrice <= minPrice) {
      return 100;
    }

    final normalized =
        (price - minPrice) / (maxPrice - minPrice);

    return 100 - (normalized * 100);
  }

  double _stockScore(NutCandidate candidate) {
    if (candidate.stock <= 0) {
      return 0;
    }

    if (candidate.minimumStock <= 0) {
      return 100;
    }

    final coverage = candidate.stockCoverageRatio;

    if (coverage <= 1) {
      return 20;
    }

    if (coverage >= 3) {
      return 100;
    }

    return 20 + ((coverage - 1) / 2) * 80;
  }

  List<NutAllocation> _buildAllocations(
    List<_ScoredCandidate> selected,
  ) {
    final scores = selected.map(
      (item) => item.score <= 0 ? 1.0 : item.score,
    );

    final totalScore = scores.fold<double>(
      0,
      (sum, score) => sum + score,
    );

    return List.unmodifiable(
      List.generate(selected.length, (index) {
        final item = selected[index];

        final percentage =
            scores.elementAt(index) / totalScore * 100;

        return NutAllocation(
          materialId: item.candidate.materialId,
          materialName: item.candidate.materialName,
          percentage: percentage,
        );
      }),
    );
  }

  String _buildReason(
    List<_ScoredCandidate> selected,
  ) {
    final names = selected
        .map((item) => item.candidate.materialName)
        .join('، ');

    return 'ترکیب بر اساس قیمت خرید و وضعیت موجودی پیشنهاد شده است: $names';
  }
}

class _ScoredCandidate {
  final NutCandidate candidate;
  final double score;

  const _ScoredCandidate({
    required this.candidate,
    required this.score,
  });
}
