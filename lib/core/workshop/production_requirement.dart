class ProductionRequirement {
  final String materialId;
  final String materialName;
  final double quantity;
  final String unit;

  const ProductionRequirement({
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unit,
  });

  @override
  String toString() {
    return '$materialName: $quantity $unit';
  }
}
