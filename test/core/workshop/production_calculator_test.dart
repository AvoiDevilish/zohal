import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/recipe.dart';

void main() {
  group('ProductionCalculator', () {
    const calculator = ProductionCalculator();

    const recipe = Recipe(
      id: 'recipe-100-ginger',
      productVariantId: 'energy-100-ginger',
      name: 'انرژی بار ۱۰۰ گرمی زنجبیلی',
      datePercentage: 70,
      nutPercentage: 27,
      sesamePercentage: 3,
      flavoringPercentage: 0.5,
    );

    test('calculates 20 x 100g production correctly', () {
      final result = calculator.calculate(
        recipe: recipe,
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutMaterialId: 'nuts',
        nutMaterialName: 'مغزها',
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        flavorMaterialId: 'ginger',
        flavorMaterialName: 'پودر زنجبیل',
      );

      expect(result.totalWeightGrams, 2000);

      final date = result.findMaterial('date');
      final nuts = result.findMaterial('nuts');
      final sesame = result.findMaterial('sesame');
      final ginger = result.findMaterial('ginger');

      expect(date?.quantity, closeTo(1393, 0.0001));
      expect(nuts?.quantity, closeTo(537.3, 0.0001));
      expect(sesame?.quantity, closeTo(59.7, 0.0001));
      expect(ginger?.quantity, closeTo(10, 0.0001));

      final total = result.requirements.fold<double>(
        0,
        (sum, item) => sum + item.quantity,
      );

      expect(total, closeTo(2000, 0.0001));
    });

    test('calculates 2 x 500g production', () {
      final result = calculator.calculate(
        recipe: recipe,
        units: 2,
        unitWeightGrams: 500,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutMaterialId: 'nuts',
        nutMaterialName: 'مغزها',
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
      );

      expect(result.totalWeightGrams, 1000);

      expect(
        result.findMaterial('date')?.quantity,
        closeTo(696.5, 0.0001),
      );

      expect(
        result.findMaterial('nuts')?.quantity,
        closeTo(268.65, 0.0001),
      );

      expect(
        result.findMaterial('sesame')?.quantity,
        closeTo(29.85, 0.0001),
      );
    });

    test('rejects invalid flavoring percentage', () {
      const invalidRecipe = Recipe(
        id: 'invalid',
        productVariantId: 'invalid',
        name: 'فرمول نامعتبر',
        flavoringPercentage: 1.2,
      );

      expect(
        () => calculator.calculate(
          recipe: invalidRecipe,
          units: 1,
          unitWeightGrams: 100,
          dateMaterialId: 'date',
          dateMaterialName: 'خرما',
          nutMaterialId: 'nuts',
          nutMaterialName: 'مغزها',
          sesameMaterialId: 'sesame',
          sesameMaterialName: 'کنجد',
        ),
        throwsArgumentError,
      );
    });
  });
}
