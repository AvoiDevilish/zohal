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

class InventoryUnitConversion {
  const InventoryUnitConversion({
    required this.unit,
    required this.toBaseFactor,
  });

  final String unit;
  final double toBaseFactor;

  Map<String, dynamic> toMap() => {
    'unit': unit,
    'toBaseFactor': toBaseFactor,
  };

  factory InventoryUnitConversion.fromMap(Map<String, dynamic> map) {
    return InventoryUnitConversion(
      unit: map['unit'] as String,
      toBaseFactor: (map['toBaseFactor'] as num).toDouble(),
    );
  }
}

class NutritionProfile {
  const NutritionProfile({
    required this.energyKcal,
    required this.proteinG,
    required this.totalFatG,
    required this.saturatedFatG,
    required this.carbohydrateG,
    required this.totalSugarG,
    required this.fiberG,
    required this.sodiumMg,
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.phosphorusMg,
    this.potassiumMg,
    this.source,
    this.note,
  });

  final double energyKcal;
  final double proteinG;
  final double totalFatG;
  final double saturatedFatG;
  final double carbohydrateG;
  final double totalSugarG;
  final double fiberG;
  final double sodiumMg;
  final double? calciumMg;
  final double? ironMg;
  final double? magnesiumMg;
  final double? phosphorusMg;
  final double? potassiumMg;
  final String? source;
  final String? note;

  Map<String, dynamic> toMap() => {
    'energyKcal': energyKcal,
    'proteinG': proteinG,
    'totalFatG': totalFatG,
    'saturatedFatG': saturatedFatG,
    'carbohydrateG': carbohydrateG,
    'totalSugarG': totalSugarG,
    'fiberG': fiberG,
    'sodiumMg': sodiumMg,
    'calciumMg': calciumMg,
    'ironMg': ironMg,
    'magnesiumMg': magnesiumMg,
    'phosphorusMg': phosphorusMg,
    'potassiumMg': potassiumMg,
    'source': source,
    'note': note,
  };

  factory NutritionProfile.fromMap(Map<String, dynamic> map) {
    double? number(String key) => (map[key] as num?)?.toDouble();

    return NutritionProfile(
      energyKcal: (map['energyKcal'] as num).toDouble(),
      proteinG: (map['proteinG'] as num).toDouble(),
      totalFatG: (map['totalFatG'] as num).toDouble(),
      saturatedFatG: (map['saturatedFatG'] as num).toDouble(),
      carbohydrateG: (map['carbohydrateG'] as num).toDouble(),
      totalSugarG: (map['totalSugarG'] as num).toDouble(),
      fiberG: (map['fiberG'] as num).toDouble(),
      sodiumMg: (map['sodiumMg'] as num).toDouble(),
      calciumMg: number('calciumMg'),
      ironMg: number('ironMg'),
      magnesiumMg: number('magnesiumMg'),
      phosphorusMg: number('phosphorusMg'),
      potassiumMg: number('potassiumMg'),
      source: map['source'] as String?,
      note: map['note'] as String?,
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
    this.category,
    this.englishName,
    this.isFood = false,
    this.unitConversions = const [],
    this.nutrition,
    this.notes,
  });

  final String id;
  final String name;
  final InventoryItemType type;
  final String unit;
  final double minimumStock;
  final String? category;
  final String? englishName;
  final bool isFood;
  final List<InventoryUnitConversion> unitConversions;
  final NutritionProfile? nutrition;
  final String? notes;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.key,
    'unit': unit,
    'minimumStock': minimumStock,
    'category': category,
    'englishName': englishName,
    'isFood': isFood,
    'unitConversions': unitConversions.map((item) => item.toMap()).toList(),
    'nutrition': nutrition?.toMap(),
    'notes': notes,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    final rawConversions = map['unitConversions'];
    final rawNutrition = map['nutrition'];

    return InventoryItem(
      id: map['id'] as String,
      name: map['name'] as String,
      type: InventoryItemTypeExtension.fromKey(map['type'] as String?),
      unit: map['unit'] as String,
      minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String?,
      englishName: map['englishName'] as String?,
      isFood: map['isFood'] as bool? ?? false,
      unitConversions: rawConversions is List
          ? rawConversions
              .whereType<Map>()
              .map(
                (item) => InventoryUnitConversion.fromMap(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : const [],
      nutrition: rawNutrition is Map
          ? NutritionProfile.fromMap(Map<String, dynamic>.from(rawNutrition))
          : null,
      notes: map['notes'] as String?,
    );
  }
}
