class ProductionCost {
  final String productionId;

  final double materialCost;
  final double packagingCost;
  final double consumableCost;

  final double totalCost;

  final int outputQuantity;

  final DateTime createdAt;

  const ProductionCost({
    required this.productionId,
    required this.materialCost,
    required this.packagingCost,
    required this.consumableCost,
    required this.totalCost,
    required this.outputQuantity,
    required this.createdAt,
  });

  double get unitCost {
    if (outputQuantity == 0) {
      return 0;
    }

    return totalCost / outputQuantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'productionId': productionId,
      'materialCost': materialCost,
      'packagingCost': packagingCost,
      'consumableCost': consumableCost,
      'totalCost': totalCost,
      'outputQuantity': outputQuantity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductionCost.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic value) {
      if (value is num) {
        return value.toDouble();
      }

      return double.parse(value.toString());
    }

    int toInt(dynamic value) {
      if (value is num) {
        return value.toInt();
      }

      return int.parse(value.toString());
    }

    return ProductionCost(
      productionId: map['productionId'] as String,
      materialCost: toDouble(map['materialCost']),
      packagingCost: toDouble(map['packagingCost']),
      consumableCost: toDouble(map['consumableCost']),
      totalCost: toDouble(map['totalCost']),
      outputQuantity: toInt(map['outputQuantity']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
