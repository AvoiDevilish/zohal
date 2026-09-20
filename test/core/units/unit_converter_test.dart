import 'package:flutter_test/flutter_test.dart';

import 'package:zohal_android_test/core/units/unit.dart';
import 'package:zohal_android_test/core/units/unit_converter.dart';

void main() {
  const converter = UnitConverter();

  group('UnitConverter', () {
    test('converts kilograms to grams', () {
      expect(
        converter.convert(
          quantity: 2,
          from: Unit.kilogram,
          to: Unit.gram,
        ),
        2000,
      );
    });

    test('converts grams to kilograms', () {
      expect(
        converter.convert(
          quantity: 2500,
          from: Unit.gram,
          to: Unit.kilogram,
        ),
        2.5,
      );
    });

    test('keeps same unit unchanged', () {
      expect(
        converter.convert(
          quantity: 537.3,
          from: Unit.gram,
          to: Unit.gram,
        ),
        537.3,
      );
    });

    test('supports count units', () {
      expect(
        converter.convert(
          quantity: 20,
          from: Unit.piece,
          to: Unit.piece,
        ),
        20,
      );
    });

    test('rejects conversion between weight and count', () {
      expect(
        () => converter.convert(
          quantity: 1,
          from: Unit.kilogram,
          to: Unit.piece,
        ),
        throwsArgumentError,
      );
    });

    test('converts to base unit', () {
      expect(
        converter.toBase(
          quantity: 3,
          unit: Unit.kilogram,
        ),
        3000,
      );

      expect(
        converter.toBase(
          quantity: 25,
          unit: Unit.piece,
        ),
        25,
      );
    });

    test('converts from base unit', () {
      expect(
        converter.fromBase(
          baseQuantity: 3500,
          unit: Unit.kilogram,
        ),
        3.5,
      );
    });

    test('supports fractional quantities', () {
      expect(
        converter.convert(
          quantity: 537.3,
          from: Unit.gram,
          to: Unit.kilogram,
        ),
        closeTo(0.5373, 0.0000001),
      );
    });
  });
}
