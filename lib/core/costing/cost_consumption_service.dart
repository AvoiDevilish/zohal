import 'cost_allocation.dart' as allocation_model;
import 'cost_allocation_store.dart';
import 'costing_engine.dart';
import 'costing_method.dart';
import 'cost_layer.dart';
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

  /// Validates a consumption request without persisting allocations or changing layer balances.\n  /// This is used by the production workflow as a costing preflight so an\n  /// expired/insufficient FEFO request cannot consume inventory first.\n  Future<CostCalculation> preview({\n    required String referenceId,\n    required String materialId,\n    required double quantity,\n    CostingMethod method = CostingMethod.fifo,\n    bool allowExpiredLots = false,\n    DateTime? now,\n  }) async {\n    if (referenceId.trim().isEmpty) {\n      throw ArgumentError('referenceId نمی‌تواند خالی باشد.');\n    }\n    if (quantity <= 0) {\n      throw ArgumentError('مقدار مصرف باید بیشتر از صفر باشد.');\n    }\n\n    final existing = await allocationStore.getAllocations(\n      referenceId: referenceId,\n      materialId: materialId,\n    );\n\n    if (existing.isNotEmpty) {\n      final existingQuantity =\n          existing.fold(0.0, (sum, item) => sum + item.quantity);\n      if ((existingQuantity - quantity).abs() > 0.000001) {\n        throw StateError(\n          'مصرف "$referenceId" قبلاً با مقدار متفاوتی ثبت شده است.',\n        );\n      }\n\n      return CostCalculation(\n        requestedQuantity: existingQuantity,\n        totalCost: existing.fold(0.0, (sum, item) => sum + item.totalCost),\n        allocations: List.unmodifiable(\n          existing\n              .map(\n                (item) => EngineAllocation(\n                  layerId: item.costLayerId,\n                  quantity: item.quantity,\n                  unitCost: item.unitCost,\n                ),\n              )\n              .toList(),\n        ),\n      );\n    }\n\n    final layers = await costLayerStore.getLayers(materialId: materialId);\n    if (layers.isEmpty) {\n      throw StateError(\n        'هیچ Cost Layer فعالی برای ماده "$materialId" وجود ندارد.',\n      );\n    }\n\n    return const CostingEngine().calculate(\n      layers: layers,\n      quantity: quantity,\n      method: method,\n      allowExpiredLots: allowExpiredLots,\n      now: now,\n    );\n  }\n\n  Future<CostConsumptionResult> consume({
    required String referenceId,
    required String materialId,
    required double quantity,
    CostingMethod method = CostingMethod.fifo,
    bool allowExpiredLots = false,
    DateTime? now,
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
      final existingQuantity =
          existing.fold(0.0, (sum, item) => sum + item.quantity);
      if ((existingQuantity - quantity).abs() > 0.000001) {
        throw StateError(
          'مصرف "$referenceId" قبلاً با مقدار متفاوتی ثبت شده است.',
        );
      }
      if (method != CostingMethod.weightedAverage) {
        await _reconcileLayerBalances(existing);
      }
      return CostConsumptionResult(
        referenceId: referenceId,
        requestedQuantity: existingQuantity,
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
      allowExpiredLots: allowExpiredLots,
      now: now,
    );

    if (method == CostingMethod.weightedAverage) {
      final allocation = calculation.allocations.first;
      final layer = layers.first;
      final createdAt = DateTime.now();
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
        createdAt: createdAt,
        sourceLotNumber: layer.lotNumber,
        sourceExpiryDate: layer.expiryDate,
      );
      await allocationStore.add(weightedAllocation);
      return CostConsumptionResult(
        referenceId: referenceId,
        requestedQuantity: calculation.requestedQuantity,
        totalCost: calculation.totalCost,
        allocations: [weightedAllocation],
      );
    }

    final createdAt = DateTime.now();
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
          createdAt: createdAt,
          sourceLotNumber: layer.lotNumber,
          sourceExpiryDate: layer.expiryDate,
        ),
      );
    }

    // Allocations are the durable intent. Persist them first so an interrupted
    // layer update can be repaired deterministically by a later retry.
    await allocationStore.addAll(allocations);
    await _reconcileLayerBalances(allocations);

    return CostConsumptionResult(
      referenceId: referenceId,
      requestedQuantity: calculation.requestedQuantity,
      totalCost: calculation.totalCost,
      allocations: List.unmodifiable(allocations),
    );
  }

  Future<void> _reconcileLayerBalances(
    List<allocation_model.CostAllocation> relevantAllocations,
  ) async {
    final layerIds = relevantAllocations
        .map((allocation) => allocation.costLayerId)
        .where((id) => id != 'weighted-average')
        .toSet();
    if (layerIds.isEmpty) return;

    final updates = <CostLayer>[];
    for (final layerId in layerIds) {
      final layer = await costLayerStore.getById(layerId);
      if (layer == null) {
        throw StateError('Cost Layer "$layerId" پیدا نشد.');
      }

      final allAllocations =
          await allocationStore.getAllocations(costLayerId: layerId);
      final consumedQuantity =
          allAllocations.fold(0.0, (sum, allocation) => sum + allocation.quantity);
      final remainingQuantity = layer.quantity - consumedQuantity;

      if (remainingQuantity < -0.000001) {
        throw StateError(
          'مجموع مصرف Cost Layer "${layer.id}" از مقدار اولیه آن بیشتر است.',
        );
      }

      updates.add(
        layer.copyWith(
          remainingQuantity: remainingQuantity < 0 ? 0 : remainingQuantity,
        ),
      );
    }

    await costLayerStore.updateAll(updates);
  }
}
