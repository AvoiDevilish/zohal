import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/packaging_rule.dart';
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

    const allocations = [
      NutAllocation(
        materialId: 'peanut',
        materialName: 'بادام زمینی',
        percentage: 45,
      ),
      NutAllocation(materialId: 'walnut', materialName: 'گردو', percentage: 30),
      NutAllocation(
        materialId: 'cashew',
        materialName: 'بادام هندی',
        percentage: 25,
      ),
    ];

    test('calculates 20 x 100g with three nuts', () {
      final result = calculator.calculate(
        recipe: recipe,
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutAllocations: allocations,
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        datePitMaterialId: 'raw_date_pit',
        datePitMaterialName: 'هسته خرما',
        flavorMaterialId: 'ginger',
        flavorMaterialName: 'پودر زنجبیل',
      );

      expect(result.totalWeightGrams, 2000);

      expect(result.findMaterial('date')?.quantity, closeTo(1547.7777778, 0.0001));

      expect(result.findByproduct('raw_date_pit')?.quantity, closeTo(154.7777778, 0.0001));

      expect(result.findMaterial('peanut')?.quantity, closeTo(241.785, 0.0001));

      expect(result.findMaterial('walnut')?.quantity, closeTo(161.19, 0.0001));

      expect(result.findMaterial('cashew')?.quantity, closeTo(134.325, 0.0001));

      expect(result.findMaterial('sesame')?.quantity, closeTo(59.7, 0.0001));

      expect(result.findMaterial('ginger')?.quantity, closeTo(10, 0.0001));

      expect(result.totalRequiredWeightGrams, closeTo(2154.7777778, 0.0001));
    });

    test('includes packaging requirements in production calculation', () {
      final result = calculator.calculate(
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
        packagingRules: const [
          PackagingRule(
            productVariantId: 'energy-100-ginger',
            materialId: 'container-100g',
            materialName: 'ظرف ۱۰۰ گرمی',
            quantityPerUnit: 1,
            unit: 'عدد',
          ),
          PackagingRule(
            productVariantId: 'energy-100-ginger',
            materialId: 'label',
            materialName: 'لیبل',
            quantityPerUnit: 1,
            unit: 'عدد',
          ),
        ],
      );

      expect(result.findMaterial('container-100g')?.quantity, 20);

      expect(result.findMaterial('label')?.quantity, 20);

      expect(result.totalRequiredWeightGrams, closeTo(2000, 0.0001));
    });

    test('does not include inactive packaging rules', () {
      final result = calculator.calculate(
        recipe: recipe,
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutAllocations: allocations,
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        packagingRules: const [
          PackagingRule(
            productVariantId: 'energy-100-ginger',
            materialId: 'container-100g',
            materialName: 'ظرف ۱۰۰ گرمی',
            quantityPerUnit: 1,
            unit: 'عدد',
          ),
          PackagingRule(
            productVariantId: 'energy-100-ginger',
            materialId: 'old-label',
            materialName: 'لیبل قدیمی',
            quantityPerUnit: 1,
            unit: 'عدد',
            active: false,
          ),
        ],
      );

      expect(result.findMaterial('container-100g')?.quantity, 20);

      expect(result.findMaterial('old-label'), isNull);
    });

    test('rejects fewer than three nuts', () {
      expect(
        () => calculator.calculate(
          recipe: recipe,
          units: 1,
          unitWeightGrams: 100,
          dateMaterialId: 'date',
          dateMaterialName: 'خرما',
          nutAllocations: const [
            NutAllocation(
              materialId: 'peanut',
              materialName: 'بادام زمینی',
              percentage: 60,
            ),
            NutAllocation(
              materialId: 'walnut',
              materialName: 'گردو',
              percentage: 40,
            ),
          ],
          sesameMaterialId: 'sesame',
          sesameMaterialName: 'کنجد',
        ),
        throwsArgumentError,
      );
    });

    test('rejects duplicate nuts', () {
      expect(
        () => calculator.calculate(
          recipe: recipe,
          units: 1,
          unitWeightGrams: 100,
          dateMaterialId: 'date',
          dateMaterialName: 'خرما',
          nutAllocations: const [
            NutAllocation(
              materialId: 'peanut',
              materialName: 'بادام زمینی',
              percentage: 40,
            ),
            NutAllocation(
              materialId: 'peanut',
              materialName: 'بادام زمینی',
              percentage: 35,
            ),
            NutAllocation(
              materialId: 'cashew',
              materialName: 'بادام هندی',
              percentage: 25,
            ),
          ],
          sesameMaterialId: 'sesame',
          sesameMaterialName: 'کنجد',
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid nut percentages', () {
      expect(
        () => calculator.calculate(
          recipe: recipe,
          units: 1,
          unitWeightGrams: 100,
          dateMaterialId: 'date',
          dateMaterialName: 'خرما',
          nutAllocations: const [
            NutAllocation(
              materialId: 'peanut',
              materialName: 'بادام زمینی',
              percentage: 50,
            ),
            NutAllocation(
              materialId: 'walnut',
              materialName: 'گردو',
              percentage: 30,
            ),
            NutAllocation(
              materialId: 'cashew',
              materialName: 'بادام هندی',
              percentage: 10,
            ),
          ],
          sesameMaterialId: 'sesame',
          sesameMaterialName: 'کنجد',
        ),
        throwsArgumentError,
      );
    });
  });
}
