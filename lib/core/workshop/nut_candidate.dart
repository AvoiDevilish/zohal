class NutCandidate {
  final String materialId;
  final String materialName;

  /// Current stock in the material's canonical unit.
  final double stock;

  /// Minimum desired stock.
  final double minimumStock;

  /// Last known purchase price per canonical unit.
  final double purchasePrice;

  const NutCandidate({
    required this.materialId,
    required this.materialName,
    required this.stock,
    required this.minimumStock,
    required this.purchasePrice,
  });

  double get stockAboveMinimum {
    return stock - minimumStock;
  }

  double get stockCoverageRatio {
    if (minimumStock <= 0) {
      return stock > 0 ? double.infinity : 0;
    }

    return stock / minimumStock;
  }
}
