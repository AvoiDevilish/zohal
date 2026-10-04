class InventoryReservation {
  const InventoryReservation({
    required this.id,
    required this.itemId,
    required this.quantity,
    required this.referenceId,
    required this.createdAt,
    this.note,
    this.releasedAt,
  });

  final String id;
  final String itemId;
  final double quantity;
  final String referenceId;
  final DateTime createdAt;
  final String? note;
  final DateTime? releasedAt;

  bool get isActive => releasedAt == null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'itemId': itemId,
    'quantity': quantity,
    'referenceId': referenceId,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
    'releasedAt': releasedAt?.toIso8601String(),
  };

  factory InventoryReservation.fromMap(Map<String, dynamic> map) {
    return InventoryReservation(
      id: map['id'] as String,
      itemId: map['itemId'] as String,
      quantity: (map['quantity'] as num).toDouble(),
      referenceId: map['referenceId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
      releasedAt: map['releasedAt'] == null
          ? null
          : DateTime.parse(map['releasedAt'] as String),
    );
  }

  InventoryReservation release(DateTime at) => InventoryReservation(
    id: id,
    itemId: itemId,
    quantity: quantity,
    referenceId: referenceId,
    createdAt: createdAt,
    note: note,
    releasedAt: at,
  );
}
