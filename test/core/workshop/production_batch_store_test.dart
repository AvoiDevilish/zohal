import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductionBatchStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    store = ProductionBatchStore.instance;

    await store.clear();
  });

  test('stores and retrieves production batch', () async {
    final batch = ProductionBatch(
      id: 'batch-1',
      productVariantId: 'energy-bar-100g-ginger',
      productName: 'انرژی بار زنجبیلی',
      units: 20,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(batch);

    final result = await store.getById('batch-1');

    expect(result, isNotNull);
    expect(result!.productName, 'انرژی بار زنجبیلی');
    expect(result.units, 20);
  });


  test('prevents duplicate production batch', () async {
    final batch = ProductionBatch(
      id: 'batch-1',
      productVariantId: 'energy-bar-100g-ginger',
      productName: 'انرژی بار زنجبیلی',
      units: 20,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(batch);

    expect(
      () => store.add(batch),
      throwsStateError,
    );
  });
}
