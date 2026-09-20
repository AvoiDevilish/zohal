import 'package:flutter_test/flutter_test.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_lifecycle.dart';

void main() {
  group('ProductionLifecycle', () {
    final createdAt = DateTime(2026, 9, 17, 10, 30);

    ProductionBatch buildBatch({
      ProductionBatchStatus status = ProductionBatchStatus.draft,
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
      );
    }

    const lifecycle = ProductionLifecycle();

    test('moves draft to ready', () {
      final result = lifecycle.moveToReady(buildBatch());

      expect(result.status, ProductionBatchStatus.ready);
    });

    test('moves ready to inProduction', () {
      final result = lifecycle.start(
        buildBatch(status: ProductionBatchStatus.ready),
      );

      expect(result.status, ProductionBatchStatus.inProduction);
    });

    test('moves inProduction to completed', () {
      final result = lifecycle.complete(
        buildBatch(status: ProductionBatchStatus.inProduction),
      );

      expect(result.status, ProductionBatchStatus.completed);
    });

    test('supports cancellation with a required reason', () {
      final result = lifecycle.cancel(
        buildBatch(status: ProductionBatchStatus.ready),
        reason: 'تغییر برنامه تولید',
      );

      expect(result.status, ProductionBatchStatus.cancelled);
      expect(result.cancellationReason, 'تغییر برنامه تولید');
    });

    test('rejects invalid transition from draft to inProduction', () {
      expect(
        () => lifecycle.start(buildBatch()),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('rejects invalid transition from draft to completed', () {
      expect(
        () => lifecycle.complete(buildBatch()),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('rejects transition after completion', () {
      final batch = buildBatch(status: ProductionBatchStatus.completed);

      expect(
        () => lifecycle.start(batch),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('rejects cancelling a completed batch', () {
      expect(
        () => lifecycle.cancel(
          buildBatch(status: ProductionBatchStatus.completed),
          reason: 'اشتباه',
        ),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('rejects empty cancellation reason', () {
      expect(
        () => lifecycle.cancel(
          buildBatch(status: ProductionBatchStatus.ready),
          reason: '   ',
        ),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('rejects cancelling an already cancelled batch', () {
      expect(
        () => lifecycle.cancel(
          buildBatch(status: ProductionBatchStatus.cancelled),
          reason: 'دلیل دوم',
        ),
        throwsA(isA<ProductionLifecycleException>()),
      );
    });

    test('preserves batch data during transition', () {
      final original = buildBatch();
      final ready = lifecycle.moveToReady(original);

      expect(ready.id, original.id);
      expect(ready.productVariantId, original.productVariantId);
      expect(ready.productName, original.productName);
      expect(ready.units, original.units);
      expect(ready.unitWeightGrams, original.unitWeightGrams);
      expect(ready.recipeId, original.recipeId);
      expect(ready.recipeVersion, original.recipeVersion);
      expect(ready.createdAt, original.createdAt);
    });
  });
}
