import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';

void main() {
  group('InventoryStore', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InventoryStore.instance.clear();
    });

    test('calculates stock from inventory movements', () async {
      final store = InventoryStore.instance;

      final now = DateTime(2026, 9, 17);

      await store.addMovement(
        InventoryMovement(
          id: 'movement-001',
          itemId: 'material-date',
          itemName: 'خرما کبکاب برازجان',
          itemType: 'raw_material',
          quantity: 20,
          unit: 'kg',
          movementType: InventoryMovementType.purchase,
          timestamp: now,
          unitCost: 185000,
        ),
      );

      await store.addMovement(
        InventoryMovement(
          id: 'movement-002',
          itemId: 'material-date',
          itemName: 'خرما کبکاب برازجان',
          itemType: 'raw_material',
          quantity: 5,
          unit: 'kg',
          movementType: InventoryMovementType.productionConsumption,
          timestamp: now.add(const Duration(minutes: 10)),
        ),
      );

      await store.addMovement(
        InventoryMovement(
          id: 'movement-003',
          itemId: 'material-date',
          itemName: 'خرما کبکاب برازجان',
          itemType: 'raw_material',
          quantity: 1,
          unit: 'kg',
          movementType: InventoryMovementType.waste,
          timestamp: now.add(const Duration(minutes: 20)),
        ),
      );

      final stock = await store.getStock('material-date');

      expect(stock, 14);
    });

    test('persists and reloads movement history', () async {
      final store = InventoryStore.instance;

      final movement = InventoryMovement(
        id: 'movement-001',
        itemId: 'box-001',
        itemName: 'جعبه محصول',
        itemType: 'packaging',
        quantity: 100,
        unit: 'count',
        movementType: InventoryMovementType.purchase,
        timestamp: DateTime(2026, 9, 17),
        unitCost: 12500,
      );

      await store.addMovement(movement);

      final movements = await store.getMovements();

      expect(movements.length, 1);
      expect(movements.first.id, 'movement-001');
      expect(movements.first.itemName, 'جعبه محصول');
      expect(movements.first.quantity, 100);
      expect(
        movements.first.movementType,
        InventoryMovementType.purchase,
      );
    });
  });
}
