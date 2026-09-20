import 'packaging_rule.dart';
import 'production_requirement.dart';
import 'packaging_validator.dart';

class PackagingCalculator {
  const PackagingCalculator();

  List<ProductionRequirement> calculate({
    required int units,
    required List<PackagingRule> rules,
  }) {
    if (units <= 0) {
      throw ArgumentError('تعداد تولید باید بیشتر از صفر باشد.');
    }

    const validator = PackagingValidator();
    validator.validateAll(rules);

    return [
      for (final rule in rules.where((rule) => rule.active))
        ProductionRequirement(
          materialId: rule.materialId,
          materialName: rule.materialName,
          quantity: rule.quantityPerUnit * units,
          unit: rule.unit,
          type: ProductionRequirementType.packaging,
        ),
    ];
  }
}
