enum RecipeComponentType {
  date,
  nut,
  sesame,
  flavoring,
  packaging,
}

class RecipeComponent {
  final String materialId;
  final String materialName;
  final RecipeComponentType type;

  /// Percentage of the applicable recipe mass.
  final double percentage;

  /// For count-based items such as containers or labels.
  final double quantityPerUnit;

  const RecipeComponent({
    required this.materialId,
    required this.materialName,
    required this.type,
    this.percentage = 0,
    this.quantityPerUnit = 0,
  });

  RecipeComponent copyWith({
    String? materialId,
    String? materialName,
    RecipeComponentType? type,
    double? percentage,
    double? quantityPerUnit,
  }) {
    return RecipeComponent(
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      type: type ?? this.type,
      percentage: percentage ?? this.percentage,
      quantityPerUnit: quantityPerUnit ?? this.quantityPerUnit,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'materialName': materialName,
      'type': type.name,
      'percentage': percentage,
      'quantityPerUnit': quantityPerUnit,
    };
  }

  factory RecipeComponent.fromMap(Map<String, dynamic> map) {
    final typeKey = map['type'] as String? ?? 'date';

    final type = RecipeComponentType.values.firstWhere(
      (item) => item.name == typeKey,
      orElse: () => RecipeComponentType.date,
    );

    return RecipeComponent(
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      type: type,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0,
      quantityPerUnit:
          (map['quantityPerUnit'] as num?)?.toDouble() ?? 0,
    );
  }
}
