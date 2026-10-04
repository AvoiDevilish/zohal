import '../costing/production_cost.dart';
import '../costing/production_cost_service.dart';
import '../costing/production_cost_store.dart';
import 'production_batch.dart';
import 'production_batch_store.dart';
import 'production_calculator.dart';
import 'production_service.dart';

class ProductionWorkflowResult {
  final ProductionExecutionResult execution;
  final ProductionCost cost;

  const ProductionWorkflowResult({
    required this.execution,
    required this.cost,
  });

  Future<ProductionWorkflowResult> _executeInternal() async => this;
}

class ProductionWorkflowService {
  final ProductionService productionService;
  final ProductionCostService productionCostService;
  final ProductionBatchStore productionBatchStore;
  final ProductionCostStore productionCostStore;

  const ProductionWorkflowService({
    required this.productionService,
    required this.productionCostService,
    required this.productionBatchStore,
    required this.productionCostStore,
  });

  /// Inventory is executed before costing so failed stock checks cannot consume
  /// Cost Layers. Both phases are retry-safe.
  Future<ProductionWorkflowResult> execute({
    required ProductionBatch batch,
    required ProductionCalculation calculation,
  }) async {
    final execution = await productionService.executeBatch(
      batch: batch,
      calculation: calculation,
    );

    if (!execution.executed && !execution.alreadyExecuted) {
      throw StateError(
        'تولید به دلیل کمبود موجودی اجرا نشد و هزینه‌ای نباید ثبت شود.',
      );
    }

    var cost = await productionCostStore.getByProductionId(batch.id);
    if (cost == null) {
      cost = await productionCostService.calculate(
        productionId: batch.id,
        calculation: calculation,
      );
    }

    final persistedBatch = await productionBatchStore.getById(batch.id);
    if (persistedBatch == null) {
      await productionBatchStore.add(execution.batch);
    }

    final persistedCost = await productionCostStore.getByProductionId(batch.id);
    if (persistedCost == null) {
      await productionCostStore.add(cost);
    } else {
      cost = persistedCost;
    }

    return ProductionWorkflowResult(execution: execution, cost: cost);
  }
}
