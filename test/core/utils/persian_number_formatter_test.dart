import 'package:flutter_test/flutter_test.dart';
import 'package:zohal_android_test/core/utils/persian_number_formatter.dart';

void main() {
  test('formats financial amounts with Persian digit grouping', () {
    expect(PersianNumberFormatter.money(1234567890), '۱٬۲۳۴٬۵۶۷٬۸۹۰ تومان');
  });

  test('converts financial totals to Persian words', () {
    expect(
      PersianNumberFormatter.words(1750000),
      'یک میلیون و هفتصد و پنجاه هزار',
    );
  });
}
