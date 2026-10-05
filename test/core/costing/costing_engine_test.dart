import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/costing/costing_engine.dart';
import 'package:zohal_android_test/core/costing/costing_method.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CostLayerStore store;
  const engine = CostingEngine();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    store = CostLayerStore.instance;
    await store.clear();
  });

  CostLayer layer({
    required String id,
    required double quantity,
    required double unitCost,
    required DateTime createdAt,
  }) {
    return CostLayer(
      id: id,
      materialId: 'date',
      materialName: 'خرما',
      quantity: quantity,
      remainingQuantity: quantity,
      unit: 'گرم',
      unitCost: unitCost,
      createdAt: createdAt,
    );
  }

  test('stores and retrieves cost layers', () async {
    final item = layer(
      id: 'layer-1',
      quantity: 10000,
      unitCost: 120,
      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(item);

    final result = await store.getById('layer-1');

    expect(result, isNotNull);
    expect(result!.quantity, 10000);
    expect(result.remainingQuantity, 10000);
    expect(result.unitCost, 120);
  });

  test('FIFO consumes oldest layer first', () {
    final result = engine.calculate(
      layers: [
        layer(
          id: 'old',
          quantity: 10000,
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
        ),
        layer(
          id: 'new',
          quantity: 10000,
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
        ),
      ],
      quantity: 7000,
    );

    expect(result.totalCost, 700000);
    expect(result.allocations, hasLength(1));
    expect(result.allocations.first.layerId, 'old');
    expect(result.allocations.first.quantity, 7000);
    expect(result.averageUnitCost, 100);
  });

  test('FEFO consumes the earliest expiring lot first', () {
    final result = engine.calculate(
      layers: [
        CostLayer(
          id: 'later-expiry',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
          lotNumber: 'LOT-LATE',
          expiryDate: DateTime(2026, 12, 31),
        ),
        CostLayer(
          id: 'earlier-expiry',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
          lotNumber: 'LOT-EARLY',
          expiryDate: DateTime(2026, 6, 30),
        ),
      ],
      quantity: 3000,
      method: CostingMethod.fefo,
    );

    expect(result.allocations, hasLength(1));
    expect(result.allocations.first.layerId, 'earlier-expiry');
    expect(result.allocations.first.quantity, 3000);
    expect(result.totalCost, 480000);
  });

  test('FEFO crosses expiry layers and uses creation time as tie breaker', () {
    final result = engine.calculate(
      layers: [
        CostLayer(
          id: 'tie-newer',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 2000,
          remainingQuantity: 2000,
          unit: 'گرم',
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
          expiryDate: DateTime(2026, 6, 30),
        ),
        CostLayer(
          id: 'tie-older',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 2000,
          remainingQuantity: 2000,
          unit: 'گرم',
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 6, 30),
        ),
        CostLayer(
          id: 'no-expiry',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 200,
          createdAt: DateTime(2025, 12, 1),
        ),
      ],
      quantity: 3000,
      method: CostingMethod.fefo,
    );

    expect(result.allocations, hasLength(2));
    expect(result.allocations[0].layerId, 'tie-older');
    expect(result.allocations[0].quantity, 2000);
    expect(result.allocations[1].layerId, 'tie-newer');
    expect(result.allocations[1].quantity, 1000);
  });

  test('FEFO rejects expired lots by default', () {
    final now = DateTime(2026, 7, 1);

    expect(
      () => engine.calculate(
        layers: [
          CostLayer(
            id: 'expired',
            materialId: 'date',
            materialName: 'خرما',
            quantity: 5000,
            remainingQuantity: 5000,
            unit: 'گرم',
            unitCost: 100,
            createdAt: DateTime(2026, 1, 1),
            lotNumber: 'LOT-EXPIRED',
            expiryDate: DateTime(2026, 6, 30),
          ),
          CostLayer(
            id: 'valid',
            materialId: 'date',
            materialName: 'خرما',
            quantity: 5000,
            remainingQuantity: 5000,
            unit: 'گرم',
            unitCost: 160,
            createdAt: DateTime(2026, 1, 2),
            lotNumber: 'LOT-VALID',
            expiryDate: DateTime(2026, 12, 31),
          ),
        ],
        quantity: 3000,
        method: CostingMethod.fefo,
        now: now,
      ),
      isNot(throwsA(anything)),
    );

    final result = engine.calculate(
      layers: [
        CostLayer(
          id: 'expired',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
          lotNumber: 'LOT-EXPIRED',
          expiryDate: DateTime(2026, 6, 30),
        ),
        CostLayer(
          id: 'valid',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 160,
          createdAt: DateTime(2026, 1, 2),
          lotNumber: 'LOT-VALID',
          expiryDate: DateTime(2026, 12, 31),
        ),
      ],
      quantity: 3000,
      method: CostingMethod.fefo,
      now: now,
    );

    expect(result.allocations, hasLength(1));
    expect(result.allocations.first.layerId, 'valid');
  });

  test('FEFO allows expired lots only with explicit override', () {
    final result = engine.calculate(
      layers: [
        CostLayer(
          id: 'expired',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
          expiryDate: DateTime(2026, 6, 30),
        ),
        CostLayer(
          id: 'valid',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 160,
          createdAt: DateTime(2026, 1, 2),
          expiryDate: DateTime(2026, 12, 31),
        ),
      ],
      quantity: 3000,
      method: CostingMethod.fefo,
      allowExpiredLots: true,
      now: DateTime(2026, 7, 1),
    );

    expect(result.allocations.first.layerId, 'expired');
    expect(result.totalCost, 300000);
  });

  test('FEFO fails when only expired lots can satisfy the request', () {
    expect(
      () => engine.calculate(
        layers: [
          CostLayer(
            id: 'expired',
            materialId: 'date',
            materialName: 'خرما',
            quantity: 5000,
            remainingQuantity: 5000,
            unit: 'گرم',
            unitCost: 100,
            createdAt: DateTime(2026, 1, 1),
            expiryDate: DateTime(2026, 6, 30),
          ),
        ],
        quantity: 1000,
        method: CostingMethod.fefo,
        now: DateTime(2026, 7, 1),
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('FEFO puts lots without expiry after dated lots', () {
    final result = engine.calculate(
      layers: [
        layer(
          id: 'no-expiry',
          quantity: 5000,
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
        ),
        CostLayer(
          id: 'dated',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 5000,
          remainingQuantity: 5000,
          unit: 'گرم',
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
          expiryDate: DateTime(2027, 1, 1),
        ),
      ],
      quantity: 1000,
      method: CostingMethod.fefo,
    );

    expect(result.allocations.first.layerId, 'dated');
  });

  test('FIFO crosses layers when first layer is insufficient', () {
    final result = engine.calculate(
      layers: [
        layer(
          id: 'old',
          quantity: 5000,
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
        ),
        layer(
          id: 'new',
          quantity: 10000,
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
        ),
      ],
      quantity: 8000,
    );

    expect(result.totalCost, 980000);
    expect(result.allocations, hasLength(2));

    expect(result.allocations[0].layerId, 'old');
    expect(result.allocations[0].quantity, 5000);

    expect(result.allocations[1].layerId, 'new');
    expect(result.allocations[1].quantity, 3000);

    expect(result.averageUnitCost, 122.5);
  });

  test('FIFO rejects insufficient quantity', () {
    expect(
      () => engine.calculate(
        layers: [
          layer(
            id: 'layer-1',
            quantity: 5000,
            unitCost: 100,
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        quantity: 6000,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('weighted average calculates blended unit cost', () {
    final result = engine.calculate(
      layers: [
        layer(
          id: 'first',
          quantity: 10000,
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
        ),
        layer(
          id: 'second',
          quantity: 5000,
          unitCost: 160,
          createdAt: DateTime(2026, 1, 10),
        ),
      ],
      quantity: 6000,
      method: CostingMethod.weightedAverage,
    );

    expect(result.averageUnitCost, closeTo(120, 0.000001));
    expect(result.totalCost, closeTo(720000, 0.000001));
    expect(result.allocations, hasLength(1));
    expect(result.allocations.first.layerId, 'weighted-average');
  });

  test('rejects layers from different materials', () {
    final first = layer(
      id: 'date',
      quantity: 1000,
      unitCost: 100,
      createdAt: DateTime(2026, 1, 1),
    );

    final second = CostLayer(
      id: 'walnut',
      materialId: 'walnut',
      materialName: 'گردو',
      quantity: 1000,
      remainingQuantity: 1000,
      unit: 'گرم',
      unitCost: 500,
      createdAt: DateTime(2026, 1, 2),
    );

    expect(
      () => engine.calculate(layers: [first, second], quantity: 100),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects invalid cost layer values', () async {
    expect(
      () => store.add(
        CostLayer(
          id: 'bad',
          materialId: 'date',
          materialName: 'خرما',
          quantity: 1000,
          remainingQuantity: 1200,
          unit: 'گرم',
          unitCost: 100,
          createdAt: DateTime(2026, 1, 1),
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('persists remaining quantity after layer update', () async {
    final item = layer(
      id: 'layer-1',
      quantity: 10000,
      unitCost: 120,
      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(item);

    await store.update(item.copyWith(remainingQuantity: 4000));

    final result = await store.getById('layer-1');

    expect(result!.remainingQuantity, 4000);
    expect(result.remainingCost, 480000);
  });
}
