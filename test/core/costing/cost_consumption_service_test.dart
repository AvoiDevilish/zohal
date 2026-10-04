import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/costing/cost_allocation.dart';
import 'package:zohal_android_test/core/costing/cost_allocation_store.dart';
import 'package:zohal_android_test/core/costing/cost_consumption_service.dart';
import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/costing/costing_method.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CostLayerStore layerStore;
  late CostAllocationStore allocationStore;
  late CostConsumptionService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    layerStore = CostLayerStore.instance;
    allocationStore = CostAllocationStore.instance;

    await layerStore.clear();
    await allocationStore.clear();

    service = CostConsumptionService(
      costLayerStore: layerStore,
      allocationStore: allocationStore,
    );
  });

  test(
    'consumes FIFO across multiple cost layers and updates remaining quantities',
    () async {
      await layerStore.add(
        CostLayer(
          id: 'layer-1',
          materialId: 'date',
          materialName: 'خرمای خشت',
          quantity: 10000,
          remainingQuantity: 10000,
          unit: 'g',
          unitCost: 12,
          createdAt: DateTime(2026, 1, 1),
          purchaseId: 'purchase-1',
        ),
      );

      await layerStore.add(
        CostLayer(
          id: 'layer-2',
          materialId: 'date',
          materialName: 'خرمای خشت',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'g',
          unitCost: 30,
          createdAt: DateTime(2026, 1, 2),
          purchaseId: 'purchase-2',
        ),
      );

      final result = await service.consume(
        referenceId: 'production-batch-1',
        materialId: 'date',
        quantity: 12000,
      );

      expect(result.alreadyConsumed, isFalse);
      expect(result.requestedQuantity, 12000);
      expect(result.totalCost, 180000);
      expect(result.averageUnitCost, closeTo(15, 0.001));

      expect(result.allocations, hasLength(2));

      expect(result.allocations[0].costLayerId, 'layer-1');
      expect(result.allocations[0].quantity, 10000);
      expect(result.allocations[0].unitCost, 12);
      expect(result.allocations[0].totalCost, 120000);

      expect(result.allocations[1].costLayerId, 'layer-2');
      expect(result.allocations[1].quantity, 2000);
      expect(result.allocations[1].unitCost, 30);
      expect(result.allocations[1].totalCost, 60000);

      final layer1 = await layerStore.getById('layer-1');
      final layer2 = await layerStore.getById('layer-2');

      expect(layer1!.remainingQuantity, 0);
      expect(layer2!.remainingQuantity, 3000);

      final savedAllocations = await allocationStore.getAllocations(
        referenceId: 'production-batch-1',
      );

      expect(savedAllocations, hasLength(2));
    },
  );

  test(
    'rejects consumption when available cost layers are insufficient',
    () async {
      await layerStore.add(
        CostLayer(
          id: 'layer-1',
          materialId: 'date',
          materialName: 'خرمای خشت',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'g',
          unitCost: 12,
          createdAt: DateTime(2026, 1, 1),
          purchaseId: 'purchase-1',
        ),
      );

      expect(
        () => service.consume(
          referenceId: 'production-batch-2',
          materialId: 'date',
          quantity: 6000,
        ),
        throwsStateError,
      );

      final layer = await layerStore.getById('layer-1');

      expect(layer!.remainingQuantity, 5000);

      final allocations = await allocationStore.getAllocations(
        referenceId: 'production-batch-2',
      );

      expect(allocations, isEmpty);
    },
  );

  test('registering the same consumption twice is idempotent', () async {
    await layerStore.add(
      CostLayer(
        id: 'layer-1',
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 10000,
        remainingQuantity: 10000,
        unit: 'g',
        unitCost: 12,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'purchase-1',
      ),
    );

    final first = await service.consume(
      referenceId: 'production-batch-3',
      materialId: 'date',
      quantity: 4000,
    );

    final second = await service.consume(
      referenceId: 'production-batch-3',
      materialId: 'date',
      quantity: 4000,
    );

    expect(first.alreadyConsumed, isFalse);
    expect(second.alreadyConsumed, isTrue);

    expect(second.totalCost, first.totalCost);
    expect(second.requestedQuantity, first.requestedQuantity);

    final layer = await layerStore.getById('layer-1');

    expect(layer!.remainingQuantity, 6000);

    final allocations = await allocationStore.getAllocations(
      referenceId: 'production-batch-3',
    );

    expect(allocations, hasLength(1));
    expect(allocations.first.quantity, 4000);
  });

  test('supports weighted average costing', () async {
    await layerStore.add(
      CostLayer(
        id: 'layer-1',
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 10000,
        remainingQuantity: 10000,
        unit: 'g',
        unitCost: 10,
        createdAt: DateTime(2026, 1, 1),
        purchaseId: 'purchase-1',
      ),
    );

    await layerStore.add(
      CostLayer(
        id: 'layer-2',
        materialId: 'date',
        materialName: 'خرمای خشت',
        quantity: 5000,
        remainingQuantity: 5000,
        unit: 'g',
        unitCost: 20,
        createdAt: DateTime(2026, 1, 2),
        purchaseId: 'purchase-2',
      ),
    );

    final result = await service.consume(
      referenceId: 'production-batch-4',
      materialId: 'date',
      quantity: 3000,
      method: CostingMethod.weightedAverage,
    );

    expect(result.totalCost, 40000);
    expect(result.averageUnitCost, closeTo(13.333, 0.001));
    expect(result.allocations, hasLength(1));

    final layer1 = await layerStore.getById('layer-1');
    final layer2 = await layerStore.getById('layer-2');

    expect(layer1!.remainingQuantity, 10000);
    expect(layer2!.remainingQuantity, 5000);
  });

  test(
    'repairs a partially persisted consumption from allocations without double-decrementing',
    () async {
      await layerStore.add(
        CostLayer(
          id: 'layer-recovery',
          materialId: 'date',
          materialName: 'خرمای خشت',
          quantity: 10000,
          remainingQuantity: 10000,
          unit: 'g',
          unitCost: 12,
          createdAt: DateTime(2026, 1, 1),
          purchaseId: 'purchase-recovery',
        ),
      );

      await allocationStore.add(
        CostAllocation(
          id: 'cost-allocation-recovery-0',
          materialId: 'date',
          materialName: 'خرمای خشت',
          costLayerId: 'layer-recovery',
          quantity: 4000,
          unit: 'g',
          unitCost: 12,
          totalCost: 48000,
          referenceId: 'production-recovery',
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      final result = await service.consume(
        referenceId: 'production-recovery',
        materialId: 'date',
        quantity: 4000,
      );

      expect(result.alreadyConsumed, isTrue);
      expect(result.totalCost, 48000);

      final layer = await layerStore.getById('layer-recovery');
      expect(layer!.remainingQuantity, 6000);

      final allocations = await allocationStore.getAllocations(
        referenceId: 'production-recovery',
      );
      expect(allocations, hasLength(1));

      final retry = await service.consume(
        referenceId: 'production-recovery',
        materialId: 'date',
        quantity: 4000,
      );
      expect(retry.alreadyConsumed, isTrue);
      expect((await layerStore.getById('layer-recovery'))!.remainingQuantity, 6000);
    },
  );

}
