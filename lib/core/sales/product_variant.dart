import '../inventory/inventory_item.dart';

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.productName,
    required this.flavor,
    required this.packageLabel,
    required this.packageGrams,
    required this.currentSellingPrice,
    this.isActive = true,
    this.nutrition,
  });

  final String id;
  final String productName;
  final String flavor;
  final String packageLabel;
  final int packageGrams;
  final int currentSellingPrice;
  final bool isActive;
  final NutritionProfile? nutrition;

  String get displayName => '$productName - $flavor - $packageLabel';

  ProductVariant copyWith({
    String? id,
    String? productName,
    String? flavor,
    String? packageLabel,
    int? packageGrams,
    int? currentSellingPrice,
    bool? isActive,
    NutritionProfile? nutrition,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      flavor: flavor ?? this.flavor,
      packageLabel: packageLabel ?? this.packageLabel,
      packageGrams: packageGrams ?? this.packageGrams,
      currentSellingPrice: currentSellingPrice ?? this.currentSellingPrice,
      isActive: isActive ?? this.isActive,
      nutrition: nutrition ?? this.nutrition,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productName': productName,
    'flavor': flavor,
    'packageLabel': packageLabel,
    'packageGrams': packageGrams,
    'currentSellingPrice': currentSellingPrice,
    'isActive': isActive,
    'nutrition': nutrition?.toMap(),
  };

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as String,
      productName: map['productName'] as String,
      flavor: map['flavor'] as String,
      packageLabel: map['packageLabel'] as String,
      packageGrams: (map['packageGrams'] as num).toInt(),
      currentSellingPrice: (map['currentSellingPrice'] as num).toInt(),
      isActive: map['isActive'] as bool? ?? true,
      nutrition: map['nutrition'] is Map
          ? NutritionProfile.fromMap(Map<String, dynamic>.from(map['nutrition'] as Map))
          : null,
    );
  }
}
