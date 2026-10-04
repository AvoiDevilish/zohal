import 'production_calculator.dart';

class ProductionStockCheckItem {
  final String materialId;
  final String materialName;
  final double requiredQuantity;
  final double availableQuantity;
  final double shortageQuantity;
  final String unit;

  const ProductionStockCheckItem({
    required this.materialId,
    required this.materialName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.shortageQuantity,
    required this.unit,
  });

  bool get isSufficient => shortageQuantity <= 0;
}

class ProductionStockCheck {
  final List<ProductionStockCheckItem> items;

  const ProductionStockCheck({
    required this.items,
  });

  bool get canProduce => items.every((item) => item.isSufficient);

  List<ProductionStockCheckItem> get shortages {
    return items.where((item) => !item.isSufficient).toList();
  }

  double get totalShortageQuantity {
    return shortages.fold<double>(
      0,
      (sum, item) => sum + item.shortageQuantity,
    );
  }
}

class ProductionStockChecker {
  const ProductionStockChecker();

  ProductionStockCheck check({
    required ProductionCalculation calculation,
    required Map<String, double> stockByMaterialId,
  }) {
    final items = calculation.requirements.map((requirement) {
      final available =
          stockByMaterialId[requirement.materialId] ?? 0;

      final double shortage =
          requirement.quantity > available
              ? requirement.quantity - available
              : 0.0;

      return ProductionStockCheckItem(
        materialId: requirement.materialId,
        materialName: requirement.materialName,
        requiredQuantity: requirement.quantity,
        availableQuantity: available,
        shortageQuantity: shortage,
        unit: requirement.unit,
      );
    }).toList();

    return ProductionStockCheck(
      items: List.unmodifiable(items),
    );
  }
}
