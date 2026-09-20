enum ProductionRequirementType { rawMaterial, consumable, packaging }

class ProductionRequirement {
  final String materialId;
  final String materialName;
  final double quantity;
  final String unit;
  final ProductionRequirementType type;

  const ProductionRequirement({
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unit,
    this.type = ProductionRequirementType.rawMaterial,
  });

  @override
  String toString() {
    return '$materialName: $quantity $unit';
  }
}
