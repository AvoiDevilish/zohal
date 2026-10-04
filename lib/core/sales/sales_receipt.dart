class SalesReceipt {
  const SalesReceipt({
    required this.id,
    required this.orderId,
    required this.customerId,
    required this.customerName,
    required this.payerId,
    required this.payerName,
    required this.amount,
    required this.createdAt,
    this.note,
  });

  final String id;
  final String orderId;
  final String customerId;
  final String customerName;
  final String payerId;
  final String payerName;
  final int amount;
  final DateTime createdAt;
  final String? note;

  Map<String, dynamic> toMap() => {
    'id': id,
    'orderId': orderId,
    'customerId': customerId,
    'customerName': customerName,
    'payerId': payerId,
    'payerName': payerName,
    'amount': amount,
    'createdAt': createdAt.toIso8601String(),
    'note': note,
  };

  factory SalesReceipt.fromMap(Map<String, dynamic> map) => SalesReceipt(
    id: map['id'] as String,
    orderId: map['orderId'] as String,
    customerId: map['customerId'] as String,
    customerName: map['customerName'] as String,
    payerId: map['payerId'] as String,
    payerName: map['payerName'] as String,
    amount: (map['amount'] as num).toInt(),
    createdAt: DateTime.parse(map['createdAt'] as String),
    note: map['note'] as String?,
  );
}
