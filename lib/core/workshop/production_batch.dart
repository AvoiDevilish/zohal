enum ProductionBatchStatus { draft, ready, inProduction, completed, cancelled }

extension ProductionBatchStatusX on ProductionBatchStatus {
  String get key {
    switch (this) {
      case ProductionBatchStatus.draft:
        return 'draft';
      case ProductionBatchStatus.ready:
        return 'ready';
      case ProductionBatchStatus.inProduction:
        return 'inProduction';
      case ProductionBatchStatus.completed:
        return 'completed';
      case ProductionBatchStatus.cancelled:
        return 'cancelled';
    }
  }

  String get title {
    switch (this) {
      case ProductionBatchStatus.draft:
        return 'پیش‌نویس';
      case ProductionBatchStatus.ready:
        return 'آماده تولید';
      case ProductionBatchStatus.inProduction:
        return 'در حال تولید';
      case ProductionBatchStatus.completed:
        return 'تکمیل شده';
      case ProductionBatchStatus.cancelled:
        return 'لغو شده';
    }
  }

  static ProductionBatchStatus fromKey(String value) {
    return ProductionBatchStatus.values.firstWhere(
      (item) => item.key == value,
      orElse: () => ProductionBatchStatus.draft,
    );
  }
}

class ProductionBatch {
  final String id;
  final String productVariantId;
  final String productName;
  final int units;
  final int unitWeightGrams;
  final String recipeId;
  final int recipeVersion;
  final DateTime createdAt;
  final ProductionBatchStatus status;
  final String? note;
  final String? cancellationReason;
  final String? lotNumber;
  final DateTime? expiryDate;
  final List<String> sourceLotNumbers;

  const ProductionBatch({
    required this.id,
    required this.productVariantId,
    required this.productName,
    required this.units,
    required this.unitWeightGrams,
    required this.recipeId,
    required this.recipeVersion,
    required this.createdAt,
    this.status = ProductionBatchStatus.draft,
    this.note,
    this.cancellationReason,
    this.lotNumber,
    this.expiryDate,
    this.sourceLotNumbers = const [],
  });

  int get totalWeightGrams => units * unitWeightGrams;

  ProductionBatch copyWith({
    String? id,
    String? productVariantId,
    String? productName,
    int? units,
    int? unitWeightGrams,
    String? recipeId,
    int? recipeVersion,
    DateTime? createdAt,
    ProductionBatchStatus? status,
    String? note,
    String? cancellationReason,
    String? lotNumber,
    DateTime? expiryDate,
    List<String>? sourceLotNumbers,
    bool clearNote = false,
    bool clearCancellationReason = false,
  }) {
    return ProductionBatch(
      id: id ?? this.id,
      productVariantId: productVariantId ?? this.productVariantId,
      productName: productName ?? this.productName,
      units: units ?? this.units,
      unitWeightGrams: unitWeightGrams ?? this.unitWeightGrams,
      recipeId: recipeId ?? this.recipeId,
      recipeVersion: recipeVersion ?? this.recipeVersion,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      note: clearNote ? null : (note ?? this.note),
      cancellationReason: clearCancellationReason
          ? null
          : (cancellationReason ?? this.cancellationReason),
      lotNumber: lotNumber ?? this.lotNumber,
      expiryDate: expiryDate ?? this.expiryDate,
      sourceLotNumbers: sourceLotNumbers ?? this.sourceLotNumbers,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productVariantId': productVariantId,
      'productName': productName,
      'units': units,
      'unitWeightGrams': unitWeightGrams,
      'recipeId': recipeId,
      'recipeVersion': recipeVersion,
      'createdAt': createdAt.toIso8601String(),
      'status': status.key,
      'note': note,
      'cancellationReason': cancellationReason,
      'lotNumber': lotNumber,
      'expiryDate': expiryDate?.toIso8601String(),
      'sourceLotNumbers': sourceLotNumbers,
    };
  }

  factory ProductionBatch.fromMap(Map<String, dynamic> map) {
    return ProductionBatch(
      id: map['id'] as String,
      productVariantId: map['productVariantId'] as String,
      productName: map['productName'] as String,
      units: (map['units'] as num).toInt(),
      unitWeightGrams: (map['unitWeightGrams'] as num).toInt(),
      recipeId: map['recipeId'] as String,
      recipeVersion: (map['recipeVersion'] as num).toInt(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: ProductionBatchStatusX.fromKey(
        map['status'] as String? ?? 'draft',
      ),
      note: map['note'] as String?,
      cancellationReason: map['cancellationReason'] as String?,
      lotNumber: map['lotNumber'] as String?,
      expiryDate: map['expiryDate'] == null
          ? null
          : DateTime.parse(map['expiryDate'] as String),
      sourceLotNumbers: (map['sourceLotNumbers'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }
}
