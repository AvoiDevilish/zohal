import '../costing/cost_allocation_store.dart';
import '../costing/production_cost.dart';
import '../costing/production_cost_service.dart';
import '../costing/production_cost_store.dart';
import '../costing/costing_method.dart';
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
  final CostAllocationStore costAllocationStore;

  const ProductionWorkflowService({
    required this.productionService,
    required this.productionCostService,
    required this.productionBatchStore,
    required this.productionCostStore,
    CostAllocationStore? costAllocationStore,
  }) : costAllocationStore = costAllocationStore ?? CostAllocationStore.instance;

  /// Costing is preflighted before inventory so an invalid FEFO request
  /// cannot consume inventory first. Durable costing is then persisted only
  /// after inventory execution succeeds; retries remain idempotent.
  Future<ProductionWorkflowResult> execute({
    required ProductionBatch batch,
    required ProductionCalculation calculation,
    CostingMethod costingMethod = CostingMethod.fifo,
    bool allowExpiredLots = false,
    DateTime? now,
  }) async {
    var cost = await productionCostStore.getByProductionId(batch.id);
    final persistedBatch = await productionBatchStore.getById(batch.id);
    if (persistedBatch != null && !_sameBatchIdentity(persistedBatch, batch)) {
      throw StateError(
        'شناسه تولید "${batch.id}" قبلاً برای یک بچ متفاوت استفاده شده است.',
      );
    }

    if (cost == null) {
      await productionCostService.validate(
        productionId: batch.id,
        calculation: calculation,
        method: costingMethod,
        allowExpiredLots: allowExpiredLots,
        now: now,
      );
    }

    final execution = await productionService.executeBatch(
      batch: batch,
      calculation: calculation,
    );

    if (!execution.executed && !execution.alreadyExecuted) {
      throw StateError(
        'تولید به دلیل کمبود موجودی اجرا نشد و هزینه‌ای نباید ثبت شود.',
      );
    }

    if (cost == null) {
      cost = await productionCostService.calculate(
        productionId: batch.id,
        calculation: calculation,
        method: costingMethod,
        allowExpiredLots: allowExpiredLots,
        now: now,
      );
    }

    final allocations = await costAllocationStore.getAllocations();
    final sourceLots = allocations
        .where((allocation) => allocation.referenceId.startsWith('${batch.id}-'))
        .map((allocation) => allocation.sourceLotNumber)
        .whereType<String>()
        .where((lot) => lot.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final traceableBatch = execution.batch.copyWith(
      lotNumber: execution.batch.lotNumber ?? 'LOT-${batch.id}',
      expiryDate: execution.batch.expiryDate ?? batch.expiryDate,
      sourceLotNumbers: sourceLots,
    );

    final storedBatch = await productionBatchStore.getById(batch.id);
    if (storedBatch == null) {
      await productionBatchStore.add(traceableBatch);
    } else if (storedBatch.lotNumber != traceableBatch.lotNumber ||
        storedBatch.expiryDate != traceableBatch.expiryDate ||
        !_sameList(storedBatch.sourceLotNumbers, traceableBatch.sourceLotNumbers)) {
      await productionBatchStore.update(
        storedBatch.copyWith(
          lotNumber: traceableBatch.lotNumber,
          expiryDate: traceableBatch.expiryDate,
          sourceLotNumbers: traceableBatch.sourceLotNumbers,
        ),
      );
    }
    final persistedCost = await productionCostStore.getByProductionId(batch.id);
    if (persistedCost == null) {
      await productionCostStore.add(cost);
    } else {
      cost = persistedCost;
    }

    final persistedTraceableBatch =
        await productionBatchStore.getById(batch.id) ?? traceableBatch;
    final traceableExecution = ProductionExecutionResult(
      productionId: execution.productionId,
      stockCheck: execution.stockCheck,
      executed: execution.executed,
      alreadyExecuted: execution.alreadyExecuted,
      batch: persistedTraceableBatch,
    );

    return ProductionWorkflowResult(execution: traceableExecution, cost: cost);
  }

  bool _sameBatchIdentity(ProductionBatch left, ProductionBatch right) {
    return left.id == right.id &&
        left.productVariantId == right.productVariantId &&
        left.productName == right.productName &&
        left.units == right.units &&
        left.unitWeightGrams == right.unitWeightGrams &&
        left.recipeId == right.recipeId &&
        left.recipeVersion == right.recipeVersion &&
        left.createdAt == right.createdAt;
  }

  bool _sameList(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }
}
