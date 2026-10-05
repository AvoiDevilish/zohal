import '../inventory/inventory_store.dart';
import '../products/product_variant.dart';
import '../sales/sales_order.dart';
import '../sales/product_variant.dart' as sales;
import '../sales/product_variant_store.dart';
import 'nut_allocation.dart';
import 'production_calculator.dart';
import 'production_inventory_checker.dart';
import 'production_requirement.dart';
import 'production_stock_check.dart';
import 'recipe_catalog.dart';

class ProductionOrderLineAnalysis {
  final SalesOrderLine line;
  final ProductionCalculation calculation;
  final ProductionStockCheck stockCheck;

  const ProductionOrderLineAnalysis({
    required this.line,
    required this.calculation,
    required this.stockCheck,
  });
}

class ProductionOrderAnalysis {
  final String orderId;
  final List<ProductionOrderLineAnalysis> lines;
  final ProductionStockCheck stockCheck;
  final List<ProductionByproduct> byproducts;

  const ProductionOrderAnalysis({
    required this.orderId,
    required this.lines,
    required this.stockCheck,
    required this.byproducts,
  });

  bool get canProduce => stockCheck.canProduce;

  List<ProductionStockCheckItem> get shortages => stockCheck.shortages;
}

class ProductionOrderAnalyzer {
  final InventoryStore inventoryStore;

  const ProductionOrderAnalyzer({
    required this.inventoryStore,
  });

  Future<ProductionOrderAnalysis> analyze(SalesOrder order) async {
    if (order.lines.isEmpty) {
      throw StateError('سفارش فاقد ردیف تولید است.');
    }

    final lineAnalyses = <ProductionOrderLineAnalysis>[];

    for (final line in order.lines) {
      final storedProduct =
          await ProductVariantStore.instance.getById(line.productVariantId);
      final product = storedProduct != null
          ? _toProductionProduct(storedProduct)
          : _toProductionProductFromLegacyCatalog(line);

      final recipe = RecipeCatalog.buildRecipeFor(product);

      final calculation = const ProductionCalculator().calculate(
        recipe: recipe,
        units: line.quantity,
        unitWeightGrams: product.weightGrams,
        dateMaterialId: RecipeCatalog.dateMaterialId,
        dateMaterialName: RecipeCatalog.dateMaterialName,
        datePitMaterialId: RecipeCatalog.datePitMaterialId,
        datePitMaterialName: RecipeCatalog.datePitMaterialName,
        nutAllocations: _defaultNutAllocations(),
        sesameMaterialId: RecipeCatalog.sesameMaterialId,
        sesameMaterialName: RecipeCatalog.sesameMaterialName,
        flavorMaterialId: RecipeCatalog.flavorMaterialId(product.flavor),
        flavorMaterialName: RecipeCatalog.flavorMaterialName(product.flavor),
        packagingRules: RecipeCatalog.packagingRulesFor(product.id),
      );

      final stockCheck = await ProductionInventoryChecker(
        inventoryStore: inventoryStore,
      ).check(
        calculation,
        reservationReferenceId: order.id,
      );

      lineAnalyses.add(
        ProductionOrderLineAnalysis(
          line: line,
          calculation: calculation,
          stockCheck: stockCheck,
        ),
      );
    }

    final aggregateCalculation = _aggregate(lineAnalyses);
    final aggregateStockCheck = await ProductionInventoryChecker(
      inventoryStore: inventoryStore,
    ).check(
      aggregateCalculation,
      reservationReferenceId: order.id,
    );

    return ProductionOrderAnalysis(
      orderId: order.id,
      lines: List.unmodifiable(lineAnalyses),
      stockCheck: aggregateStockCheck,
      byproducts: _aggregateByproducts(lineAnalyses),
    );
  }

  ProductVariant _toProductionProductFromLegacyCatalog(SalesOrderLine line) {
    final flavor = switch (line.flavor) {
      'زنجبیلی' || 'زنجبیل' => ProductFlavor.ginger,
      'آرد نخودچی' => ProductFlavor.chickpeaFlour,
      'ساده (پودر نشاسته ذرت)' || 'نشاسته' || 'نشاسته ذرت' =>
        ProductFlavor.cornStarch,
      _ => ProductFlavor.ginger,
    };

    final weight =
        RegExp(r'(\d+)').firstMatch(line.packageLabel)?.group(1);
    final weightGrams = int.tryParse(weight ?? '') ?? 100;

    return ProductVariant(
      id: line.productVariantId,
      baseProductId: 'legacy-' + line.productVariantId,
      name: line.productName,
      weightGrams: weightGrams,
      flavor: flavor,
      sku: line.productVariantId,
    );
  }

  ProductVariant _toProductionProduct(sales.ProductVariant product) {
    final flavorText = product.flavor.trim();
    final flavor = switch (flavorText) {
      'زنجبیل' => ProductFlavor.ginger,
      'آرد نخودچی' => ProductFlavor.chickpeaFlour,
      'ساده (پودر نشاسته ذرت)' || 'نشاسته' => ProductFlavor.cornStarch,
      _ => throw StateError(
          'برای طعم/مدل «' + flavorText + '» فرمول تولید تعریف نشده است. '
          'یکی از طعم‌های پشتیبانی‌شده را انتخاب کنید.',
        ),
    };

    return ProductVariant(
      id: product.id,
      baseProductId: 'stored-product',
      name: product.displayName,
      weightGrams: product.packageGrams,
      flavor: flavor,
      sku: product.id,
    );
  }

  ProductionCalculation _aggregate(
    List<ProductionOrderLineAnalysis> lines,
  ) {
    final requirements = <String, ProductionRequirement>{};

    for (final line in lines) {
      for (final requirement in line.calculation.requirements) {
        final current = requirements[requirement.materialId];

        if (current == null) {
          requirements[requirement.materialId] = requirement;
        } else {
          requirements[requirement.materialId] = ProductionRequirement(
            materialId: current.materialId,
            materialName: current.materialName,
            quantity: current.quantity + requirement.quantity,
            unit: current.unit,
            type: current.type,
          );
        }
      }
    }

    final totalUnits = lines.fold<int>(
      0,
      (sum, line) => sum + line.calculation.units,
    );

    final totalWeight = lines.fold<double>(
      0,
      (sum, line) => sum + line.calculation.totalWeightGrams,
    );

    return ProductionCalculation(
      units: totalUnits,
      unitWeightGrams: 0,
      totalWeightGrams: totalWeight,
      requirements: List.unmodifiable(requirements.values),
    );
  }

  List<ProductionByproduct> _aggregateByproducts(
    List<ProductionOrderLineAnalysis> lines,
  ) {
    final byproducts = <String, ProductionByproduct>{};

    for (final line in lines) {
      for (final byproduct in line.calculation.byproducts) {
        final current = byproducts[byproduct.itemId];

        if (current == null) {
          byproducts[byproduct.itemId] = byproduct;
        } else {
          byproducts[byproduct.itemId] = ProductionByproduct(
            itemId: current.itemId,
            itemName: current.itemName,
            itemType: current.itemType,
            quantity: current.quantity + byproduct.quantity,
            unit: current.unit,
          );
        }
      }
    }

    return List.unmodifiable(byproducts.values);
  }

  List<NutAllocation> _defaultNutAllocations() {
    return List.unmodifiable(
      List.generate(
        RecipeCatalog.defaultNutIds.length,
        (index) => NutAllocation(
          materialId: RecipeCatalog.defaultNutIds[index],
          materialName: RecipeCatalog.defaultNutNames[index],
          percentage: 100 / 3,
        ),
      ),
    );
  }
}
