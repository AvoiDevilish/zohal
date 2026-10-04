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
  String toString() => '$materialName: $quantity $unit';
}

class ProductionByproduct {
  final String itemId;
  final String itemName;
  final String itemType;
  final double quantity;
  final String unit;

  const ProductionByproduct({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.unit,
  });
}
