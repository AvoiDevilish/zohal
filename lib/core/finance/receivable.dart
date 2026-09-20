enum ReceivableStatus { open, partiallyPaid, paid, cancelled }

extension ReceivableStatusX on ReceivableStatus {
  String get key {
    switch (this) {
      case ReceivableStatus.open:
        return 'open';
      case ReceivableStatus.partiallyPaid:
        return 'partiallyPaid';
      case ReceivableStatus.paid:
        return 'paid';
      case ReceivableStatus.cancelled:
        return 'cancelled';
    }
  }

  String get title {
    switch (this) {
      case ReceivableStatus.open:
        return 'باز';
      case ReceivableStatus.partiallyPaid:
        return 'بخشی پرداخت شده';
      case ReceivableStatus.paid:
        return 'تسویه شده';
      case ReceivableStatus.cancelled:
        return 'لغو شده';
    }
  }

  static ReceivableStatus fromKey(String key) {
    return ReceivableStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => ReceivableStatus.open,
    );
  }
}

class Receivable {
  final String id;
  final String saleId;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final ReceivableStatus status;
  final DateTime createdAt;
  final String? note;

  const Receivable({
    required this.id,
    required this.saleId,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    this.paidAmount = 0,
    this.status = ReceivableStatus.open,
    required this.createdAt,
    this.note,
  });

  double get remainingAmount {
    final remaining = totalAmount - paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  Receivable copyWith({
    String? id,
    String? saleId,
    String? customerId,
    String? customerName,
    double? totalAmount,
    double? paidAmount,
    ReceivableStatus? status,
    DateTime? createdAt,
    String? note,
  }) {
    return Receivable(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'customerId': customerId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'status': status.key,
      'createdAt': createdAt.toIso8601String(),
      'note': note,
    };
  }

  factory Receivable.fromMap(Map<String, dynamic> map) {
    return Receivable(
      id: map['id'] as String,
      saleId: map['saleId'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0,
      status: ReceivableStatusX.fromKey(map['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(map['createdAt'] as String),
      note: map['note'] as String?,
    );
  }
}
