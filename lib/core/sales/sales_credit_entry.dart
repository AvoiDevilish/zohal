class SalesCreditEntry {
  const SalesCreditEntry({
    required this.id,
    required this.customerId,
    required this.amount,
    required this.createdAt,
    required this.referenceId,
    this.note,
  });

  final String id;
  final String customerId;
  final int amount;
  final DateTime createdAt;
  final String referenceId;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'referenceId': referenceId,
    'note': note,
  };

  factory SalesCreditEntry.fromMap(Map<String, dynamic> map) => SalesCreditEntry(
    id: map['id'] as String,
    customerId: map['customerId'] as String,
    amount: (map['amount'] as num).toInt(),
    createdAt: DateTime.parse(map['createdAt'] as String),
    referenceId: map['referenceId'] as String,
    note: map['note'] as String?,
  );
}
