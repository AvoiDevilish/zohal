import 'cost_layer.dart';
import 'costing_method.dart';

class EngineAllocation {
  final String layerId;
  final double quantity;
  final double unitCost;

  const EngineAllocation({
    required this.layerId,
    required this.quantity,
    required this.unitCost,
  });

  double get totalCost => quantity * unitCost;
}

class CostCalculation {
  final double requestedQuantity;
  final double totalCost;
  final List<EngineAllocation> allocations;

  const CostCalculation({
    required this.requestedQuantity,
    required this.totalCost,
    required this.allocations,
  });

  double get averageUnitCost {
    if (requestedQuantity == 0) {
      return 0;
    }

    return totalCost / requestedQuantity;
  }
}

class CostingEngine {
  const CostingEngine();

  CostCalculation calculate({
    required List<CostLayer> layers,
    required double quantity,
    CostingMethod method = CostingMethod.fifo,
  }) {
    if (quantity <= 0) {
      throw ArgumentError('Requested quantity must be greater than zero.');
    }

    final availableLayers = layers
        .where((layer) => layer.remainingQuantity > 0)
        .toList();

    if (availableLayers.isEmpty) {
      throw StateError('No available cost layers for requested material.');
    }

    final materialIds = availableLayers
        .map((layer) => layer.materialId)
        .toSet();

    if (materialIds.length > 1) {
      throw ArgumentError('All cost layers must belong to the same material.');
    }

    switch (method) {
      case CostingMethod.fifo:
        return _calculateFifo(layers: availableLayers, quantity: quantity);

      case CostingMethod.fefo:
        return _calculateFefo(
          layers: availableLayers,
          quantity: quantity,
        );

      case CostingMethod.weightedAverage:
        return _calculateWeightedAverage(
          layers: availableLayers,
          quantity: quantity,
        );
    }
  }

  CostCalculation _calculateFifo({
    required List<CostLayer> layers,
    required double quantity,
  }) {
    final sortedLayers = [...layers]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    var remaining = quantity;
    var totalCost = 0.0;
    final allocations = <EngineAllocation>[];

    for (final layer in sortedLayers) {
      if (remaining <= 0) {
        break;
      }

      final allocated = remaining < layer.remainingQuantity
          ? remaining
          : layer.remainingQuantity;

      allocations.add(
        EngineAllocation(
          layerId: layer.id,
          quantity: allocated,
          unitCost: layer.unitCost,
        ),
      );

      totalCost += allocated * layer.unitCost;
      remaining -= allocated;
    }

    if (remaining > 0) {
      throw StateError(
        'Insufficient cost-layer quantity. '
        'Missing: $remaining ${sortedLayers.first.unit}.',
      );
    }

    return CostCalculation(
      requestedQuantity: quantity,
      totalCost: totalCost,
      allocations: List.unmodifiable(allocations),
    );
  }

  CostCalculation _calculateFefo({
    required List<CostLayer> layers,
    required double quantity,
  }) {
    final sortedLayers = [...layers]
      ..sort((a, b) {
        final aExpiry = a.expiryDate;
        final bExpiry = b.expiryDate;

        if (aExpiry == null && bExpiry == null) {
          return a.createdAt.compareTo(b.createdAt);
        }
        if (aExpiry == null) return 1;
        if (bExpiry == null) return -1;

        final expiryComparison = aExpiry.compareTo(bExpiry);
        if (expiryComparison != 0) return expiryComparison;
        return a.createdAt.compareTo(b.createdAt);
      });

    return _allocateFromOrderedLayers(
      layers: sortedLayers,
      quantity: quantity,
    );
  }

  CostCalculation _allocateFromOrderedLayers({
    required List<CostLayer> layers,
    required double quantity,
  }) {
    var remaining = quantity;
    var totalCost = 0.0;
    final allocations = <EngineAllocation>[];

    for (final layer in layers) {
      if (remaining <= 0) break;

      final allocated = remaining < layer.remainingQuantity
          ? remaining
          : layer.remainingQuantity;

      allocations.add(
        EngineAllocation(
          layerId: layer.id,
          quantity: allocated,
          unitCost: layer.unitCost,
        ),
      );
      totalCost += allocated * layer.unitCost;
      remaining -= allocated;
    }

    if (remaining > 0) {
      throw StateError(
        'Insufficient cost-layer quantity. Missing: $remaining ${layers.first.unit}.',
      );
    }

    return CostCalculation(
      requestedQuantity: quantity,
      totalCost: totalCost,
      allocations: List.unmodifiable(allocations),
    );
  }

  CostCalculation _calculateWeightedAverage({
    required List<CostLayer> layers,
    required double quantity,
  }) {
    final totalAvailableQuantity = layers.fold<double>(
      0,
      (sum, layer) => sum + layer.remainingQuantity,
    );

    if (totalAvailableQuantity < quantity) {
      throw StateError(
        'Insufficient cost-layer quantity. '
        'Available: $totalAvailableQuantity, requested: $quantity.',
      );
    }

    final totalAvailableCost = layers.fold<double>(
      0,
      (sum, layer) => sum + layer.remainingCost,
    );

    final averageCost = totalAvailableCost / totalAvailableQuantity;

    return CostCalculation(
      requestedQuantity: quantity,
      totalCost: quantity * averageCost,
      allocations: List.unmodifiable([
        EngineAllocation(
          layerId: 'weighted-average',
          quantity: quantity,
          unitCost: averageCost,
        ),
      ]),
    );
  }
}
