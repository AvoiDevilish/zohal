import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/products/product_catalog.dart';
import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/packaging_rule.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_service.dart';
import 'package:zohal_android_test/core/workshop/recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ProductionService', () {
    late InventoryStore inventoryStore;

    setUp(() async {
      inventoryStore = InventoryStore.instance;
      await inventoryStore.clear();
    });

    Recipe recipe() {
      return Recipe(
        id: 'recipe-1',
        productVariantId: ProductCatalog.findById('energy-bar-100g-ginger').id,
        name: 'انرژی بار زنجبیلی',
        flavoringPercentage: 0.5,
      );
    }

    ProductionCalculation calculation({
      List<PackagingRule> packagingRules = const [],
    }) {
      return ProductionCalculator().calculate(
        recipe: recipe(),
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای دشتستان',
        nutAllocations: const [
          NutAllocation(
            materialId: 'peanut',
            materialName: 'بادام زمینی',
            percentage: 45,
          ),
          NutAllocation(
            materialId: 'walnut',
            materialName: 'گردوی ایرانی خرد شده',
            percentage: 30,
          ),
          NutAllocation(
            materialId: 'cashew',
            materialName: 'بادام هندی',
            percentage: 25,
          ),
        ],
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        datePitMaterialId: 'raw_date_pit',
        datePitMaterialName: 'هسته خرما',
        flavorMaterialId: 'ginger',
        flavorMaterialName: 'پودر زنجبیل',
        packagingRules: packagingRules,
      );
    }

    Future<void> addStock({
      required String itemId,
      required String itemName,
      required double quantity,
      String unit = 'g',
      String itemType = 'rawMaterial',
    }) {
      return inventoryStore.addMovement(
        InventoryMovement(
          id: 'purchase-$itemId',
          itemId: itemId,
          itemName: itemName,
          itemType: itemType,
          quantity: quantity,
          unit: unit,
          movementType: InventoryMovementType.purchase,
          timestamp: DateTime(2026, 1, 1),
        ),
      );
    }

    Future<void> addStandardProductionStock() async {
      await addStock(itemId: 'date', itemName: 'خرمای دشتستان', quantity: 2000);
      await addStock(itemId: 'peanut', itemName: 'بادام زمینی', quantity: 500);
      await addStock(
        itemId: 'walnut',
        itemName: 'گردوی ایرانی خرد شده',
        quantity: 300,
      );
      await addStock(itemId: 'cashew', itemName: 'بادام هندی', quantity: 300);
      await addStock(itemId: 'sesame', itemName: 'کنجد', quantity: 100);
      await addStock(itemId: 'ginger', itemName: 'پودر زنجبیل', quantity: 20);
    }

    test('executes production and records consumption plus output', () async {
      await addStandardProductionStock();

      final result = await ProductionService(inventoryStore: inventoryStore)
          .execute(
            calculation: calculation(),
            productId: 'energy-bar-100g-ginger',
            productName: 'انرژی بار ۱۰۰g زنجبیلی',
            productionId: 'production-test-1',
          );

      expect(result.executed, isTrue);
      expect(result.productionId, 'production-test-1');
      expect(result.stockCheck.canProduce, isTrue);

      final movements = await inventoryStore.getMovements();

      final productionMovements = movements
          .where((m) => m.referenceId == 'production-test-1')
          .toList();

      expect(productionMovements, hasLength(8));

      expect(
        productionMovements.where(
          (m) => m.movementType == InventoryMovementType.productionConsumption,
        ),
        hasLength(6),
      );

      expect(
        productionMovements.where(
          (m) => m.movementType == InventoryMovementType.productionOutput,
        ),
        hasLength(2),
      );

      final output = productionMovements.firstWhere(
        (m) => m.movementType == InventoryMovementType.productionOutput,
      );

      expect(output.itemId, 'energy-bar-100g-ginger');
      expect(output.quantity, 20);
      expect(output.unit, 'عدد');

      expect(await inventoryStore.getStock('date'), closeTo(452.222222, 0.001));
      expect(await inventoryStore.getStock('raw_date_pit'), closeTo(154.777778, 0.001));
      expect(await inventoryStore.getStock('peanut'), closeTo(258.215, 0.001));
      expect(await inventoryStore.getStock('walnut'), closeTo(138.81, 0.001));
      expect(await inventoryStore.getStock('cashew'), closeTo(165.675, 0.001));
      expect(await inventoryStore.getStock('sesame'), closeTo(40.3, 0.001));
      expect(await inventoryStore.getStock('ginger'), closeTo(10, 0.001));

      expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 20);
    });

    test('consumes packaging inventory during production', () async {
      await addStandardProductionStock();

      await addStock(
        itemId: 'container-100g',
        itemName: 'ظرف ۱۰۰ گرمی',
        quantity: 50,
        unit: 'عدد',
        itemType: 'packaging',
      );

      await addStock(
        itemId: 'label',
        itemName: 'لیبل',
        quantity: 50,
        unit: 'عدد',
        itemType: 'packaging',
      );

      final result = await ProductionService(inventoryStore: inventoryStore)
          .execute(
            calculation: calculation(
              packagingRules: const [
                PackagingRule(
                  productVariantId: 'energy-bar-100g-ginger',
                  materialId: 'container-100g',
                  materialName: 'ظرف ۱۰۰ گرمی',
                  quantityPerUnit: 1,
                  unit: 'عدد',
                ),
                PackagingRule(
                  productVariantId: 'energy-bar-100g-ginger',
                  materialId: 'label',
                  materialName: 'لیبل',
                  quantityPerUnit: 1,
                  unit: 'عدد',
                ),
              ],
            ),
            productId: 'energy-bar-100g-ginger',
            productName: 'انرژی بار ۱۰۰g زنجبیلی',
            productionId: 'production-packaging-1',
          );

      expect(result.executed, isTrue);
      expect(result.stockCheck.canProduce, isTrue);

      expect(await inventoryStore.getStock('container-100g'), 30);

      expect(await inventoryStore.getStock('label'), 30);

      final movements = await inventoryStore.getMovements();

      final packagingMovements = movements
          .where(
            (movement) =>
                movement.referenceId == 'production-packaging-1' &&
                movement.movementType ==
                    InventoryMovementType.productionConsumption &&
                (movement.itemId == 'container-100g' ||
                    movement.itemId == 'label'),
          )
          .toList();

      expect(packagingMovements, hasLength(2));

      for (final movement in packagingMovements) {
        expect(movement.itemType, 'packaging');
        expect(movement.quantity, 20);
        expect(movement.unit, 'عدد');
      }

      expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 20);
    });

    test('does not change inventory when production is insufficient', () async {
      await addStock(itemId: 'date', itemName: 'خرمای دشتستان', quantity: 2000);
      await addStock(itemId: 'peanut', itemName: 'بادام زمینی', quantity: 100);
      await addStock(
        itemId: 'walnut',
        itemName: 'گردوی ایرانی خرد شده',
        quantity: 300,
      );
      await addStock(itemId: 'cashew', itemName: 'بادام هندی', quantity: 300);
      await addStock(itemId: 'sesame', itemName: 'کنجد', quantity: 100);
      await addStock(itemId: 'ginger', itemName: 'پودر زنجبیل', quantity: 20);

      final before = await inventoryStore.getMovements();

      final result = await ProductionService(inventoryStore: inventoryStore)
          .execute(
            calculation: calculation(),
            productId: 'energy-bar-100g-ginger',
            productName: 'انرژی بار ۱۰۰g زنجبیلی',
            productionId: 'production-test-2',
          );

      expect(result.executed, isFalse);
      expect(result.stockCheck.canProduce, isFalse);
      expect(result.stockCheck.shortages, isNotEmpty);

      final after = await inventoryStore.getMovements();

      expect(after.length, before.length);
      expect(after.where((m) => m.referenceId == 'production-test-2'), isEmpty);

      expect(await inventoryStore.getStock('peanut'), 100);
      expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 0);
    });
    test('repairs a partial production movement set on retry', () async {
      await addStandardProductionStock();

      const productionId = 'production-partial-1';
      final calc = calculation();
      final service = ProductionService(inventoryStore: inventoryStore);

      final fullResult = await service.execute(
        calculation: calc,
        productId: 'energy-bar-100g-ginger',
        productName: 'انرژی بار ۱۰۰g زنجبیلی',
        productionId: productionId,
      );
      expect(fullResult.executed, isTrue);

      final all = await inventoryStore.getMovements();
      final output = all.firstWhere(
        (movement) =>
            movement.referenceId == productionId &&
            movement.movementType == InventoryMovementType.productionOutput &&
            movement.itemId == 'energy-bar-100g-ginger',
      );
      await inventoryStore.removeMovement(output.id);

      final retry = await service.execute(
        calculation: calc,
        productId: 'energy-bar-100g-ginger',
        productName: 'انرژی بار ۱۰۰g زنجبیلی',
        productionId: productionId,
      );

      expect(retry.executed, isTrue);
      expect(
        (await inventoryStore.getMovements())
            .where((movement) => movement.referenceId == productionId),
        hasLength(8),
      );
      expect(await inventoryStore.getStock('energy-bar-100g-ginger'), 20);
    });

  });
}
