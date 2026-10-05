import '../products/product_catalog.dart';
import '../products/product_variant.dart';
import 'packaging_rule.dart';
import 'recipe.dart';
import 'recipe_component.dart';

class RecipeCatalog {
  const RecipeCatalog._();

  static const String dateMaterialId = 'raw_date_khesht';
  static const String dateMaterialName = 'خرما خشت';
  static const String datePitMaterialId = 'raw_date_pit';
  static const String datePitMaterialName = 'هسته خرما';
  static const String sesameMaterialId = 'raw_sesame';
  static const String sesameMaterialName = 'کنجد';

  static const List<String> defaultNutIds = [
    'raw_walnut_iranian',
    'raw_almond',
    'raw_peanut',
  ];

  static const List<String> defaultNutNames = [
    'گردو ایرانی',
    'بادام درختی',
    'بادام زمینی',
  ];

  static Recipe buildRecipeFor(ProductVariant product) => _buildRecipe(product);

  static List<Recipe> buildDefaultRecipes() {
    return ProductCatalog.buildDefaultVariants()
        .map(_buildRecipe)
        .toList(growable: false);
  }

  static Recipe findByProductVariantId(String productVariantId) {
    return buildDefaultRecipes().firstWhere(
      (recipe) => recipe.productVariantId == productVariantId,
      orElse: () => throw StateError(
        'فرمول تولید برای محصول $productVariantId تعریف نشده است.',
      ),
    );
  }

  static List<PackagingRule> packagingRulesFor(String productVariantId) {
    final product = ProductCatalog.findById(productVariantId);
    return packagingRulesForProduct(product);
  }

  static List<PackagingRule> packagingRulesForProduct(ProductVariant product) {

    final containerId = switch (product.weightGrams) {
      100 => 'pack_container_100g',
      400 => 'pack_container_400g',
      500 => 'pack_container_500g',
      1000 => 'pack_container_1kg',
      _ => throw StateError(
          'قانون بسته‌بندی برای وزن ${product.weightGrams} گرم تعریف نشده است.',
        ),
    };

    final containerName = switch (product.weightGrams) {
      100 => 'ظرف ۱۰۰ گرمی',
      400 => 'ظرف ۴۰۰ گرمی',
      500 => 'ظرف ۵۰۰ گرمی',
      1000 => 'ظرف یک کیلویی',
      _ => throw StateError('بسته‌بندی نامعتبر است.'),
    };

    return [
      PackagingRule(
        productVariantId: product.id,
        materialId: containerId,
        materialName: containerName,
        quantityPerUnit: 1,
        unit: 'عدد',
      ),
      PackagingRule(
        productVariantId: product.id,
        materialId: 'pack_label',
        materialName: 'لیبل',
        quantityPerUnit: 1,
        unit: 'عدد',
      ),
    ];
  }

  static String flavorMaterialId(ProductFlavor flavor) {
    return switch (flavor) {
      ProductFlavor.ginger => 'raw_ground_ginger',
      ProductFlavor.chickpeaFlour => 'raw_chickpea_flour',
      ProductFlavor.cornStarch => 'raw_food_starch',
    };
  }

  static String flavorMaterialName(ProductFlavor flavor) {
    return switch (flavor) {
      ProductFlavor.ginger => 'پودر زنجبیل',
      ProductFlavor.chickpeaFlour => 'آرد نخودچی',
      ProductFlavor.cornStarch => 'پودر نشاسته',
    };
  }

  static Recipe _buildRecipe(ProductVariant product) {
    final flavorId = flavorMaterialId(product.flavor);
    final flavorName = flavorMaterialName(product.flavor);

    return Recipe(
      id: 'recipe-${product.id}',
      productVariantId: product.id,
      name: 'فرمول پایه ${product.name}',
      version: 1,
      components: [
        const RecipeComponent(
          materialId: dateMaterialId,
          materialName: dateMaterialName,
          type: RecipeComponentType.date,
          percentage: 70,
        ),
        for (var index = 0; index < defaultNutIds.length; index++)
          RecipeComponent(
            materialId: defaultNutIds[index],
            materialName: defaultNutNames[index],
            type: RecipeComponentType.nut,
            percentage: 100 / 3,
          ),
        const RecipeComponent(
          materialId: sesameMaterialId,
          materialName: sesameMaterialName,
          type: RecipeComponentType.sesame,
          percentage: 3,
        ),
        RecipeComponent(
          materialId: flavorId,
          materialName: flavorName,
          type: RecipeComponentType.flavoring,
          percentage: 0.5,
        ),
        ...packagingRulesForProduct(product).map(
          (rule) => RecipeComponent(
            materialId: rule.materialId,
            materialName: rule.materialName,
            type: RecipeComponentType.packaging,
            quantityPerUnit: rule.quantityPerUnit,
          ),
        ),
      ],
    );
  }
}
