import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/products/product_catalog.dart';
import 'package:zohal_android_test/core/products/product_variant.dart';
import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/nut_allocation_validator.dart';

void main() {
  group('ProductCatalog', () {
    test('creates exactly 9 product variants', () {
      final products = ProductCatalog.buildDefaultVariants();

      expect(products.length, 9);
      expect(
        products.map((item) => item.id).toSet().length,
        9,
      );
    });

    test('contains all weights and flavors', () {
      final products = ProductCatalog.buildDefaultVariants();

      expect(
        products.where((item) => item.weightGrams == 100).length,
        3,
      );

      expect(
        products.where((item) => item.weightGrams == 500).length,
        3,
      );

      expect(
        products.where((item) => item.weightGrams == 1000).length,
        3,
      );

      expect(
        products.where(
          (item) => item.flavor == ProductFlavor.ginger,
        ).length,
        3,
      );
    });

    test('finds product by stable id', () {
      final products = ProductCatalog.buildDefaultVariants();
      final target = products.first;

      final result = ProductCatalog.findById(target.id);

      expect(result.id, target.id);
      expect(result.weightGrams, target.weightGrams);
      expect(result.flavor, target.flavor);
    });
  });

  group('NutAllocationValidator', () {
    const validator = NutAllocationValidator();

    test('accepts exactly three unique nuts totaling 100%', () {
      const allocations = [
        NutAllocation(
          materialId: 'peanut',
          materialName: 'بادام زمینی',
          percentage: 40,
        ),
        NutAllocation(
          materialId: 'walnut',
          materialName: 'گردو',
          percentage: 35,
        ),
        NutAllocation(
          materialId: 'cashew',
          materialName: 'بادام هندی',
          percentage: 25,
        ),
      ];

      expect(validator.isValid(allocations), isTrue);
    });

    test('rejects fewer than three nuts', () {
      const allocations = [
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
      ];

      expect(validator.isValid(allocations), isFalse);
    });

    test('rejects duplicate nuts', () {
      const allocations = [
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
      ];

      expect(validator.isValid(allocations), isFalse);
    });

    test('rejects allocations that do not total 100%', () {
      const allocations = [
        NutAllocation(
          materialId: 'peanut',
          materialName: 'بادام زمینی',
          percentage: 40,
        ),
        NutAllocation(
          materialId: 'walnut',
          materialName: 'گردو',
          percentage: 30,
        ),
        NutAllocation(
          materialId: 'cashew',
          materialName: 'بادام هندی',
          percentage: 20,
        ),
      ];

      expect(validator.isValid(allocations), isFalse);
    });
  });
}
