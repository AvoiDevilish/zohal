class Purchase {
  final String id;
  final String materialId;
  final String materialName;
  final double quantity;
  final String unit;
  final double unitPrice;
  final String? supplierId;
  final String? supplierName;
  final DateTime purchaseDate;
  final String? note;

  const Purchase({
    required this.id,
    required this.materialId,
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.supplierId,
    this.supplierName,
    required this.purchaseDate,
    this.note,
  });

  double get totalPrice => quantity * unitPrice;

  Purchase copyWith({
    String? id,
    String? materialId,
    String? materialName,
    double? quantity,
    String? unit,
    double? unitPrice,
    String? supplierId,
    String? supplierName,
    DateTime? purchaseDate,
    String? note,
    bool clearSupplier = false,
    bool clearNote = false,
  }) {
    return Purchase(
      id: id ?? this.id,
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      supplierId: clearSupplier ? null : supplierId ?? this.supplierId,
      supplierName: clearSupplier ? null : supplierName ?? this.supplierName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      note: clearNote ? null : note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'materialId': materialId,
      'materialName': materialName,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'purchaseDate': purchaseDate.toIso8601String(),
      'note': note,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'] as String,
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      unitPrice: (map['unitPrice'] as num).toDouble(),
      supplierId: map['supplierId'] as String?,
      supplierName: map['supplierName'] as String?,
      purchaseDate: DateTime.parse(map['purchaseDate'] as String),
      note: map['note'] as String?,
    );
  }
}
