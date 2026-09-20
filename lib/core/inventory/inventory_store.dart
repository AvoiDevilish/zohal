import '../storage/local_store.dart';
import 'inventory_movement.dart';

class InventoryStore {
  InventoryStore._();

  static final InventoryStore instance = InventoryStore._();

  static const String _storageKey = 'inventory_movements';

  Future<List<InventoryMovement>> getMovements() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    return rows.map(InventoryMovement.fromMap).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addMovement(InventoryMovement movement) async {
    await addMovements([movement]);
  }

  Future<void> addMovements(List<InventoryMovement> newMovements) async {
    if (newMovements.isEmpty) {
      return;
    }

    final movements = await getMovements();
    movements.addAll(newMovements);

    await LocalStore.instance.writeList(
      _storageKey,
      movements.map((item) => item.toMap()).toList(),
    );
  }

  Future<double> getStock(String itemId) async {
    final movements = await getMovements();

    return movements
        .where((movement) => movement.itemId == itemId)
        .fold<double>(0, (total, movement) => total + movement.signedQuantity);
  }

  Future<Map<String, double>> getAllStocks() async {
    final movements = await getMovements();

    final stocks = <String, double>{};

    for (final movement in movements) {
      stocks.update(
        movement.itemId,
        (current) => current + movement.signedQuantity,
        ifAbsent: () => movement.signedQuantity,
      );
    }

    return stocks;
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
