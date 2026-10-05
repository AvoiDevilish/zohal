import 'package:flutter_test/flutter_test.dart';
import 'package:zohal_android_test/app/app.dart';

void main() {
  testWidgets('ZOHAL app loads', (tester) async {
    await tester.pumpWidget(const ZohalApp());
    await tester.pump();

    expect(find.text('خانه'), findsWidgets);
    expect(find.text('زحل'), findsWidgets);
    expect(find.text('همه‌چیز تحت کنترل است.'), findsOneWidget);
  });
}
