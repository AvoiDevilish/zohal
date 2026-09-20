import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/units/unit.dart';

void main() {
  group('Unit', () {
    test('has correct metadata for weight units', () {
      expect(Unit.gram.key, 'g');
      expect(Unit.kilogram.key, 'kg');

      expect(Unit.gram.type, UnitType.weight);
      expect(Unit.kilogram.type, UnitType.weight);

      expect(Unit.gram.baseMultiplier, 1);
      expect(Unit.kilogram.baseMultiplier, 1000);
    });

    test('has correct metadata for count unit', () {
      expect(Unit.piece.key, 'unit');
      expect(Unit.piece.title, 'عدد');
      expect(Unit.piece.type, UnitType.count);
      expect(Unit.piece.baseMultiplier, 1);
    });

    test('resolves unit from key', () {
      expect(Unit.fromKey('g'), Unit.gram);
      expect(Unit.fromKey('kg'), Unit.kilogram);
      expect(Unit.fromKey('unit'), Unit.piece);
    });

    test('throws for unknown unit key', () {
      expect(
        () => Unit.fromKey('unknown'),
        throwsArgumentError,
      );
    });

    test('converts quantity to base unit', () {
      expect(Unit.gram.toBase(500), 500);
      expect(Unit.kilogram.toBase(2), 2000);
      expect(Unit.piece.toBase(20), 20);
    });

    test('converts quantity from base unit', () {
      expect(Unit.gram.fromBase(500), 500);
      expect(Unit.kilogram.fromBase(2000), 2);
      expect(Unit.piece.fromBase(20), 20);
    });
  });
}
