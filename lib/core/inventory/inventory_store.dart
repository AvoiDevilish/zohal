import '../storage/local_store.dart';
import 'inventory_movement.dart';
import 'inventory_reservation.dart';

class InventoryStore {
  InventoryStore._();

  static final InventoryStore instance = InventoryStore._();

  static const String _storageKey = 'inventory_movements';
  static const String _reservationStorageKey = 'inventory_reservations';

  Future<List<InventoryMovement>> getMovements() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    return rows.map(InventoryMovement.fromMap).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addMovement(InventoryMovement movement) async {
    await addMovements([movement]);
  }

  Future<void> addMovements(List<InventoryMovement> newMovements) async {
    if (newMovements.isEmpty) return;

    final movements = await getMovements();
    final projected = <String, double>{};

    for (final movement in movements) {
      projected.update(
        movement.itemId,
        (current) => current + movement.signedQuantity,
        ifAbsent: () => movement.signedQuantity,
      );
    }

    for (final movement in newMovements) {
      final next = (projected[movement.itemId] ?? 0) + movement.signedQuantity;
      if (next < -0.000001) {
        throw StateError(
          'موجودی قلم ' + movement.itemName + ' برای این عملیات کافی نیست.',
        );
      }
      projected[movement.itemId] = next;
    }

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

  Future<List<InventoryReservation>> getReservations({
    String? itemId,
    bool activeOnly = false,
  }) async {
    final rows = await LocalStore.instance.readList(_reservationStorageKey);
    var reservations = rows.map(InventoryReservation.fromMap).toList();

    if (itemId != null) {
      reservations = reservations
          .where((reservation) => reservation.itemId == itemId)
          .toList();
    }
    if (activeOnly) {
      reservations = reservations
          .where((reservation) => reservation.isActive)
          .toList();
    }

    reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return reservations;
  }

  Future<double> getReservedStock(String itemId) async {
    final reservations = await getReservations(
      itemId: itemId,
      activeOnly: true,
    );
    return reservations.fold<double>(
      0,
      (total, item) => total + item.quantity,
    );
  }

  Future<double> getAvailableStock(String itemId) async {
    final onHand = await getStock(itemId);
    final reserved = await getReservedStock(itemId);
    return onHand - reserved;
  }

  Future<void> reserve(InventoryReservation reservation) async {
    if (reservation.quantity <= 0) {
      throw ArgumentError.value(
        reservation.quantity,
        'quantity',
        'باید بیشتر از صفر باشد.',
      );
    }

    final available = await getAvailableStock(reservation.itemId);
    if (reservation.quantity > available + 0.000001) {
      throw StateError('موجودی آزاد برای رزرو کافی نیست.');
    }

    final reservations = await getReservations();
    reservations.add(reservation);

    await LocalStore.instance.writeList(
      _reservationStorageKey,
      reservations.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> releaseReservation(String reservationId) async {
    final reservations = await getReservations();
    final index = reservations.indexWhere((item) => item.id == reservationId);

    if (index == -1) {
      throw StateError('رزرو موردنظر پیدا نشد.');
    }

    if (!reservations[index].isActive) return;

    reservations[index] = reservations[index].release(DateTime.now());

    await LocalStore.instance.writeList(
      _reservationStorageKey,
      reservations.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
    await LocalStore.instance.remove(_reservationStorageKey);
  }
}
