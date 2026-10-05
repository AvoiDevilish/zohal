import 'nut_allocation.dart';
import 'packaging_rule.dart';
import 'packaging_validator.dart';
import 'production_requirement.dart';
import 'recipe.dart';

class ProductionCalculation {
  final int units;
  final int unitWeightGrams;
  final double totalWeightGrams;
  final List<ProductionRequirement> requirements;
  final List<ProductionByproduct> byproducts;

  const ProductionCalculation({
    required this.units,
    required this.unitWeightGrams,
    required this.totalWeightGrams,
    required this.requirements,
    this.byproducts = const [],
  });

  ProductionRequirement? findMaterial(String materialId) {
    for (final item in requirements) {
      if (item.materialId == materialId) return item;
    }
    return null;
  }

  ProductionByproduct? findByproduct(String itemId) {
    for (final item in byproducts) {
      if (item.itemId == itemId) return item;
    }
    return null;
  }

  double get totalRequiredWeightGrams {
    return requirements.fold<double>(0, (sum, item) {
      if (item.unit != 'گرم') return sum;
      return sum + item.quantity;
    });
  }
}

class ProductionCalculator {
  const ProductionCalculator();

  ProductionCalculation calculate({
    required Recipe recipe,
    required int units,
    required int unitWeightGrams,
    required String dateMaterialId,
    required String dateMaterialName,
    required List<NutAllocation> nutAllocations,
    required String sesameMaterialId,
    required String sesameMaterialName,
    String? datePitMaterialId,
    String? datePitMaterialName,
    String? flavorMaterialId,
    String? flavorMaterialName,
    List<PackagingRule> packagingRules = const [],
  }) {
    if (units <= 0) {
      throw ArgumentError('تعداد تولید باید بیشتر از صفر باشد.');
    }
    if (unitWeightGrams <= 0) {
      throw ArgumentError('وزن محصول باید بیشتر از صفر باشد.');
    }
    if (!recipe.isValid) {
      throw ArgumentError('فرمول محصول معتبر نیست.');
    }

    _validateNutAllocations(nutAllocations);

    final totalWeight = units.toDouble() * unitWeightGrams.toDouble();
    final flavoringWeight = totalWeight * recipe.flavoringPercentage / 100;
    final baseWeight = totalWeight - flavoringWeight;
    final dateMeatWeight = baseWeight * recipe.datePercentage / 100;
    final totalNutWeight = baseWeight * recipe.nutPercentage / 100;
    final sesameWeight = baseWeight * recipe.sesamePercentage / 100;

    final wholeDateWeight =
        dateMeatWeight * 100 / recipe.dateMeatYieldPercentage;
    final pitWeight = wholeDateWeight - dateMeatWeight;

    final requirements = <ProductionRequirement>[
      ProductionRequirement(
        materialId: dateMaterialId,
        materialName: dateMaterialName,
        quantity: wholeDateWeight,
        unit: 'گرم',
      ),
    ];

    for (final allocation in nutAllocations) {
      final nutWeight = totalNutWeight * allocation.percentage / 100;
      requirements.add(
        ProductionRequirement(
          materialId: allocation.materialId,
          materialName: allocation.materialName,
          quantity: nutWeight,
          unit: 'گرم',
        ),
      );
    }

    requirements.add(
      ProductionRequirement(
        materialId: sesameMaterialId,
        materialName: sesameMaterialName,
        quantity: sesameWeight,
        unit: 'گرم',
      ),
    );

    if (flavorMaterialId != null &&
        flavorMaterialName != null &&
        flavoringWeight > 0) {
      requirements.add(
        ProductionRequirement(
          materialId: flavorMaterialId,
          materialName: flavorMaterialName,
          quantity: flavoringWeight,
          unit: 'گرم',
        ),
      );
    }

    const packagingValidator = PackagingValidator();
    packagingValidator.validateAll(packagingRules);

    for (final rule in packagingRules.where((rule) => rule.active)) {
      requirements.add(
        ProductionRequirement(
          materialId: rule.materialId,
          materialName: rule.materialName,
          quantity: rule.quantityPerUnit * units,
          unit: rule.unit,
          type: ProductionRequirementType.packaging,
        ),
      );
    }

    _validateUniqueRequirements(requirements);

    final byproducts = <ProductionByproduct>[];
    if (datePitMaterialId != null &&
        datePitMaterialName != null &&
        pitWeight > 0) {
      byproducts.add(
        ProductionByproduct(
          itemId: datePitMaterialId,
          itemName: datePitMaterialName,
          itemType: 'rawMaterial',
          quantity: pitWeight,
          unit: 'گرم',
        ),
      );
    }

    return ProductionCalculation(
      units: units,
      unitWeightGrams: unitWeightGrams,
      totalWeightGrams: totalWeight,
      requirements: List.unmodifiable(requirements),
      byproducts: List.unmodifiable(byproducts),
    );
  }

  void _validateUniqueRequirements(List<ProductionRequirement> requirements) {
    final seenMaterialIds = <String>{};

    for (final requirement in requirements) {
      if (!seenMaterialIds.add(requirement.materialId)) {
        throw ArgumentError(
          'یک ماده نمی‌تواند بیش از یک بار در نیازمندی‌های یک تولید تکرار شود: '
          '${requirement.materialId}',
        );
      }
    }
  }

  void _validateNutAllocations(List<NutAllocation> allocations) {
    if (allocations.length != 3) {
      throw ArgumentError('برای هر محصول باید دقیقاً سه نوع مغز انتخاب شود.');
    }
    final ids = allocations.map((item) => item.materialId).toSet();
    if (ids.length != 3) {
      throw ArgumentError('سه نوع مغز باید متفاوت باشند.');
    }
    if (allocations.any((item) => item.percentage <= 0)) {
      throw ArgumentError('درصد هر مغز باید بیشتر از صفر باشد.');
    }
    final total = allocations.fold<double>(
      0,
      (sum, item) => sum + item.percentage,
    );
    if ((total - 100).abs() > 0.0001) {
      throw ArgumentError('مجموع درصد مغزها باید دقیقاً ۱۰۰٪ باشد.');
    }
  }
}
