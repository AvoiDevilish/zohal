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

  /// Runs the accounting and inventory workflow for one production batch.
  ///
  /// Cost allocation is completed before inventory movements are written.
  /// Both cost allocation and inventory execution are idempotent, so a retry
  /// after a partial failure can resume without consuming the same cost twice.
  Future<ProductionWorkflowResult> execute({
    required ProductionBatch batch,
    required ProductionCalculation calculation,
  }) async {
    var cost = await productionCostStore.getByProductionId(batch.id);

    if (cost == null) {
      cost = await productionCostService.calculate(
        productionId: batch.id,
        calculation: calculation,
      );
    }

    final execution = await productionService.executeBatch(
      batch: batch,
      calculation: calculation,
    );

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

    return ProductionWorkflowResult(
      execution: execution,
      cost: cost,
    );
  }
}
