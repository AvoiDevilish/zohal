import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/production_cost.dart';
import 'package:zohal_android_test/core/costing/production_cost_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProductionCostStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = ProductionCostStore.instance;
    await store.clear();
  });

  test('stores and retrieves production cost', () async {
    final cost = ProductionCost(
      productionId: 'production-1',
      materialCost: 10000,
      packagingCost: 5000,
      consumableCost: 0,
      totalCost: 15000,
      outputQuantity: 10,

      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(cost);

    final result = await store.getByProductionId('production-1');

    expect(result, isNotNull);
    expect(result!.totalCost, 15000);
    expect(result.unitCost, 1500);
  });

  test('prevents duplicate production cost', () async {
    final cost = ProductionCost(
      productionId: 'production-1',
      materialCost: 10000,
      packagingCost: 0,
      consumableCost: 0,
      totalCost: 10000,
      outputQuantity: 10,

      createdAt: DateTime(2026, 1, 1),
    );

    await store.add(cost);

    expect(() => store.add(cost), throwsStateError);
  });
}
