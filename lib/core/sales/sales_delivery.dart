class SalesDeliveryLine {
  const SalesDeliveryLine({
    required this.productVariantId,
    required this.quantity,
    required this.unitSellingPrice,
    required this.totalAmount,
    this.productName,
  });

  final String productVariantId;
  final int quantity;
  final int unitSellingPrice;
  final int totalAmount;
  final String? productName;

  Map<String, dynamic> toMap() => {
    'productVariantId': productVariantId,
    'quantity': quantity,
    'unitSellingPrice': unitSellingPrice,
    'totalAmount': totalAmount,
    'productName': productName,
  };

  factory SalesDeliveryLine.fromMap(Map<String, dynamic> map) {
    return SalesDeliveryLine(
      productVariantId: map['productVariantId'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitSellingPrice: (map['unitSellingPrice'] as num).toInt(),
      totalAmount: (map['totalAmount'] as num).toInt(),
      productName: map['productName'] as String?,
    );
  }
}

class SalesDelivery {
  const SalesDelivery({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.createdAt,
    required this.lines,
    required this.totalAmount,
  });

  final String id;
  final String orderId;
  final String customerId;
  final DateTime createdAt;
  final List<SalesDeliveryLine> lines;
  final int totalAmount;

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'customerId': customerId,
    'createdAt': createdAt.toIso8601String(),
    'lines': lines.map((line) => line.toMap()).toList(),
    'totalAmount': totalAmount,
  };

  factory SalesDelivery.fromMap(Map<String, dynamic> map) {
    return SalesDelivery(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      customerId: map['customerId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      lines: (map['lines'] as List)
          .whereType<Map>()
          .map((line) => SalesDeliveryLine.fromMap(Map<String, dynamic>.from(line)))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toInt(),
    );
  }
}
