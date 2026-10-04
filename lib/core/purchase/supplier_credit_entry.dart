class SupplierCreditEntry {
  const SupplierCreditEntry({
    required this.id,
    required this.supplierId,
    required this.amount,
    required this.createdAt,
    required this.referenceId,
    this.note,
  });

  final String id;
  final String supplierId;
  final int amount;
  final DateTime createdAt;
  final String referenceId;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'referenceId': referenceId,
    'note': note,
  };

  factory SupplierCreditEntry.fromMap(Map<String, dynamic> map) =>
      SupplierCreditEntry(
        id: map['id'] as String,
        supplierId: map['supplierId'] as String,
        amount: (map['amount'] as num).toInt(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        referenceId: map['referenceId'] as String,
        note: map['note'] as String?,
      );
}
