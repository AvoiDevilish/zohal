class SupplierCreditSettlement {
  const SupplierCreditSettlement({
    required this.id,
    required this.supplierId,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String supplierId;
  final int amount;
  final DateTime createdAt;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'supplierId': supplierId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory SupplierCreditSettlement.fromMap(Map<String, dynamic> map) =>
      SupplierCreditSettlement(
        id: map['id'] as String,
        supplierId: map['supplierId'] as String,
        amount: (map['amount'] as num).toInt(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        note: map['note'] as String?,
      );
}
