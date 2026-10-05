import '../workshop/production_calculator.dart';
import '../workshop/production_requirement.dart';
import 'cost_consumption_service.dart';
import 'costing_method.dart';
import 'production_cost.dart';

class ProductionCostService {
  final CostConsumptionService costConsumptionService;

  const ProductionCostService({required this.costConsumptionService});

  /// Validates every material requirement without persisting costing state.\n  /// The production workflow runs this before inventory consumption.\n  Future<void> validate({\n    required String productionId,\n    required ProductionCalculation calculation,\n    CostingMethod method = CostingMethod.fifo,\n    bool allowExpiredLots = false,\n    DateTime? now,\n  }) async {\n    for (final requirement in calculation.requirements) {\n      await costConsumptionService.preview(\n        referenceId: '\$productionId-\${requirement.materialId}',\n        materialId: requirement.materialId,\n        quantity: requirement.quantity,\n        method: method,\n        allowExpiredLots: allowExpiredLots,\n        now: now,\n      );\n    }\n  }\n\n  Future<ProductionCost> calculate({
    required String productionId,
    required ProductionCalculation calculation,
    CostingMethod method = CostingMethod.fifo,
    bool allowExpiredLots = false,
    DateTime? now,
  }) async {
    var materialCost = 0.0;
    var packagingCost = 0.0;
    var consumableCost = 0.0;

    for (final requirement in calculation.requirements) {
      final result = await costConsumptionService.consume(
        referenceId: '$productionId-${requirement.materialId}',
        materialId: requirement.materialId,
        quantity: requirement.quantity,
        method: method,
        allowExpiredLots: allowExpiredLots,
        now: now,
      );

      switch (requirement.type) {
        case ProductionRequirementType.rawMaterial:
          materialCost += result.totalCost;
          break;

        case ProductionRequirementType.packaging:
          packagingCost += result.totalCost;
          break;

        case ProductionRequirementType.consumable:
          consumableCost += result.totalCost;
          break;
      }
    }

    return ProductionCost(
      productionId: productionId,
      materialCost: materialCost,
      packagingCost: packagingCost,
      consumableCost: consumableCost,
      totalCost: materialCost + packagingCost + consumableCost,
      outputQuantity: calculation.units,
      createdAt: DateTime.now(),
    );
  }
}
