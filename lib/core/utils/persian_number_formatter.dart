class PersianNumberFormatter {
  static const List<String> _ones = ['', 'یک', 'دو', 'سه', 'چهار', 'پنج', 'شش', 'هفت', 'هشت', 'نه', 'ده', 'یازده', 'دوازده', 'سیزده', 'چهارده', 'پانزده', 'شانزده', 'هفده', 'هجده', 'نوزده'];
  static const List<String> _tens = ['', '', 'بیست', 'سی', 'چهل', 'پنجاه', 'شصت', 'هفتاد', 'هشتاد', 'نود'];
  static const List<String> _hundreds = ['', 'صد', 'دویست', 'سیصد', 'چهارصد', 'پانصد', 'ششصد', 'هفتصد', 'هشتصد', 'نهصد'];
  static const List<String> _scales = ['', 'هزار', 'میلیون', 'میلیارد', 'تریلیون'];

  static String digits(int value) {
    const western = '0123456789';
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    return value.toString().split('').map((char) {
      final index = western.indexOf(char);
      return index == -1 ? char : persian[index];
    }).join();
  }

  static String money(int value) {
    final negative = value < 0;
    final raw = value.abs().toString();
    final groups = <String>[];
    for (var end = raw.length; end > 0;) {
      final start = end >= 3 ? end - 3 : 0;
      groups.insert(0, raw.substring(start, end));
      end = start;
    }
    final formatted = groups.map((group) => digits(int.parse(group))).join('٬');
    return (negative ? '−' : '') + formatted + ' تومان';
  }

  static String words(int value) {
    if (value == 0) return 'صفر';
    if (value < 0) return 'منفی ' + words(-value);
    final parts = <String>[];
    var remaining = value;
    var scale = 0;
    while (remaining > 0) {
      final group = remaining % 1000;
      if (group != 0) {
        final groupWords = _threeDigitsToWords(group);
        parts.insert(0, _scales[scale].isEmpty ? groupWords : groupWords + ' ' + _scales[scale]);
      }
      remaining ~/= 1000;
      scale++;
    }
    return parts.join(' و ');
  }

  static String _threeDigitsToWords(int value) {
    final parts = <String>[];
    final hundreds = value ~/ 100;
    final remainder = value % 100;
    if (hundreds > 0) parts.add(_hundreds[hundreds]);
    if (remainder > 0) {
      if (remainder < 20) {
        parts.add(_ones[remainder]);
      } else {
        final tens = remainder ~/ 10;
        final ones = remainder % 10;
        parts.add(_tens[tens]);
        if (ones > 0) parts.add(_ones[ones]);
      }
    }
    return parts.join(' و ');
  }
}
