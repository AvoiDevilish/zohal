import '../inventory/inventory_store.dart';
import 'production_calculator.dart';
import 'production_stock_check.dart';

class ProductionInventoryChecker {
  final InventoryStore inventoryStore;

  const ProductionInventoryChecker({
    required this.inventoryStore,
  });

  Future<ProductionStockCheck> check(
    ProductionCalculation calculation, {
    String? reservationReferenceId,
  }) async {
    final items = <ProductionStockCheckItem>[];

    for (final requirement in calculation.requirements) {
      var available = await inventoryStore.getAvailableStock(
        requirement.materialId,
      );

      if (reservationReferenceId != null) {
        final ownReservations = await inventoryStore.getReservations(
          itemId: requirement.materialId,
          activeOnly: true,
        );
        available += ownReservations
            .where(
              (reservation) =>
                  reservation.referenceId == reservationReferenceId,
            )
            .fold<double>(
              0,
              (sum, reservation) => sum + reservation.quantity,
            );
      }

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
