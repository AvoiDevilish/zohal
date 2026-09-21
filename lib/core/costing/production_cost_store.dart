import 'package:shared_preferences/shared_preferences.dart';

import 'production_cost.dart';

class ProductionCostStore {
  ProductionCostStore._();

  static final ProductionCostStore instance = ProductionCostStore._();

  static const _key = 'production_costs';

  Future<List<ProductionCost>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_key) ?? [];

    return data
        .map(
          (item) => ProductionCost.fromMap(
            Map<String, dynamic>.from(Uri.splitQueryString(item)),
          ),
        )
        .toList();
  }

  Future<ProductionCost?> getByProductionId(String productionId) async {
    final costs = await getAll();

    for (final cost in costs) {
      if (cost.productionId == productionId) {
        return cost;
      }
    }

    return null;
  }

  Future<void> add(ProductionCost cost) async {
    final existing = await getByProductionId(cost.productionId);

    if (existing != null) {
      throw StateError(
        'Production cost "${cost.productionId}" already exists.',
      );
    }

    final costs = await getAll();

    costs.add(cost);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      costs
          .map(
            (item) => item
                .toMap()
                .entries
                .map((e) => '${e.key}=${e.value}')
                .join('&'),
          )
          .toList(),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
