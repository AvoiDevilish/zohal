import '../workshop/production_calculator.dart';
import '../workshop/production_requirement.dart';
import 'cost_consumption_service.dart';
import 'costing_method.dart';
import 'production_cost.dart';

class ProductionCostService {
  final CostConsumptionService costConsumptionService;

  const ProductionCostService({required this.costConsumptionService});

  Future<ProductionCost> calculate({
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
