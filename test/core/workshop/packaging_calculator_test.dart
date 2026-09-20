import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/workshop/packaging_calculator.dart';
import '../../../lib/core/workshop/packaging_rule.dart';

void main() {
  const calculator = PackagingCalculator();

  group('PackagingCalculator', () {
    test('calculates one packaging item for production quantity', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'container-100g',
          materialName: 'ظرف ۱۰۰ گرمی',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
      ];

      final result = calculator.calculate(units: 20, rules: rules);

      expect(result, hasLength(1));
      expect(result.first.materialId, 'container-100g');
      expect(result.first.quantity, 20);
      expect(result.first.unit, 'عدد');
    });

    test('calculates multiple packaging rules', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'container-100g',
          materialName: 'ظرف ۱۰۰ گرمی',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'label',
          materialName: 'لیبل',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
      ];

      final result = calculator.calculate(units: 20, rules: rules);

      expect(result, hasLength(2));
      expect(result[0].quantity, 20);
      expect(result[1].quantity, 20);
    });

    test('supports fractional quantity per product', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'special-material',
          materialName: 'قلم بسته‌بندی',
          quantityPerUnit: 0.5,
          unit: 'عدد',
        ),
      ];

      final result = calculator.calculate(units: 20, rules: rules);

      expect(result.first.quantity, 10);
    });

    test('ignores inactive packaging rules', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'container-100g',
          materialName: 'ظرف ۱۰۰ گرمی',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'old-label',
          materialName: 'لیبل قدیمی',
          quantityPerUnit: 1,
          unit: 'عدد',
          active: false,
        ),
      ];

      final result = calculator.calculate(units: 20, rules: rules);

      expect(result, hasLength(1));
      expect(result.first.materialId, 'container-100g');
    });

    test('rejects zero production quantity', () {
      expect(
        () => calculator.calculate(units: 0, rules: const []),
        throwsArgumentError,
      );
    });

    test('rejects negative production quantity', () {
      expect(
        () => calculator.calculate(units: -1, rules: const []),
        throwsArgumentError,
      );
    });

    test('rejects zero quantity per unit', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'container-100g',
          materialName: 'ظرف ۱۰۰ گرمی',
          quantityPerUnit: 0,
          unit: 'عدد',
        ),
      ];

      expect(
        () => calculator.calculate(units: 20, rules: rules),
        throwsArgumentError,
      );
    });

    test('rejects empty material id', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: '',
          materialName: 'ظرف ۱۰۰ گرمی',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
      ];

      expect(
        () => calculator.calculate(units: 20, rules: rules),
        throwsArgumentError,
      );
    });

    test('rejects duplicate packaging material rules', () {
      final rules = [
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'label',
          materialName: 'لیبل',
          quantityPerUnit: 1,
          unit: 'عدد',
        ),
        const PackagingRule(
          productVariantId: 'energy-bar-100g-ginger',
          materialId: 'label',
          materialName: 'لیبل',
          quantityPerUnit: 2,
          unit: 'عدد',
        ),
      ];

      expect(
        () => calculator.calculate(units: 20, rules: rules),
        throwsArgumentError,
      );
    });

    test('serializes and restores packaging rule', () {
      const original = PackagingRule(
        productVariantId: 'energy-bar-100g-ginger',
        materialId: 'container-100g',
        materialName: 'ظرف ۱۰۰ گرمی',
        quantityPerUnit: 1,
        unit: 'عدد',
      );

      final restored = PackagingRule.fromMap(original.toMap());

      expect(restored.productVariantId, original.productVariantId);
      expect(restored.materialId, original.materialId);
      expect(restored.materialName, original.materialName);
      expect(restored.quantityPerUnit, original.quantityPerUnit);
      expect(restored.unit, original.unit);
      expect(restored.active, original.active);
    });
  });
}
