import '../inventory/inventory_store.dart';
import 'production_calculator.dart';
import 'production_stock_check.dart';

class ProductionInventoryChecker {
  final InventoryStore inventoryStore;

  const ProductionInventoryChecker({
    required this.inventoryStore,
  });

  Future<ProductionStockCheck> check(
    ProductionCalculation calculation,
  ) async {
    final items = <ProductionStockCheckItem>[];

    for (final requirement in calculation.requirements) {
      final available = await inventoryStore.getAvailableStock(
        requirement.materialId,
      );
      final shortage = requirement.quantity > available
          ? requirement.quantity - available
          : 0.0;

      items.add(
        ProductionStockCheckItem(
          materialId: requirement.materialId,
          materialName: requirement.materialName,
          requiredQuantity: requirement.quantity,
          availableQuantity: available,
          shortageQuantity: shortage,
        ),
      );
    }

    return ProductionStockCheck(
      items: List.unmodifiable(items),
    );
  }
}
