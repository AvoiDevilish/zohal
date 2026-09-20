import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_service.dart';
import 'package:zohal_android_test/core/workshop/recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Recipe buildRecipe() {
    return const Recipe(
      id: 'recipe-100g-ginger',
      productVariantId: 'energy-bar-100g-ginger',
      name: 'انرژی بار ۱۰۰ گرم زنجبیلی',
      version: 1,
      datePercentage: 70,
      nutPercentage: 27,
      sesamePercentage: 3,
      flavoringPercentage: 0.5,
    );
  }

  ProductionCalculation buildCalculation() {
    return const ProductionCalculator().calculate(
      recipe: Recipe(
        id: 'recipe-100g-ginger',
        productVariantId: 'energy-bar-100g-ginger',
        name: 'انرژی بار ۱۰۰ گرم زنجبیلی',
        version: 1,
        datePercentage: 70,
        nutPercentage: 27,
        sesamePercentage: 3,
        flavoringPercentage: 0.5,
      ),
      units: 20,
      unitWeightGrams: 100,
      dateMaterialId: 'date',
      dateMaterialName: 'خرما',
      nutAllocations: [
        NutAllocation(
          materialId: 'peanut',
          materialName: 'بادام زمینی',
          percentage: 34,
        ),
        NutAllocation(
          materialId: 'walnut',
          materialName: 'گردوی ایرانی',
          percentage: 33,
        ),
        NutAllocation(
          materialId: 'cashew',
          materialName: 'بادام هندی',
          percentage: 33,
        ),
      ],
      sesameMaterialId: 'sesame',
      sesameMaterialName: 'کنجد',
      flavorMaterialId: 'ginger',
      flavorMaterialName: 'زنجبیل',
    );
  }

  Future<void> addStock(
    InventoryStore store, {
    required String id,
    required String name,
    required double quantity,
    required String unit,
    required String itemType,
  }) async {
    await store.addMovement(
      InventoryMovement(
        id: 'purchase-$id',
        itemId: id,
        itemName: name,
        itemType: itemType,
        quantity: quantity,
        unit: unit,
        movementType: InventoryMovementType.purchase,
        timestamp: DateTime(2026, 9, 17),
        unitCost: 1000,
      ),
    );
  }

  Future<void> addStandardStock(InventoryStore store) async {
    await addStock(
      store,
      id: 'date',
      name: 'خرما',
      quantity: 2000,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    await addStock(
      store,
      id: 'peanut',
      name: 'بادام زمینی',
      quantity: 1000,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    await addStock(
      store,
      id: 'walnut',
      name: 'گردوی ایرانی',
      quantity: 1000,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    await addStock(
      store,
      id: 'cashew',
      name: 'بادام هندی',
      quantity: 1000,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    await addStock(
      store,
      id: 'sesame',
      name: 'کنجد',
      quantity: 500,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    await addStock(
      store,
      id: 'ginger',
      name: 'زنجبیل',
      quantity: 100,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );
  }

  ProductionBatch buildBatch() {
    return ProductionBatch(
      id: 'batch-001',
      productVariantId: 'energy-bar-100g-ginger',
      productName: 'انرژی بار ۱۰۰ گرم زنجبیلی',
      units: 20,
      unitWeightGrams: 100,
      recipeId: 'recipe-100g-ginger',
      recipeVersion: 1,
      createdAt: DateTime(2026, 9, 17),
    );
  }

  test('executes batch and completes lifecycle', () async {
    final store = InventoryStore.instance;
    await addStandardStock(store);

    final batch = const ProductionLifecycleHelper().ready(buildBatch());

    final result = await ProductionService(
      inventoryStore: store,
    ).executeBatch(batch: batch, calculation: buildCalculation());

    expect(result.executed, isTrue);
    expect(result.alreadyExecuted, isFalse);
    expect(result.batch.status, ProductionBatchStatus.completed);

    final movements = await store.getMovements();

    expect(
      movements.where((item) => item.referenceId == 'batch-001').length,
      7,
    );

    expect(
      movements
          .where(
            (item) =>
                item.referenceId == 'batch-001' &&
                item.movementType == InventoryMovementType.productionOutput,
          )
          .length,
      1,
    );
  });

  test('does not execute same batch twice', () async {
    final store = InventoryStore.instance;
    await addStandardStock(store);

    final batch = const ProductionLifecycleHelper().ready(buildBatch());
    final service = ProductionService(inventoryStore: store);

    final first = await service.executeBatch(
      batch: batch,
      calculation: buildCalculation(),
    );

    final stockAfterFirst = await store.getAllStocks();

    final second = await service.executeBatch(
      batch: first.batch,
      calculation: buildCalculation(),
    );

    final stockAfterSecond = await store.getAllStocks();

    expect(first.executed, isTrue);
    expect(second.executed, isFalse);
    expect(second.alreadyExecuted, isTrue);

    expect(stockAfterSecond, equals(stockAfterFirst));

    final movements = await store.getMovements();

    expect(
      movements.where((item) => item.referenceId == 'batch-001').length,
      7,
    );
  });

  test('does not consume inventory when stock is insufficient', () async {
    final store = InventoryStore.instance;

    await addStock(
      store,
      id: 'date',
      name: 'خرما',
      quantity: 10,
      unit: 'گرم',
      itemType: 'rawMaterial',
    );

    final batch = const ProductionLifecycleHelper().ready(buildBatch());

    final result = await ProductionService(
      inventoryStore: store,
    ).executeBatch(batch: batch, calculation: buildCalculation());

    expect(result.executed, isFalse);
    expect(result.alreadyExecuted, isFalse);

    // کمبود موجودی نباید Batch را وارد چرخه تولید کند.
    // Batch باید در وضعیت READY باقی بماند تا پس از تأمین مواد
    // بتوان دوباره همان Batch را اجرا کرد.
    expect(result.batch.status, ProductionBatchStatus.ready);

    final movements = await store.getMovements();

    expect(
      movements.where(
        (item) =>
            item.referenceId == 'batch-001' &&
            item.movementType == InventoryMovementType.productionConsumption,
      ),
      isEmpty,
    );

    expect(
      movements.where(
        (item) =>
            item.referenceId == 'batch-001' &&
            item.movementType == InventoryMovementType.productionOutput,
      ),
      isEmpty,
    );
  });
}

/// فقط برای آماده‌کردن Batch تست؛
/// Lifecycle واقعی همچنان در ProductionLifecycle قرار دارد.
class ProductionLifecycleHelper {
  const ProductionLifecycleHelper();

  ProductionBatch ready(ProductionBatch batch) {
    return batch.copyWith(status: ProductionBatchStatus.ready);
  }
}
