import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_stock_check.dart';
import 'package:zohal_android_test/core/workshop/recipe.dart';

void main() {
  group('ProductionStockChecker', () {
    const calculator = ProductionCalculator();
    const checker = ProductionStockChecker();

    const recipe = Recipe(
      id: 'recipe-100-ginger',
      productVariantId: 'energy-100-ginger',
      name: 'انرژی بار ۱۰۰ گرمی زنجبیلی',
      datePercentage: 70,
      nutPercentage: 27,
      sesamePercentage: 3,
      flavoringPercentage: 0.5,
    );

    const allocations = [
      NutAllocation(
        materialId: 'peanut',
        materialName: 'بادام زمینی',
        percentage: 45,
      ),
      NutAllocation(
        materialId: 'walnut',
        materialName: 'گردو',
        percentage: 30,
      ),
      NutAllocation(
        materialId: 'cashew',
        materialName: 'بادام هندی',
        percentage: 25,
      ),
    ];

    ProductionCalculation buildCalculation() {
      return calculator.calculate(
        recipe: recipe,
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutAllocations: allocations,
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        flavorMaterialId: 'ginger',
        flavorMaterialName: 'پودر زنجبیل',
      );
    }

    test('allows production when all materials are sufficient', () {
      final result = checker.check(
        calculation: buildCalculation(),
        stockByMaterialId: const {
          'date': 5000,
          'peanut': 500,
          'walnut': 500,
          'cashew': 500,
          'sesame': 500,
          'ginger': 100,
        },
      );

      expect(result.canProduce, isTrue);
      expect(result.shortages, isEmpty);
    });

    test('blocks production when a material is insufficient', () {
      final result = checker.check(
        calculation: buildCalculation(),
        stockByMaterialId: const {
          'date': 5000,
          'peanut': 100,
          'walnut': 500,
          'cashew': 500,
          'sesame': 500,
          'ginger': 100,
        },
      );

      expect(result.canProduce, isFalse);
      expect(result.shortages.length, 1);

      final shortage = result.shortages.first;

      expect(shortage.materialId, 'peanut');
      expect(shortage.requiredQuantity, closeTo(241.785, 0.0001));
      expect(shortage.availableQuantity, 100);
      expect(shortage.shortageQuantity, closeTo(141.785, 0.0001));
    });

    test('treats missing material stock as zero', () {
      final result = checker.check(
        calculation: buildCalculation(),
        stockByMaterialId: const {
          'date': 5000,
          'peanut': 500,
          'walnut': 500,
          'cashew': 500,
          'sesame': 500,
        },
      );

      expect(result.canProduce, isFalse);

      final shortage = result.shortages.firstWhere(
        (item) => item.materialId == 'ginger',
      );

      expect(shortage.availableQuantity, 0);
      expect(shortage.shortageQuantity, 10);
    });

    test('calculates multiple shortages independently', () {
      final result = checker.check(
        calculation: buildCalculation(),
        stockByMaterialId: const {
          'date': 1000,
          'peanut': 100,
          'walnut': 100,
          'cashew': 100,
          'sesame': 20,
          'ginger': 5,
        },
      );

      expect(result.canProduce, isFalse);
      expect(result.shortages.length, 6);

      expect(
        result.totalShortageQuantity,
        closeTo(
          (1547.7777777777778 - 1000) +
              (241.785 - 100) +
              (161.19 - 100) +
              (134.325 - 100) +
              (59.7 - 20) +
              (10 - 5),
          0.0001,
        ),
      );
    });
  });
}
