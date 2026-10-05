import '../storage/local_store.dart';
import 'production_cost.dart';

class ProductionCostStore {
  ProductionCostStore._();
  static final ProductionCostStore instance = ProductionCostStore._();
  static const _key = 'production_costs';

  Future<List<ProductionCost>> getAll() async {
    final rows = await LocalStore.instance.readList(_key);
    return rows.map(ProductionCost.fromMap).toList();
  }

  Future<ProductionCost?> getByProductionId(String productionId) async {
    final costs = await getAll();
    for (final cost in costs) {
      if (cost.productionId == productionId) return cost;
    }
    return null;
  }

  Future<void> add(ProductionCost cost) async {
    final existing = await getByProductionId(cost.productionId);
    if (existing != null) {
      if (!_same(existing, cost)) {
        throw StateError(
          'Production cost "${cost.productionId}" already exists with different data.',
        );
      }
      throw StateError(
        'Production cost "${cost.productionId}" already exists.',
      );
    }
    final costs = await getAll();
    costs.add(cost);
    await LocalStore.instance.writeList(
      _key,
      costs.map((item) => item.toMap()).toList(),
    );
  }

  bool _same(ProductionCost left, ProductionCost right) {
    return left.productionId == right.productionId &&
        (left.materialCost - right.materialCost).abs() <= 0.000001 &&
        (left.packagingCost - right.packagingCost).abs() <= 0.000001 &&
        (left.consumableCost - right.consumableCost).abs() <= 0.000001 &&
        (left.totalCost - right.totalCost).abs() <= 0.000001 &&
        left.outputQuantity == right.outputQuantity;
  }

  Future<void> clear() async => LocalStore.instance.remove(_key);
}