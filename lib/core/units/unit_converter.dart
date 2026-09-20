import 'unit.dart';

class UnitConverter {
  const UnitConverter();

  double convert({
    required double quantity,
    required Unit from,
    required Unit to,
  }) {
    if (from.type != to.type) {
      throw ArgumentError(
        'تبدیل بین خانواده‌های متفاوت واحد مجاز نیست: '
        '${from.key} → ${to.key}',
      );
    }

    final baseQuantity = from.toBase(quantity);
    return to.fromBase(baseQuantity);
  }

  double toBase({
    required double quantity,
    required Unit unit,
  }) {
    return unit.toBase(quantity);
  }

  double fromBase({
    required double baseQuantity,
    required Unit unit,
  }) {
    return unit.fromBase(baseQuantity);
  }
}
