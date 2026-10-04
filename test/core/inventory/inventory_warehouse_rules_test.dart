import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_reservation.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';

void main() {
  group('InventoryStore warehouse rules', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InventoryStore.instance.clear();
    });

    test('does not allow stock to go below zero', () async {
      final store = InventoryStore.instance;

      await store.addMovement(
        InventoryMovement(
          id: 'purchase-1',
          itemId: 'date',
          itemName: 'خرما',
          itemType: 'raw_material',
          quantity: 10,
          unit: 'kg',
          movementType: InventoryMovementType.purchase,
          timestamp: DateTime(2026, 10, 4),
        ),
      );

      expect(
        () => store.addMovement(
          InventoryMovement(
            id: 'sale-1',
            itemId: 'date',
            itemName: 'خرما',
            itemType: 'raw_material',
            quantity: 11,
            unit: 'kg',
            movementType: InventoryMovementType.sale,
            timestamp: DateTime(2026, 10, 4, 1),
          ),
        ),
        throwsA(isA<StateError>()),
      );

      expect(await store.getStock('date'), 10);
    });

    test('reserved stock is not available stock', () async {
      final store = InventoryStore.instance;

      await store.addMovement(
        InventoryMovement(
          id: 'purchase-1',
          itemId: 'box',
          itemName: 'ظرف ۱۰۰ گرمی',
          itemType: 'packaging',
          quantity: 20,
          unit: 'count',
          movementType: InventoryMovementType.purchase,
          timestamp: DateTime(2026, 10, 4),
        ),
      );

      await store.reserve(
        InventoryReservation(
          id: 'reservation-1',
          itemId: 'box',
          quantity: 8,
          referenceId: 'order-1',
          createdAt: DateTime(2026, 10, 4),
        ),
      );

      expect(await store.getStock('box'), 20);
      expect(await store.getReservedStock('box'), 8);
      expect(await store.getAvailableStock('box'), 12);
    });

    test('cannot reserve more than available stock', () async {
      final store = InventoryStore.instance;

      await store.addMovement(
        InventoryMovement(
          id: 'purchase-1',
          itemId: 'product',
          itemName: 'محصول',
          itemType: 'product',
          quantity: 5,
          unit: 'kg',
          movementType: InventoryMovementType.purchase,
          timestamp: DateTime(2026, 10, 4),
        ),
      );

      await store.reserve(
        InventoryReservation(
          id: 'reservation-1',
          itemId: 'product',
          quantity: 4,
          referenceId: 'order-1',
          createdAt: DateTime(2026, 10, 4),
        ),
      );

      expect(
        () => store.reserve(
          InventoryReservation(
            id: 'reservation-2',
            itemId: 'product',
            quantity: 2,
            referenceId: 'order-2',
            createdAt: DateTime(2026, 10, 4),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
