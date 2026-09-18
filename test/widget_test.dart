import 'package:flutter_test/flutter_test.dart';
import 'package:zohal_android_test/app/app.dart';

void main() {
  testWidgets('ZOHAL app loads', (tester) async {
    await tester.pumpWidget(const ZohalApp());

    expect(find.text('مدیریت زحل'), findsOneWidget);
    expect(find.text('فروش امروز'), findsOneWidget);
  });
}
