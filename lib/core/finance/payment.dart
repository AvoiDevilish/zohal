enum PaymentMethod { cash, card, bankTransfer, other }

extension PaymentMethodX on PaymentMethod {
  String get key {
    switch (this) {
      case PaymentMethod.cash:
        return 'cash';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.bankTransfer:
        return 'bankTransfer';
      case PaymentMethod.other:
        return 'other';
    }
  }

  String get title {
    switch (this) {
      case PaymentMethod.cash:
        return 'نقدی';
      case PaymentMethod.card:
        return 'کارت';
      case PaymentMethod.bankTransfer:
        return 'انتقال بانکی';
      case PaymentMethod.other:
        return 'سایر';
    }
  }

  static PaymentMethod fromKey(String key) {
    return PaymentMethod.values.firstWhere(
      (method) => method.key == key,
      orElse: () => PaymentMethod.other,
    );
  }
}

class Payment {
  final String id;
  final String receivableId;
  final String customerId;
  final String customerName;
  final double amount;
  final PaymentMethod method;
  final DateTime paymentDate;
  final String? note;

  const Payment({
    required this.id,
    required this.receivableId,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'receivableId': receivableId,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'method': method.key,
      'paymentDate': paymentDate.toIso8601String(),
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      receivableId: map['receivableId'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: PaymentMethodX.fromKey(map['method'] as String? ?? 'other'),
      paymentDate: DateTime.parse(map['paymentDate'] as String),
      note: map['note'] as String?,
    );
  }
}
