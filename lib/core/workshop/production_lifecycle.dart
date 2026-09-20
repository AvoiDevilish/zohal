import 'production_batch.dart';

class ProductionLifecycleException implements Exception {
  final String message;

  const ProductionLifecycleException(this.message);

  @override
  String toString() => message;
}

class ProductionLifecycle {
  const ProductionLifecycle();

  ProductionBatch moveToReady(ProductionBatch batch) {
    _requireStatus(batch, ProductionBatchStatus.draft);

    return batch.copyWith(status: ProductionBatchStatus.ready);
  }

  ProductionBatch start(ProductionBatch batch) {
    _requireStatus(batch, ProductionBatchStatus.ready);

    return batch.copyWith(status: ProductionBatchStatus.inProduction);
  }

  ProductionBatch complete(ProductionBatch batch) {
    _requireStatus(batch, ProductionBatchStatus.inProduction);

    return batch.copyWith(status: ProductionBatchStatus.completed);
  }

  ProductionBatch cancel(ProductionBatch batch, {required String reason}) {
    if (batch.status == ProductionBatchStatus.completed) {
      throw const ProductionLifecycleException(
        'تولید تکمیل‌شده قابل لغو نیست.',
      );
    }

    if (batch.status == ProductionBatchStatus.cancelled) {
      throw const ProductionLifecycleException('این تولید قبلاً لغو شده است.');
    }

    if (reason.trim().isEmpty) {
      throw const ProductionLifecycleException(
        'برای لغو تولید باید دلیل ثبت شود.',
      );
    }

    return batch.copyWith(
      status: ProductionBatchStatus.cancelled,
      cancellationReason: reason.trim(),
    );
  }

  void _requireStatus(ProductionBatch batch, ProductionBatchStatus expected) {
    if (batch.status != expected) {
      throw ProductionLifecycleException(
        'تغییر وضعیت از ${batch.status.title} به وضعیت موردنظر مجاز نیست.',
      );
    }
  }
}
