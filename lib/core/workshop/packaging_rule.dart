class PackagingRule {
  final String productVariantId;
  final String materialId;
  final String materialName;
  final double quantityPerUnit;
  final String unit;
  final bool active;

  const PackagingRule({
    required this.productVariantId,
    required this.materialId,
    required this.materialName,
    required this.quantityPerUnit,
    required this.unit,
    this.active = true,
  });

  PackagingRule copyWith({
    String? productVariantId,
    String? materialId,
    String? materialName,
    double? quantityPerUnit,
    String? unit,
    bool? active,
  }) {
    return PackagingRule(
      productVariantId: productVariantId ?? this.productVariantId,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
      unit: unit ?? this.unit,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productVariantId': productVariantId,
      'materialId': materialId,
      'materialName': materialName,
      'quantityPerUnit': quantityPerUnit,
      'unit': unit,
      'active': active,
    };
  }

  factory PackagingRule.fromMap(Map<String, dynamic> map) {
    return PackagingRule(
      productVariantId: map['productVariantId'] as String,
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      quantityPerUnit: (map['quantityPerUnit'] as num).toDouble(),
      unit: map['unit'] as String,
      active: map['active'] as bool? ?? true,
    );
  }
}
