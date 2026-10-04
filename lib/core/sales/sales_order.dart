enum SalesOrderStatus {
  workshopPending,
  workshopAnalyzing,
  readyForProduction,
  materialsReserved,
  shortage,
  inProduction,
  productionCompleted,
  readyForDelivery,
  partiallyDelivered,
  delivered,
  cancelled,
}

extension SalesOrderStatusExtension on SalesOrderStatus {
  String get key => name;

  String get title => switch (this) {
    SalesOrderStatus.workshopPending => 'در انتظار کارگاه',
    SalesOrderStatus.workshopAnalyzing => 'در حال تحلیل کارگاه',
    SalesOrderStatus.readyForProduction => 'آماده تولید',
    SalesOrderStatus.materialsReserved => 'مواد رزرو شده',
    SalesOrderStatus.shortage => 'دارای کمبود',
    SalesOrderStatus.inProduction => 'در حال تولید',
    SalesOrderStatus.productionCompleted => 'تولید تکمیل شده',
    SalesOrderStatus.readyForDelivery => 'آماده تحویل',
    SalesOrderStatus.partiallyDelivered => 'تحویل جزئی',
    SalesOrderStatus.delivered => 'تحویل کامل',
    SalesOrderStatus.cancelled => 'لغو شده',
  };

  static SalesOrderStatus fromKey(String? key) {
    return SalesOrderStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => SalesOrderStatus.workshopPending,
    );
  }
}

class SalesOrderLine {
  const SalesOrderLine({
    required this.productVariantId,
    required this.productName,
    required this.flavor,
    required this.packageLabel,
    required this.quantity,
    required this.unitSellingPrice,
    required this.lineTotal,
  });

  final String productVariantId;
  final String productName;
  final String flavor;
  final String packageLabel;
  final int quantity;
  final int unitSellingPrice;
  final int lineTotal;

  Map<String, dynamic> toMap() => {
    'productVariantId': productVariantId,
    'productName': productName,
    'flavor': flavor,
    'packageLabel': packageLabel,
    'quantity': quantity,
    'unitSellingPrice': unitSellingPrice,
    'lineTotal': lineTotal,
  };

  factory SalesOrderLine.fromMap(Map<String, dynamic> map) {
    return SalesOrderLine(
      productVariantId: map['productVariantId'] as String,
      productName: map['productName'] as String,
      flavor: map['flavor'] as String,
      packageLabel: map['packageLabel'] as String,
      quantity: (map['quantity'] as num).toInt(),
      unitSellingPrice: (map['unitSellingPrice'] as num).toInt(),
      lineTotal: (map['lineTotal'] as num).toInt(),
    );
  }
}

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.orderDate,
    required this.lines,
    required this.totalAmount,
    this.status = SalesOrderStatus.workshopPending,
  });

  final String id;
  final String customerId;
  final String customerName;
  final DateTime orderDate;
  final List<SalesOrderLine> lines;
  final int totalAmount;
  final SalesOrderStatus status;

  Map<String, dynamic> toMap() => {
    'id': id,
    'customerId': customerId,
    'customerName': customerName,
    'orderDate': orderDate.toIso8601String(),
    'lines': lines.map((line) => line.toMap()).toList(),
    'totalAmount': totalAmount,
    'status': status.key,
  };

  factory SalesOrder.fromMap(Map<String, dynamic> map) {
    return SalesOrder(
      id: map['id'] as String,
      customerId: map['customerId'] as String,
      customerName: map['customerName'] as String,
      orderDate: DateTime.parse(map['orderDate'] as String),
      lines: (map['lines'] as List)
          .whereType<Map>()
          .map((line) => SalesOrderLine.fromMap(Map<String, dynamic>.from(line)))
          .toList(),
      totalAmount: (map['totalAmount'] as num).toInt(),
      status: SalesOrderStatusExtension.fromKey(map['status'] as String?),
    );
  }
}
