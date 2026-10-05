class CostLayer {
  final String id;
  final String materialId;
  final String materialName;
  final double quantity;
  final double remainingQuantity;
  final String unit;
  final double unitCost;
  final DateTime createdAt;
  final String? purchaseId;
  final String? lotNumber;
  final DateTime? expiryDate;

  const CostLayer({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.remainingQuantity,
    required this.unit,
    required this.unitCost,
    required this.createdAt,
    this.purchaseId,
    this.lotNumber,
    this.expiryDate,
  });

  double get totalCost => quantity * unitCost;

  double get remainingCost => remainingQuantity * unitCost;

  CostLayer copyWith({
    String? id,
    String? materialId,
    String? materialName,
    double? quantity,
    double? remainingQuantity,
    String? unit,
    double? unitCost,
    DateTime? createdAt,
    String? purchaseId,
    String? lotNumber,
    DateTime? expiryDate,
  }) {
    return CostLayer(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unit: unit ?? this.unit,
      unitCost: unitCost ?? this.unitCost,
      createdAt: createdAt ?? this.createdAt,
      purchaseId: purchaseId ?? this.purchaseId,
      lotNumber: lotNumber ?? this.lotNumber,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialId': materialId,
      'materialName': materialName,
      'quantity': quantity,
      'remainingQuantity': remainingQuantity,
      'unit': unit,
      'unitCost': unitCost,
      'createdAt': createdAt.toIso8601String(),
      'purchaseId': purchaseId,
      'lotNumber': lotNumber,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }

  factory CostLayer.fromMap(Map<String, dynamic> map) {
    return CostLayer(
      id: map['id'] as String,
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      remainingQuantity: (map['remainingQuantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitCost: (map['unitCost'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      purchaseId: map['purchaseId'] as String?,
      lotNumber: map['lotNumber'] as String?,
      expiryDate: map['expiryDate'] == null
          ? null
          : DateTime.parse(map['expiryDate'] as String),
    );
  }
}
