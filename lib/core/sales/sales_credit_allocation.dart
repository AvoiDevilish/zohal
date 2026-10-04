class SalesCreditAllocation {
  const SalesCreditAllocation({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String orderId;
  final String customerId;
  final int amount;
  final DateTime createdAt;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'customerId': customerId,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory SalesCreditAllocation.fromMap(Map<String, dynamic> map) {
    return SalesCreditAllocation(
      id: map['id'] as String,
      orderId: map['orderId'] as String,
      customerId: map['customerId'] as String,
      amount: (map['amount'] as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
    );
  }
}
