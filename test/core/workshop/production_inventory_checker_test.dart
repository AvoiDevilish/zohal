import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/workshop/nut_allocation.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_inventory_checker.dart';
import 'package:zohal_android_test/core/workshop/recipe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('ProductionInventoryChecker', () {
    late InventoryStore inventoryStore;
    late ProductionInventoryChecker checker;

    const calculator = ProductionCalculator();

    const recipe = Recipe(
      id: 'recipe-100-ginger',
      productVariantId: 'energy-100-ginger',
      name: 'انرژی بار ۱۰۰ گرمی زنجبیلی',
      datePercentage: 70,
      nutPercentage: 27,
      sesamePercentage: 3,
      flavoringPercentage: 0.5,
    );

    const allocations = [
      NutAllocation(
        materialId: 'peanut',
        materialName: 'بادام زمینی',
        percentage: 45,
      ),
      NutAllocation(
        materialId: 'walnut',
        materialName: 'گردو',
        percentage: 30,
      ),
      NutAllocation(
        materialId: 'cashew',
        materialName: 'بادام هندی',
        percentage: 25,
      ),
    ];

    setUp(() async {
      inventoryStore = InventoryStore.instance;
      await inventoryStore.clear();

      checker = ProductionInventoryChecker(
        inventoryStore: inventoryStore,
      );
    });

    tearDown(() async {
      await inventoryStore.clear();
    });

    ProductionCalculation buildCalculation() {
      return calculator.calculate(
        recipe: recipe,
        units: 20,
        unitWeightGrams: 100,
        dateMaterialId: 'date',
        dateMaterialName: 'خرمای خشت',
        nutAllocations: allocations,
        sesameMaterialId: 'sesame',
        sesameMaterialName: 'کنجد',
        flavorMaterialId: 'ginger',
        flavorMaterialName: 'پودر زنجبیل',
      );
    }

    Future<void> addStock({
      required String materialId,
      required String materialName,
      required double quantity,
    }) async {
      await inventoryStore.addMovement(
        InventoryMovement(
          id: 'purchase-$materialId',
          itemId: materialId,
          itemName: materialName,
          itemType: 'rawMaterial',
          quantity: quantity,
          unit: 'گرم',
          movementType: InventoryMovementType.purchase,
          timestamp: DateTime(2026, 1, 1),
          note: 'تست',
        ),
      );
    }

    test('reads stock from InventoryStore', () async {
      await addStock(
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 5000,
      );

      await addStock(
        materialId: 'peanut',
        materialName: 'بادام زمینی',
        quantity: 500,
      );

      await addStock(
        materialId: 'walnut',
        materialName: 'گردو',
        quantity: 500,
      );

      await addStock(
        materialId: 'cashew',
        materialName: 'بادام هندی',
        quantity: 500,
      );

      await addStock(
        materialId: 'sesame',
        materialName: 'کنجد',
        quantity: 500,
      );

      await addStock(
        materialId: 'ginger',
        materialName: 'پودر زنجبیل',
        quantity: 100,
      );

      final result = await checker.check(
        buildCalculation(),
      );

      expect(result.canProduce, isTrue);
      expect(result.shortages, isEmpty);
    });

    test('blocks production using real inventory shortage', () async {
      await addStock(
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 5000,
      );

      await addStock(
        materialId: 'peanut',
        materialName: 'بادام زمینی',
        quantity: 100,
      );

      await addStock(
        materialId: 'walnut',
        materialName: 'گردو',
        quantity: 500,
      );

      await addStock(
        materialId: 'cashew',
        materialName: 'بادام هندی',
        quantity: 500,
      );

      await addStock(
        materialId: 'sesame',
        materialName: 'کنجد',
        quantity: 500,
      );

      await addStock(
        materialId: 'ginger',
        materialName: 'پودر زنجبیل',
        quantity: 100,
      );

      final result = await checker.check(
        buildCalculation(),
      );

      expect(result.canProduce, isFalse);

      final peanut = result.shortages.firstWhere(
        (item) => item.materialId == 'peanut',
      );

      expect(
        peanut.shortageQuantity,
        closeTo(141.785, 0.0001),
      );
    });
  });
}
