import 'dart:convert';

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


  test('migrates legacy string-list production batches', () async {
    final legacyBatch = ProductionBatch(
      id: 'legacy-batch',
      productVariantId: 'variant-1',
      productName: 'محصول قدیمی',
      units: 5,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    SharedPreferences.setMockInitialValues({
      'production_batches': [jsonEncode(legacyBatch.toMap())],
    });

    final result = await store.getById('legacy-batch');
    expect(result, isNotNull);
    expect(result!.productName, 'محصول قدیمی');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('production_batches'), isNotNull);
    expect(prefs.getStringList('production_batches'), isNull);
  });

  test('preserves traceability fields through persistence', () async {
    final batch = ProductionBatch(
      id: 'trace-batch',
      productVariantId: 'variant-1',
      productName: 'محصول',
      units: 10,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 2,
      createdAt: DateTime(2026, 1, 1),
      lotNumber: 'LOT-2026-001',
      expiryDate: DateTime(2026, 12, 31),
      sourceLotNumbers: const ['RAW-001', 'RAW-002'],
    );

    await store.add(batch);
    final result = await store.getById('trace-batch');

    expect(result!.lotNumber, 'LOT-2026-001');
    expect(result.expiryDate, DateTime(2026, 12, 31));
    expect(result.sourceLotNumbers, ['RAW-001', 'RAW-002']);
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
