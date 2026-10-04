import 'recipe_component.dart';

class Recipe {
  final String id;
  final String productVariantId;
  final String name;
  final int version;
  final double datePercentage;
  final double nutPercentage;
  final double sesamePercentage;
  final double flavoringPercentage;
  final double dateMeatYieldPercentage;
  final List<RecipeComponent> components;
  final bool active;

  const Recipe({
    required this.id,
    required this.productVariantId,
    required this.name,
    this.version = 1,
    this.datePercentage = 70,
    this.nutPercentage = 27,
    this.sesamePercentage = 3,
    this.flavoringPercentage = 0.5,
    this.dateMeatYieldPercentage = 90,
    this.components = const [],
    this.active = true,
  });

  double get basePercentageTotal =>
      datePercentage + nutPercentage + sesamePercentage;

  bool get isBaseFormulaValid =>
      (basePercentageTotal - 100).abs() < 0.0001;

  bool get isFlavoringValid =>
      flavoringPercentage >= 0 && flavoringPercentage < 1;

  bool get isDateYieldValid =>
      dateMeatYieldPercentage > 0 && dateMeatYieldPercentage <= 100;

  bool get isValid =>
      isBaseFormulaValid && isFlavoringValid && isDateYieldValid;

  Recipe copyWith({
    String? id,
    String? productVariantId,
    String? name,
    int? version,
    double? datePercentage,
    double? nutPercentage,
    double? sesamePercentage,
    double? flavoringPercentage,
    double? dateMeatYieldPercentage,
    List<RecipeComponent>? components,
    bool? active,
  }) {
    return Recipe(
      id: id ?? this.id,
      productVariantId: productVariantId ?? this.productVariantId,
      name: name ?? this.name,
      version: version ?? this.version,
      datePercentage: datePercentage ?? this.datePercentage,
      nutPercentage: nutPercentage ?? this.nutPercentage,
      sesamePercentage: sesamePercentage ?? this.sesamePercentage,
      flavoringPercentage: flavoringPercentage ?? this.flavoringPercentage,
      dateMeatYieldPercentage:
          dateMeatYieldPercentage ?? this.dateMeatYieldPercentage,
      components: components ?? this.components,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productVariantId': productVariantId,
    'name': name,
    'version': version,
    'datePercentage': datePercentage,
    'nutPercentage': nutPercentage,
    'sesamePercentage': sesamePercentage,
    'flavoringPercentage': flavoringPercentage,
    'dateMeatYieldPercentage': dateMeatYieldPercentage,
    'components': components.map((item) => item.toMap()).toList(),
    'active': active,
  };

  factory Recipe.fromMap(Map<String, dynamic> map) {
    final rawComponents = map['components'];
    final components = rawComponents is List
        ? rawComponents.whereType<Map>().map(
            (item) => RecipeComponent.fromMap(
              Map<String, dynamic>.from(item),
            ),
          ).toList()
        : <RecipeComponent>[];

    return Recipe(
      id: map['id'] as String,
      productVariantId: map['productVariantId'] as String,
      name: map['name'] as String,
      version: (map['version'] as num?)?.toInt() ?? 1,
      datePercentage: (map['datePercentage'] as num?)?.toDouble() ?? 70,
      nutPercentage: (map['nutPercentage'] as num?)?.toDouble() ?? 27,
      sesamePercentage: (map['sesamePercentage'] as num?)?.toDouble() ?? 3,
      flavoringPercentage:
          (map['flavoringPercentage'] as num?)?.toDouble() ?? 0.5,
      dateMeatYieldPercentage:
          (map['dateMeatYieldPercentage'] as num?)?.toDouble() ?? 90,
      components: components,
      active: map['active'] as bool? ?? true,
    );
  }
}
