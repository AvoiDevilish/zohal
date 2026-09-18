import 'production_requirement.dart';
import 'recipe.dart';

class ProductionCalculation {
  final int units;
  final int unitWeightGrams;
  final double totalWeightGrams;
  final List<ProductionRequirement> requirements;

  const ProductionCalculation({
    required this.units,
    required this.unitWeightGrams,
    required this.totalWeightGrams,
    required this.requirements,
  });

  ProductionRequirement? findMaterial(String materialId) {
    for (final item in requirements) {
      if (item.materialId == materialId) {
        return item;
      }
    }
    return null;
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
    required String nutMaterialId,
    required String nutMaterialName,
    required String sesameMaterialId,
    required String sesameMaterialName,
    String? flavorMaterialId,
    String? flavorMaterialName,
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

    final double totalWeight = units.toDouble() * unitWeightGrams.toDouble();

    // Flavoring is part of the final product weight.
    final flavoringWeight =
        totalWeight * recipe.flavoringPercentage / 100;

    // The remaining mass preserves the exact 70/27/3 ratio.
    final baseWeight = totalWeight - flavoringWeight;

    final dateWeight =
        baseWeight * recipe.datePercentage / 100;

    final nutWeight =
        baseWeight * recipe.nutPercentage / 100;

    final sesameWeight =
        baseWeight * recipe.sesamePercentage / 100;

    final requirements = <ProductionRequirement>[
      ProductionRequirement(
        materialId: dateMaterialId,
        materialName: dateMaterialName,
        quantity: dateWeight,
        unit: 'گرم',
      ),
      ProductionRequirement(
        materialId: nutMaterialId,
        materialName: nutMaterialName,
        quantity: nutWeight,
        unit: 'گرم',
      ),
      ProductionRequirement(
        materialId: sesameMaterialId,
        materialName: sesameMaterialName,
        quantity: sesameWeight,
        unit: 'گرم',
      ),
    ];

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

    return ProductionCalculation(
      units: units,
      unitWeightGrams: unitWeightGrams,
      totalWeightGrams: totalWeight,
      requirements: requirements,
    );
  }
}
