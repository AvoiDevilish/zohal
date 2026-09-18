enum ProductFlavor {
  ginger,
  chickpeaFlour,
  cornStarch,
}

extension ProductFlavorX on ProductFlavor {
  String get title {
    switch (this) {
      case ProductFlavor.ginger:
        return 'زنجبیلی';
      case ProductFlavor.chickpeaFlour:
        return 'آرد نخودچی';
      case ProductFlavor.cornStarch:
        return 'نشاسته';
    }
  }

  String get key => name;
}

class ProductVariant {
  final String id;
  final String baseProductId;
  final String name;
  final int weightGrams;
  final ProductFlavor flavor;
  final String sku;
  final bool active;

  const ProductVariant({
    required this.id,
    required this.baseProductId,
    required this.name,
    required this.weightGrams,
    required this.flavor,
    required this.sku,
    this.active = true,
  });

  ProductVariant copyWith({
    String? id,
    String? baseProductId,
    String? name,
    int? weightGrams,
    ProductFlavor? flavor,
    String? sku,
    bool? active,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      baseProductId: baseProductId ?? this.baseProductId,
      name: name ?? this.name,
      weightGrams: weightGrams ?? this.weightGrams,
      flavor: flavor ?? this.flavor,
      sku: sku ?? this.sku,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'baseProductId': baseProductId,
      'name': name,
      'weightGrams': weightGrams,
      'flavor': flavor.key,
      'sku': sku,
      'active': active,
    };
  }

  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    final flavorKey = map['flavor'] as String? ?? 'ginger';

    final flavor = ProductFlavor.values.firstWhere(
      (item) => item.name == flavorKey,
      orElse: () => ProductFlavor.ginger,
    );

    return ProductVariant(
      id: map['id'] as String,
      baseProductId: map['baseProductId'] as String,
      name: map['name'] as String,
      weightGrams: (map['weightGrams'] as num).toInt(),
      flavor: flavor,
      sku: map['sku'] as String,
      active: map['active'] as bool? ?? true,
    );
  }
}
