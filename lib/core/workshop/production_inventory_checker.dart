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
    final stockByMaterialId =
        await inventoryStore.getAllStocks();

    return const ProductionStockChecker().check(
      calculation: calculation,
      stockByMaterialId: stockByMaterialId,
    );
  }
}
