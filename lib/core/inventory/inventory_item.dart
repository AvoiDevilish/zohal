enum InventoryItemType {
  product,
  rawMaterial,
  consumable,
  packaging,
  semiFinished,
}

extension InventoryItemTypeExtension on InventoryItemType {
  String get key => switch (this) {
    InventoryItemType.product => 'product',
    InventoryItemType.rawMaterial => 'raw_material',
    InventoryItemType.consumable => 'consumable',
    InventoryItemType.packaging => 'packaging',
    InventoryItemType.semiFinished => 'semi_finished',
  };

  String get title => switch (this) {
    InventoryItemType.product => 'محصول',
    InventoryItemType.rawMaterial => 'مواد اولیه',
    InventoryItemType.consumable => 'اقلام مصرفی',
    InventoryItemType.packaging => 'بسته‌بندی',
    InventoryItemType.semiFinished => 'محصول نیمه‌آماده',
  };

  static InventoryItemType fromKey(String? key) {
    return InventoryItemType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => InventoryItemType.rawMaterial,
    );
  }
}

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    this.minimumStock = 0,
  });

  final String id;
  final String name;
  final InventoryItemType type;
  final String unit;
  final double minimumStock;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.key,
    'unit': unit,
    'minimumStock': minimumStock,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      type: InventoryItemTypeExtension.fromKey(map['type'] as String?),
      unit: map['unit'] as String,
      minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 0,
    );
  }
}
