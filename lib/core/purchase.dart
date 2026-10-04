class PurchaseLine {
  const PurchaseLine({
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.unit,
    required this.unitCost,
  });

  final String itemId;
  final String itemName;
  final String itemType;
  final double quantity;
  final String unit;
  final int unitCost;

  int get totalCost => (quantity * unitCost).round();

  Map<String, dynamic> toMap() => {
    'itemId': itemId,
    'itemName': itemName,
    'itemType': itemType,
    'quantity': quantity,
    'unit': unit,
    'unitCost': unitCost,
  };

  factory PurchaseLine.fromMap(Map<String, dynamic> map) => PurchaseLine(
    itemId: map['itemId'] as String,
    itemName: map['itemName'] as String,
    itemType: map['itemType'] as String,
    quantity: (map['quantity'] as num).toDouble(),
    unit: map['unit'] as String,
    unitCost: (map['unitCost'] as num).toInt(),
  );
}

class Purchase {
  const Purchase({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.createdAt,
    required this.lines,
    required this.totalAmount,
    this.note,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final DateTime createdAt;
  final List<PurchaseLine> lines;
  final int totalAmount;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'supplierName': supplierName,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((line) => line.toMap()).toList(),
    'totalAmount': totalAmount,
    'note': note,
  };

  factory Purchase.fromMap(Map<String, dynamic> map) => Purchase(
    id: map['id'] as String,
    supplierId: map['supplierId'] as String,
    supplierName: map['supplierName'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
    lines: (map['lines'] as List)
        .whereType<Map>()
        .map((line) => PurchaseLine.fromMap(Map<String, dynamic>.from(line)))
        .toList(),
    totalAmount: (map['totalAmount'] as num).toInt(),
    note: map['note'] as String?,
  );
}
