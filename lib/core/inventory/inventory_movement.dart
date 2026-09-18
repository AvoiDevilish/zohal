enum InventoryMovementType {
  purchase,
  productionConsumption,
  productionOutput,
  sale,
  saleReturn,
  purchaseReturn,
  adjustmentIncrease,
  adjustmentDecrease,
  waste,
}

extension InventoryMovementTypeExtension on InventoryMovementType {
  String get key {
    switch (this) {
      case InventoryMovementType.purchase:
        return 'purchase';
      case InventoryMovementType.productionConsumption:
        return 'production_consumption';
      case InventoryMovementType.productionOutput:
        return 'production_output';
      case InventoryMovementType.sale:
        return 'sale';
      case InventoryMovementType.saleReturn:
        return 'sale_return';
      case InventoryMovementType.purchaseReturn:
        return 'purchase_return';
      case InventoryMovementType.adjustmentIncrease:
        return 'adjustment_increase';
      case InventoryMovementType.adjustmentDecrease:
        return 'adjustment_decrease';
      case InventoryMovementType.waste:
        return 'waste';
    }
  }

  String get title {
    switch (this) {
      case InventoryMovementType.purchase:
        return 'خرید';
      case InventoryMovementType.productionConsumption:
        return 'مصرف تولید';
      case InventoryMovementType.productionOutput:
        return 'خروجی تولید';
      case InventoryMovementType.sale:
        return 'فروش';
      case InventoryMovementType.saleReturn:
        return 'برگشت فروش';
      case InventoryMovementType.purchaseReturn:
        return 'برگشت خرید';
      case InventoryMovementType.adjustmentIncrease:
        return 'افزایش اصلاحی';
      case InventoryMovementType.adjustmentDecrease:
        return 'کاهش اصلاحی';
      case InventoryMovementType.waste:
        return 'ضایعات';
    }
  }

  bool get increasesStock {
    switch (this) {
      case InventoryMovementType.purchase:
      case InventoryMovementType.productionOutput:
      case InventoryMovementType.saleReturn:
      case InventoryMovementType.adjustmentIncrease:
        return true;
      case InventoryMovementType.productionConsumption:
      case InventoryMovementType.sale:
      case InventoryMovementType.purchaseReturn:
      case InventoryMovementType.adjustmentDecrease:
      case InventoryMovementType.waste:
        return false;
    }
  }

  static InventoryMovementType fromKey(String? key) {
    return InventoryMovementType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => InventoryMovementType.adjustmentIncrease,
    );
  }
}

class InventoryMovement {
  const InventoryMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.itemType,
    required this.quantity,
    required this.unit,
    required this.movementType,
    required this.timestamp,
    this.referenceId,
    this.unitCost,
    this.note,
  });

  final String id;
  final String itemId;
  final String itemName;
  final String itemType;
  final double quantity;
  final String unit;
  final InventoryMovementType movementType;
  final DateTime timestamp;
  final String? referenceId;
  final int? unitCost;
  final String? note;

  double get signedQuantity {
    return movementType.increasesStock ? quantity : -quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'itemType': itemType,
      'quantity': quantity,
      'unit': unit,
      'movementType': movementType.key,
      'timestamp': timestamp.toIso8601String(),
      'referenceId': referenceId,
      'unitCost': unitCost,
      'note': note,
    };
  }

  factory InventoryMovement.fromMap(Map<String, dynamic> map) {
    return InventoryMovement(
      id: map['id'] as String,
      itemId: map['itemId'] as String,
      itemName: map['itemName'] as String,
      itemType: map['itemType'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String,
      movementType: InventoryMovementTypeExtension.fromKey(
        map['movementType'] as String?,
      ),
      timestamp: DateTime.parse(map['timestamp'] as String),
      referenceId: map['referenceId'] as String?,
      unitCost: (map['unitCost'] as num?)?.toInt(),
      note: map['note'] as String?,
    );
  }
}
