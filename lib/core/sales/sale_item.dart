class SaleItem {
  final String productVariantId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const SaleItem({
    required this.productVariantId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;

  SaleItem copyWith({
    String? productVariantId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) {
    return SaleItem(
      productVariantId: productVariantId ?? this.productVariantId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productVariantId': productVariantId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productVariantId: map['productVariantId'] as String,
      productName: map['productName'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitPrice: (map['unitPrice'] as num).toDouble(),
    );
  }
}
