import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/workshop/nut_recommendation_engine.dart';
import 'package:zohal_android_test/core/workshop/nut_candidate.dart';

void main() {
  const engine = NutRecommendationEngine();

  group('NutRecommendationEngine', () {
    test('selects exactly three candidates', () {
      final result = engine.recommend(
        requiredNutWeightGrams: 500,
        candidates: const [
          NutCandidate(
            materialId: 'peanut',
            materialName: 'بادام زمینی',
            stock: 5000,
            minimumStock: 1000,
            purchasePrice: 100,
          ),
          NutCandidate(
            materialId: 'walnut',
            materialName: 'گردو',
            stock: 4000,
            minimumStock: 1000,
            purchasePrice: 150,
          ),
          NutCandidate(
            materialId: 'cashew',
            materialName: 'بادام هندی',
            stock: 3000,
            minimumStock: 500,
            purchasePrice: 200,
          ),
          NutCandidate(
            materialId: 'almond',
            materialName: 'بادام درختی',
            stock: 3000,
            minimumStock: 500,
            purchasePrice: 250,
          ),
        ],
      );

      expect(result, isNotNull);
      expect(result!.allocations.length, 3);
    });

    test('allocations total exactly 100 percent', () {
      final result = engine.recommend(
        requiredNutWeightGrams: 1000,
        candidates: const [
          NutCandidate(
            materialId: 'peanut',
            materialName: 'بادام زمینی',
            stock: 10000,
            minimumStock: 1000,
            purchasePrice: 100,
          ),
          NutCandidate(
            materialId: 'walnut',
            materialName: 'گردو',
            stock: 10000,
            minimumStock: 1000,
            purchasePrice: 150,
          ),
          NutCandidate(
            materialId: 'cashew',
            materialName: 'بادام هندی',
            stock: 10000,
            minimumStock: 1000,
            purchasePrice: 200,
          ),
        ],
      );

      expect(result, isNotNull);

      final total = result!.allocations.fold<double>(
        0,
        (sum, item) => sum + item.percentage,
      );

      expect(total, closeTo(100, 0.0001));
    });

    test('prefers economically stronger candidates', () {
      final result = engine.recommend(
        requiredNutWeightGrams: 1000,
        candidates: const [
          NutCandidate(
            materialId: 'expensive',
            materialName: 'گران',
            stock: 1000,
            minimumStock: 500,
            purchasePrice: 1000,
          ),
          NutCandidate(
            materialId: 'cheap',
            materialName: 'ارزان',
            stock: 10000,
            minimumStock: 500,
            purchasePrice: 100,
          ),
          NutCandidate(
            materialId: 'medium',
            materialName: 'متوسط',
            stock: 8000,
            minimumStock: 500,
            purchasePrice: 200,
          ),
          NutCandidate(
            materialId: 'medium2',
            materialName: 'متوسط دوم',
            stock: 7000,
            minimumStock: 500,
            purchasePrice: 250,
          ),
        ],
      );

      expect(result, isNotNull);

      final ids = result!.allocations
          .map((item) => item.materialId)
          .toSet();

      expect(ids.contains('cheap'), isTrue);
      expect(ids.contains('medium'), isTrue);
      expect(ids.contains('medium2'), isTrue);
      expect(ids.contains('expensive'), isFalse);
    });

    test('returns null when fewer than three materials are available', () {
      final result = engine.recommend(
        requiredNutWeightGrams: 500,
        candidates: const [
          NutCandidate(
            materialId: 'peanut',
            materialName: 'بادام زمینی',
            stock: 5000,
            minimumStock: 1000,
            purchasePrice: 100,
          ),
          NutCandidate(
            materialId: 'walnut',
            materialName: 'گردو',
            stock: 5000,
            minimumStock: 1000,
            purchasePrice: 150,
          ),
        ],
      );

      expect(result, isNull);
    });
  });
}
