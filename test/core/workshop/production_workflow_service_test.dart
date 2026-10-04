import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_allocation_store.dart';
import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/costing/cost_consumption_service.dart';
import 'package:zohal_android_test/core/costing/production_cost_service.dart';
import 'package:zohal_android_test/core/costing/production_cost_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_requirement.dart';
import 'package:zohal_android_test/core/workshop/production_service.dart';
import 'package:zohal_android_test/core/workshop/production_workflow_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InventoryStore inventoryStore;
  late CostLayerStore costLayerStore;
  late CostAllocationStore allocationStore;
  late ProductionCostStore costStore;
  late ProductionBatchStore batchStore;
  late ProductionWorkflowService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    inventoryStore = InventoryStore.instance;
    costLayerStore = CostLayerStore.instance;
    allocationStore = CostAllocationStore.instance;
    costStore = ProductionCostStore.instance;
    batchStore = ProductionBatchStore.instance;

    await inventoryStore.clear();
    await costLayerStore.clear();
    await allocationStore.clear();
    await costStore.clear();
    await batchStore.clear();

    service = ProductionWorkflowService(
      productionService: ProductionService(
        inventoryStore: inventoryStore,
      ),
      productionCostService: ProductionCostService(
        costConsumptionService: CostConsumptionService(
          costLayerStore: costLayerStore,
          allocationStore: allocationStore,
        ),
      ),
      productionBatchStore: batchStore,
      productionCostStore: costStore,
    );
  });

  ProductionBatch batch() {
    return ProductionBatch(
      id: 'production-workflow-1',
      productVariantId: 'energy-bar-100g',
      productName: 'انرژی بار ۱۰۰ گرمی',
      units: 10,
      unitWeightGrams: 100,
      recipeId: 'recipe-1',
      recipeVersion: 1,
      createdAt: DateTime(2026, 1, 1),
      status: ProductionBatchStatus.ready,
    );
  }

  ProductionCalculation calculation() {
    return const ProductionCalculation(
      units: 10,
      unitWeightGrams: 100,
      totalWeightGrams: 1000,
      requirements: [
        ProductionRequirement(
          materialId: 'date',
          materialName: 'خرما',
          quantity: 1000,
          unit: 'g',
        ),
        ProductionRequirement(
          materialId: 'box',
          materialName: 'ظرف',
          quantity: 10,
          unit: 'unit',
          type: ProductionRequirementType.packaging,
        ),
      ],
    );
  }

  Future<void> addInventoryStock({
    required String itemId,
    required String itemName,
    required double quantity,
    required String unit,
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

  Future<void> addCostLayer({
    required String id,
    required String materialId,
    required String materialName,
    required double quantity,
    required String unit,
    required double unitCost,
  }) {
    return costLayerStore.add(
      CostLayer(
        id: id,
        materialId: materialId,
        materialName: materialName,
        quantity: quantity,
        remainingQuantity: quantity,
        unit: unit,
        unitCost: unitCost,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'purchase-$materialId',
      ),
    );
  }

  test('executes production, persists batch and persists production cost',
      () async {
    await addInventoryStock(
      itemId: 'date',
      itemName: 'خرما',
      quantity: 2000,
      unit: 'g',
    );
    await addInventoryStock(
      itemId: 'box',
      itemName: 'ظرف',
      quantity: 20,
      unit: 'unit',
      itemType: 'packaging',
    );

    await addCostLayer(
      id: 'date-layer',
      materialId: 'date',
      materialName: 'خرما',
      quantity: 2000,
      unit: 'g',
      unitCost: 10,
    );
    await addCostLayer(
      id: 'box-layer',
      materialId: 'box',
      materialName: 'ظرف',
      quantity: 20,
      unit: 'unit',
      unitCost: 500,
    );

    final result = await service.execute(
      batch: batch(),
      calculation: calculation(),
    );

    expect(result.execution.executed, isTrue);
    expect(result.execution.alreadyExecuted, isFalse);
    expect(result.cost.totalCost, 15000);
    expect(result.cost.materialCost, 10000);
    expect(result.cost.packagingCost, 5000);
    expect(result.cost.unitCost, 1500);

    expect(await batchStore.getById(batch().id), isNotNull);
    expect(await costStore.getByProductionId(batch().id), isNotNull);

    final movements = await inventoryStore.getMovements();
    expect(
      movements.where((item) => item.referenceId == batch().id),
      hasLength(3),
    );

    expect((await costLayerStore.getById('date-layer'))!.remainingQuantity, 1000);
    expect((await costLayerStore.getById('box-layer'))!.remainingQuantity, 10);
  });

  test('retry is idempotent and does not double-consume inventory or cost',
      () async {
    await addInventoryStock(
      itemId: 'date',
      itemName: 'خرما',
      quantity: 2000,
      unit: 'g',
    );
    await addInventoryStock(
      itemId: 'box',
      itemName: 'ظرف',
      quantity: 20,
      unit: 'unit',
      itemType: 'packaging',
    );

    await addCostLayer(
      id: 'date-layer',
      materialId: 'date',
      materialName: 'خرما',
      quantity: 2000,
      unit: 'g',
      unitCost: 10,
    );
    await addCostLayer(
      id: 'box-layer',
      materialId: 'box',
      materialName: 'ظرف',
      quantity: 20,
      unit: 'unit',
      unitCost: 500,
    );

    final first = await service.execute(
      batch: batch(),
      calculation: calculation(),
    );
    final firstMovements = await inventoryStore.getMovements();
    final firstDateRemaining =
        (await costLayerStore.getById('date-layer'))!.remainingQuantity;
    final firstBoxRemaining =
        (await costLayerStore.getById('box-layer'))!.remainingQuantity;

    final second = await service.execute(
      batch: batch(),
      calculation: calculation(),
    );
    final secondMovements = await inventoryStore.getMovements();

    expect(first.cost.totalCost, 15000);
    expect(second.cost.totalCost, 15000);
    expect(second.execution.alreadyExecuted, isTrue);

    expect(
      secondMovements.where((item) => item.referenceId == batch().id),
      hasLength(3),
    );
    expect(
      secondMovements.length,
      firstMovements.length,
    );

    expect(
      (await costLayerStore.getById('date-layer'))!.remainingQuantity,
      firstDateRemaining,
    );
    expect(
      (await costLayerStore.getById('box-layer'))!.remainingQuantity,
      firstBoxRemaining,
    );
    expect(
      await allocationStore.getAllocations(referenceId: batch().id),
      hasLength(2),
    );

    expect(await batchStore.getById(batch().id), isNotNull);
    expect(await costStore.getByProductionId(batch().id), isNotNull);

    expect(first.execution.executed, isTrue);
  });
}
