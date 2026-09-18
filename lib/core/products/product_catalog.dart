import 'product_variant.dart';

class ProductCatalog {
  static const String baseProductId = 'energy-bar';

  static const List<int> weights = [
    100,
    500,
    1000,
  ];

  static const List<ProductFlavor> flavors = [
    ProductFlavor.ginger,
    ProductFlavor.chickpeaFlour,
    ProductFlavor.cornStarch,
  ];

  static List<ProductVariant> buildDefaultVariants() {
    final variants = <ProductVariant>[];

    for (final weight in weights) {
      for (final flavor in flavors) {
        final weightKey = '${weight}g';
        final flavorKey = flavor.key;

        variants.add(
          ProductVariant(
            id: '$baseProductId-$weightKey-$flavorKey',
            baseProductId: baseProductId,
            name: 'انرژی بار $weight گرم ${flavor.title}',
            weightGrams: weight,
            flavor: flavor,
            sku: 'ZOH-$weightKey-${flavorKey.toUpperCase()}',
          ),
        );
      }
    }

    return List.unmodifiable(variants);
  }

  static ProductVariant findById(String id) {
    return buildDefaultVariants().firstWhere(
      (item) => item.id == id,
      orElse: () => throw StateError(
        'محصول با شناسه $id پیدا نشد.',
      ),
    );
  }
}
