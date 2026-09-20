import 'cost_allocation.dart' as allocation_model;
import 'cost_allocation_store.dart';
import 'costing_engine.dart';
import 'costing_method.dart';
import 'cost_layer_store.dart';

class CostConsumptionResult {
  final String referenceId;
  final double requestedQuantity;
  final double totalCost;
  final List<allocation_model.CostAllocation> allocations;
  final bool alreadyConsumed;

  const CostConsumptionResult({
    required this.referenceId,
    required this.requestedQuantity,
    required this.totalCost,
    required this.allocations,
    this.alreadyConsumed = false,
  });

  double get averageUnitCost =>
      requestedQuantity == 0 ? 0 : totalCost / requestedQuantity;
}

class CostConsumptionService {
  final CostLayerStore costLayerStore;
  final CostAllocationStore allocationStore;

  const CostConsumptionService({
    required this.costLayerStore,
    required this.allocationStore,
  });

  Future<CostConsumptionResult> consume({
    required String referenceId,
    required String materialId,
    required double quantity,
    CostingMethod method = CostingMethod.fifo,
  }) async {
    if (referenceId.trim().isEmpty) {
      throw ArgumentError('referenceId نمی‌تواند خالی باشد.');
    }

    if (quantity <= 0) {
      throw ArgumentError('مقدار مصرف باید بیشتر از صفر باشد.');
    }

    final existing = await allocationStore.getAllocations(
      referenceId: referenceId,
      materialId: materialId,
    );

    if (existing.isNotEmpty) {
      return CostConsumptionResult(
        referenceId: referenceId,
        requestedQuantity: existing.fold(0, (sum, item) => sum + item.quantity),
        totalCost: existing.fold(0, (sum, item) => sum + item.totalCost),
        allocations: existing,
        alreadyConsumed: true,
      );
    }

    final layers = await costLayerStore.getLayers(materialId: materialId);

    if (layers.isEmpty) {
      throw StateError(
        'هیچ Cost Layer فعالی برای ماده "$materialId" وجود ندارد.',
      );
    }

    final calculation = const CostingEngine().calculate(
      layers: layers,
      quantity: quantity,
      method: method,
    );

    if (method == CostingMethod.weightedAverage) {
      final allocation = calculation.allocations.first;
      final layer = layers.first;
      final now = DateTime.now();

      final weightedAllocation = allocation_model.CostAllocation(
        id: 'cost-allocation-$referenceId-0',
        materialId: layer.materialId,
        materialName: layer.materialName,
        costLayerId: 'weighted-average',
        quantity: allocation.quantity,
        unit: layer.unit,
        unitCost: allocation.unitCost,
        totalCost: allocation.totalCost,
        referenceId: referenceId,
        createdAt: now,
      );

      await allocationStore.add(weightedAllocation);

      return CostConsumptionResult(
        referenceId: referenceId,
        requestedQuantity: calculation.requestedQuantity,
        totalCost: calculation.totalCost,
        allocations: [weightedAllocation],
      );
    }

    final now = DateTime.now();
    final allocations = <allocation_model.CostAllocation>[];

    for (var index = 0; index < calculation.allocations.length; index++) {
      final allocation = calculation.allocations[index];

      final layer = await costLayerStore.getById(allocation.layerId);

      if (layer == null) {
        throw StateError('Cost Layer "${allocation.layerId}" پیدا نشد.');
      }

      final remainingQuantity = layer.remainingQuantity - allocation.quantity;

      if (remainingQuantity < -0.000001) {
        throw StateError('موجودی Cost Layer "${layer.id}" کافی نیست.');
      }

      await costLayerStore.update(
        layer.copyWith(
          remainingQuantity: remainingQuantity < 0 ? 0 : remainingQuantity,
        ),
      );

      allocations.add(
        allocation_model.CostAllocation(
          id: 'cost-allocation-$referenceId-$index',
          materialId: layer.materialId,
          materialName: layer.materialName,
          costLayerId: layer.id,
          quantity: allocation.quantity,
          unit: layer.unit,
          unitCost: allocation.unitCost,
          totalCost: allocation.totalCost,
          referenceId: referenceId,
          createdAt: now,
        ),
      );
    }

    for (final allocation in allocations) {
      await allocationStore.add(allocation);
    }

    return CostConsumptionResult(
      referenceId: referenceId,
      requestedQuantity: calculation.requestedQuantity,
      totalCost: calculation.totalCost,
      allocations: List.unmodifiable(allocations),
    );
  }
}
