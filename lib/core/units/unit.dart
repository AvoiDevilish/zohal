enum UnitType { weight, count }

enum Unit {
  gram(key: 'g', title: 'گرم', type: UnitType.weight, baseMultiplier: 1),
  kilogram(
    key: 'kg',
    title: 'کیلوگرم',
    type: UnitType.weight,
    baseMultiplier: 1000,
  ),
  piece(key: 'unit', title: 'عدد', type: UnitType.count, baseMultiplier: 1);

  final String key;
  final String title;
  final UnitType type;

  /// مقدار این واحد نسبت به واحد پایه همان خانواده.
  ///
  /// weight:
  /// g = 1
  /// kg = 1000 g
  ///
  /// count:
  /// unit = 1
  final double baseMultiplier;

  const Unit({
    required this.key,
    required this.title,
    required this.type,
    required this.baseMultiplier,
  });

  static Unit fromKey(String key) {
    return Unit.values.firstWhere(
      (unit) => unit.key == key || unit.title == key,
      orElse: () => throw ArgumentError('واحد ناشناخته: $key'),
    );
  }

  double toBase(double quantity) {
    return quantity * baseMultiplier;
  }

  double fromBase(double baseQuantity) {
    return baseQuantity / baseMultiplier;
  }
}
