class NutAllocation {
  final String materialId;
  final String materialName;

  /// Percentage of the 27% nut portion.
  final double percentage;

  const NutAllocation({
    required this.materialId,
    required this.materialName,
    required this.percentage,
  });

  NutAllocation copyWith({
    String? materialId,
    String? materialName,
    double? percentage,
  }) {
    return NutAllocation(
      materialId: materialId ?? this.materialId,
      materialName: materialName ?? this.materialName,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'materialName': materialName,
      'percentage': percentage,
    };
  }

  factory NutAllocation.fromMap(Map<String, dynamic> map) {
    return NutAllocation(
      materialId: map['materialId'] as String,
      materialName: map['materialName'] as String,
      percentage: (map['percentage'] as num).toDouble(),
    );
  }
}
