class CostAllocation {
  final String id;
  final String materialId;
  final String materialName;
  final String costLayerId;
  final double quantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final String referenceId;
  final DateTime createdAt;

  const CostAllocation({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.costLayerId,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
    required this.referenceId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialId': materialId,
      'materialName': materialName,
      'costLayerId': costLayerId,
      'quantity': quantity,
      'unit': unit,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'referenceId': referenceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CostAllocation.fromMap(Map<String, dynamic> map) {
    return CostAllocation(
      id: map['id'] as String,
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      costLayerId: map['costLayerId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitCost: (map['unitCost'] as num).toDouble(),
      totalCost: (map['totalCost'] as num).toDouble(),
      referenceId: map['referenceId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
