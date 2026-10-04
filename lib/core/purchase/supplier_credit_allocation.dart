class SupplierCreditAllocation {
  const SupplierCreditAllocation({
    required this.id,
    required this.purchaseId,
    required this.supplierId,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String purchaseId;
  final String supplierId;
  final int amount;
  final DateTime createdAt;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'purchaseId': purchaseId,
    'supplierId': supplierId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory SupplierCreditAllocation.fromMap(Map<String, dynamic> map) =>
      SupplierCreditAllocation(
        id: map['id'] as String,
        purchaseId: map['purchaseId'] as String,
        supplierId: map['supplierId'] as String,
        amount: (map['amount'] as num).toInt(),
        createdAt: DateTime.parse(map['createdAt'] as String),
        note: map['note'] as String?,
      );
}
