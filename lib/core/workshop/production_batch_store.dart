import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'production_batch.dart';

class ProductionBatchStore {
  ProductionBatchStore._();

  static final ProductionBatchStore instance =
      ProductionBatchStore._();

  static const _key = 'production_batches';

  Future<List<ProductionBatch>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getStringList(_key) ?? [];

    return data
        .map(
          (item) => ProductionBatch.fromMap(
            Map<String, dynamic>.from(
              jsonDecode(item) as Map,
            ),
          ),
        )
        .toList();
  }

  Future<ProductionBatch?> getById(String id) async {
    final batches = await getAll();

    for (final batch in batches) {
      if (batch.id == id) {
        return batch;
      }
    }

    return null;
  }

  Future<void> add(ProductionBatch batch) async {
    final existing = await getById(batch.id);

    if (existing != null) {
      throw StateError(
        'Production batch "${batch.id}" already exists.',
      );
    }

    final batches = await getAll();

    batches.add(batch);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setStringList(
      _key,
      batches
          .map(
            (item) => jsonEncode(item.toMap()),
          )
          .toList(),
    );
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_key);
  }
}
