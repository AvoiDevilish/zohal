import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_allocation_store.dart';
import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/costing_method.dart';
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
      expiryDate: DateTime(2026, 2, 1),
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
        lotNumber: materialId == 'date' ? 'LOT-DATE-001' : null,
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

    final persistedBatch = await batchStore.getById(batch().id);
    expect(persistedBatch, isNotNull);
    expect(persistedBatch!.lotNumber, 'LOT-${batch().id}');
    expect(persistedBatch.expiryDate, DateTime(2026, 2, 1));
    expect(persistedBatch.sourceLotNumbers, ['LOT-DATE-001']);
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
      await allocationStore.getAllocations(),
      hasLength(2),
    );

    expect(await batchStore.getById(batch().id), isNotNull);
    expect(await costStore.getByProductionId(batch().id), isNotNull);

    expect(first.execution.executed, isTrue);
  });

  test(
    'does not consume costing when inventory execution fails',
    () async {
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

      expect(
        () => service.execute(
          batch: batch(),
          calculation: calculation(),
        ),
        throwsStateError,
      );

      expect(
        await allocationStore.getAllocations(
          referenceId: batch().id,
        ),
        isEmpty,
      );
      expect(
        (await costLayerStore.getById('date-layer'))!.remainingQuantity,
        2000,
      );
      expect(
        (await costLayerStore.getById('box-layer'))!.remainingQuantity,
        20,
      );
      expect(
        await costStore.getByProductionId(batch().id),
        isNull,
      );
      expect(
        await batchStore.getById(batch().id),
        isNull,
      );
    },
  );

  test(
    'preflights FEFO so expired costing does not consume inventory',
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

      await costLayerStore.add(
        CostLayer(
          id: 'expired-date-layer',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 2000,
          remainingQuantity: 2000,
          unit: 'g',
          unitCost: 10,
          createdAt: DateTime(2026, 1, 1),
          purchaseId: 'purchase-expired-date',
          lotNumber: 'LOT-EXPIRED',
          expiryDate: DateTime(2026, 6, 30),
        ),
      );
      await addCostLayer(
        id: 'box-layer',
        materialId: 'box',
        materialName: 'ظرف',
        quantity: 20,
        unit: 'unit',
        unitCost: 500,
      );

      expect(
        () => service.execute(
          batch: batch(),
          calculation: calculation(),
          costingMethod: CostingMethod.fefo,
          now: DateTime(2026, 7, 1),
        ),
        throwsStateError,
      );

      expect(await inventoryStore.getStock('date'), 2000);
      expect(await inventoryStore.getStock('box'), 20);
      expect(
        (await inventoryStore.getMovements())
            .where((item) => item.referenceId == batch().id),
        isEmpty,
      );
      expect(
        await allocationStore.getAllocations(referenceId: batch().id),
        isEmpty,
      );
      expect(
        (await costLayerStore.getById('expired-date-layer'))!.remainingQuantity,
        2000,
      );
      expect(await costStore.getByProductionId(batch().id), isNull);
      expect(await batchStore.getById(batch().id), isNull);
    },
  );

  test(
    'executes multi-lot FEFO through production workflow and retry stays idempotent',
    () async {
      await addInventoryStock(
        itemId: 'date',
        itemName: 'خرما',
        quantity: 1000,
        unit: 'g',
      );
      await addInventoryStock(
        itemId: 'box',
        itemName: 'ظرف',
        quantity: 20,
        unit: 'unit',
        itemType: 'packaging',
      );

      await costLayerStore.add(
        CostLayer(
          id: 'fefo-late',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 600,
          remainingQuantity: 600,
          unit: 'g',
          unitCost: 30,
          createdAt: DateTime(2026, 1, 2),
          purchaseId: 'purchase-fefo-late',
          lotNumber: 'LOT-LATE',
          expiryDate: DateTime(2026, 6, 30),
        ),
      );
      await costLayerStore.add(
        CostLayer(
          id: 'fefo-early',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 400,
          remainingQuantity: 400,
          unit: 'g',
          unitCost: 20,
          createdAt: DateTime(2026, 1, 3),
          purchaseId: 'purchase-fefo-early',
          lotNumber: 'LOT-EARLY',
          expiryDate: DateTime(2026, 3, 31),
        ),
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
        costingMethod: CostingMethod.fefo,
        now: DateTime(2026, 1, 1),
      );

      expect(first.cost.totalCost, 31000);
      expect(first.cost.materialCost, 26000);
      expect(first.cost.packagingCost, 5000);
      expect(first.execution.batch.sourceLotNumbers, [
        'LOT-EARLY',
        'LOT-LATE',
      ]);

      final allocations = await allocationStore.getAllocations();
      expect(allocations, hasLength(3));

      final dateAllocations = allocations
          .where((allocation) => allocation.materialId == 'date')
          .toList()
        ..sort((a, b) => a.costLayerId.compareTo(b.costLayerId));
      expect(dateAllocations, hasLength(2));
      expect(
        dateAllocations
            .firstWhere((allocation) => allocation.costLayerId == 'fefo-early')
            .quantity,
        400,
      );
      expect(
        dateAllocations
            .firstWhere((allocation) => allocation.costLayerId == 'fefo-late')
            .quantity,
        600,
      );

      final second = await service.execute(
        batch: batch(),
        calculation: calculation(),
        costingMethod: CostingMethod.fefo,
        now: DateTime(2026, 1, 1),
      );

      expect(second.execution.alreadyExecuted, isTrue);
      expect(second.cost.totalCost, first.cost.totalCost);
      expect(await allocationStore.getAllocations(), hasLength(3));
      expect(
        (await costLayerStore.getById('fefo-early'))!.remainingQuantity,
        0,
      );
      expect(
        (await costLayerStore.getById('fefo-late'))!.remainingQuantity,
        0,
      );
      expect(
        (await costLayerStore.getById('box-layer'))!.remainingQuantity,
        10,
      );
    },
  );

  test(
    'allows expired FEFO lot only with explicit workflow override',
    () async {
      await addInventoryStock(
        itemId: 'date',
        itemName: 'خرما',
        quantity: 1000,
        unit: 'g',
      );
      await addInventoryStock(
        itemId: 'box',
        itemName: 'ظرف',
        quantity: 20,
        unit: 'unit',
        itemType: 'packaging',
      );

      await costLayerStore.add(
        CostLayer(
          id: 'expired-date-layer',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 1000,
          remainingQuantity: 1000,
          unit: 'g',
          unitCost: 10,
          createdAt: DateTime(2026, 1, 1),
          purchaseId: 'purchase-expired-date',
          lotNumber: 'LOT-EXPIRED',
          expiryDate: DateTime(2026, 6, 30),
        ),
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
        costingMethod: CostingMethod.fefo,
        allowExpiredLots: true,
        now: DateTime(2026, 7, 1),
      );

      expect(result.execution.executed, isTrue);
      expect(result.cost.totalCost, 15000);
      expect(result.execution.batch.sourceLotNumbers, ['LOT-EXPIRED']);
      expect(
        (await costLayerStore.getById('expired-date-layer'))!.remainingQuantity,
        0,
      );
      expect(
        await inventoryStore.getStock('date'),
        0,
      );
    },
  );


}
