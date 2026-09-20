import 'sale_item.dart';

class Sale {
  final String id;
  final String? customerId;
  final String? customerName;
  final List<SaleItem> items;
  final DateTime saleDate;
  final String? note;

  const Sale({
    required this.id,
    this.customerId,
    this.customerName,
    required this.items,
    required this.saleDate,
    this.note,
  });

  double get totalAmount {
    return items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Sale copyWith({
    String? id,
    String? customerId,
    String? customerName,
    List<SaleItem>? items,
    DateTime? saleDate,
    String? note,
  }) {
    return Sale(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      items: items ?? this.items,
      saleDate: saleDate ?? this.saleDate,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'items': items.map((item) => item.toMap()).toList(),
      'saleDate': saleDate.toIso8601String(),
      'note': note,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      customerId: map['customerId'] as String?,
      customerName: map['customerName'] as String?,
      items: (map['items'] as List<dynamic>)
          .map(
            (item) => SaleItem.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      saleDate: DateTime.parse(map['saleDate'] as String),
      note: map['note'] as String?,
    );
  }
}
