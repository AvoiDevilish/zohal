class SalesReturnLine {
  const SalesReturnLine({
    required this.productVariantId,
    required this.quantity,
    required this.unitSellingPrice,
    required this.totalAmount,
  });

  final String productVariantId;
  final int quantity;
  final int unitSellingPrice;
  final int totalAmount;

  Map<String, dynamic> toMap() => {
    'productVariantId': productVariantId,
    'quantity': quantity,
    'unitSellingPrice': unitSellingPrice,
    'totalAmount': totalAmount,
  };

  factory SalesReturnLine.fromMap(Map<String, dynamic> map) {
    return SalesReturnLine(
      productVariantId: map['productVariantId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitSellingPrice: (map['unitSellingPrice'] as num).toInt(),
      totalAmount: (map['totalAmount'] as num).toInt(),
    );
  }
}

class SalesReturn {
  const SalesReturn({
    required this.id,
    required this.deliveryId,
    required this.orderId,
    required this.customerId,
    required this.createdAt,
    required this.lines,
    required this.totalAmount,
    this.note,
  });

  final String id;
  final String deliveryId;
  final String orderId;
  final String customerId;
  final DateTime createdAt;
  final List<SalesReturnLine> lines;
  final int totalAmount;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'deliveryId': deliveryId,
    'orderId': orderId,
    'customerId': customerId,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((line) => line.toMap()).toList(),
    'totalAmount': totalAmount,
    'note': note,
  };

  factory SalesReturn.fromMap(Map<String, dynamic> map) {
    return SalesReturn(
      id: map['id'] as String,
      deliveryId: map['deliveryId'] as String,
      orderId: map['orderId'] as String,
      customerId: map['customerId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lines: (map['lines'] as List)
          .whereType<Map>()
          .map((line) => SalesReturnLine.fromMap(Map<String, dynamic>.from(line)))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toInt(),
      note: map['note'] as String?,
    );
  }
}
