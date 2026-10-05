import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/storage/local_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads and writes list data', () async {
    await LocalStore.instance.writeList('test-key', [
      {'id': 'one', 'value': 10},
    ]);

    expect(await LocalStore.instance.readList('test-key'), [
      {'id': 'one', 'value': 10},
    ]);
  });

  test('returns empty list for a missing key', () async {
    expect(await LocalStore.instance.readList('missing-key'), isEmpty);
  });

  test('rejects stored JSON with a non-list root', () async {
    SharedPreferences.setMockInitialValues({
      'test-key': '{"id":"one"}',
    });

    expect(
      () => LocalStore.instance.readList('test-key'),
      throwsStateError,
    );
  });

  test('rejects a list containing a non-map record', () async {
    SharedPreferences.setMockInitialValues({
      'test-key': '[{"id":"one"}, 42]',
    });

    expect(
      () => LocalStore.instance.readList('test-key'),
      throwsStateError,
    );
  });

  test('propagates malformed JSON instead of treating it as empty data', () async {
    SharedPreferences.setMockInitialValues({
      'test-key': '{"broken"',
    });

    expect(
      () => LocalStore.instance.readList('test-key'),
      throwsFormatException,
    );
  });
}
