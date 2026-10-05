import 'package:flutter_test/flutter_test.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';

void main() {
  group('ProductionBatch', () {
    final createdAt = DateTime(2026, 9, 17, 10, 30);

    ProductionBatch buildBatch({
      ProductionBatchStatus status = ProductionBatchStatus.draft,
      String? note,
    }) {
      return ProductionBatch(
        id: 'batch-001',
        productVariantId: 'energy-bar-100g-ginger',
        productName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        units: 20,
        unitWeightGrams: 100,
        recipeId: 'recipe-100g-ginger',
        recipeVersion: 2,
        createdAt: createdAt,
        status: status,
        note: note,
      );
    }

    test('calculates total production weight', () {
      final batch = buildBatch();

      expect(batch.totalWeightGrams, 2000);
    });

    test('defaults to draft status', () {
      final batch = buildBatch();

      expect(batch.status, ProductionBatchStatus.draft);
      expect(batch.status.key, 'draft');
      expect(batch.status.title, 'پیش‌نویس');
    });

    test('serializes and restores all fields', () {
      final batch = buildBatch(note: 'تولید آزمایشی').copyWith(
        lotNumber: 'LOT-001',
        expiryDate: DateTime(2026, 12, 31),
        sourceLotNumbers: const ['RAW-001', 'RAW-002'],
      );

      final restored = ProductionBatch.fromMap(batch.toMap());

      expect(restored.id, batch.id);
      expect(restored.productVariantId, batch.productVariantId);
      expect(restored.productName, batch.productName);
      expect(restored.units, batch.units);
      expect(restored.unitWeightGrams, batch.unitWeightGrams);
      expect(restored.totalWeightGrams, 2000);
      expect(restored.recipeId, batch.recipeId);
      expect(restored.recipeVersion, batch.recipeVersion);
      expect(restored.createdAt, batch.createdAt);
      expect(restored.status, batch.status);
      expect(restored.note, batch.note);
      expect(restored.lotNumber, 'LOT-001');
      expect(restored.expiryDate, DateTime(2026, 12, 31));
      expect(restored.sourceLotNumbers, ['RAW-001', 'RAW-002']);
    });

    test('supports copyWith', () {
      final batch = buildBatch(note: 'نسخه اول');

      final updated = batch.copyWith(
        units: 35,
        recipeVersion: 3,
        note: 'نسخه جدید',
      );

      expect(updated.id, batch.id);
      expect(updated.productVariantId, batch.productVariantId);
      expect(updated.units, 35);
      expect(updated.unitWeightGrams, 100);
      expect(updated.totalWeightGrams, 3500);
      expect(updated.recipeVersion, 3);
      expect(updated.note, 'نسخه جدید');
    });

    test('can clear note with copyWith', () {
      final batch = buildBatch(note: 'یادداشت');

      final updated = batch.copyWith(clearNote: true);

      expect(updated.note, isNull);
    });

    test('unknown status falls back to draft', () {
      final restored = ProductionBatch.fromMap({
        'id': 'batch-002',
        'productVariantId': 'energy-bar-100g-ginger',
        'productName': 'انرژی بار ۱۰۰ گرم زنجبیلی',
        'units': 10,
        'unitWeightGrams': 100,
        'recipeId': 'recipe-100g-ginger',
        'recipeVersion': 1,
        'createdAt': createdAt.toIso8601String(),
        'status': 'unknown-status',
      });

      expect(restored.status, ProductionBatchStatus.draft);
    });
  });
}
