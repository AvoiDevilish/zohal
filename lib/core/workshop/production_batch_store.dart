import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../storage/local_store.dart';
import 'production_batch.dart';

class ProductionBatchStore {
  ProductionBatchStore._();

  static final ProductionBatchStore instance = ProductionBatchStore._();

  static const _key = 'production_batches';

  Future<List<ProductionBatch>> getAll() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getString(_key) == null) {
      final legacyData = prefs.getStringList(_key);
      if (legacyData != null) {
        final rows = legacyData
            .map((item) => Map<String, dynamic>.from(jsonDecode(item) as Map))
            .toList();
        await LocalStore.instance.writeList(_key, rows);
      }
    }

    final rows = await LocalStore.instance.readList(_key);
    return rows.map(ProductionBatch.fromMap).toList();
  }

  Future<ProductionBatch?> getById(String id) async {
    final batches = await getAll();
    for (final batch in batches) {
      if (batch.id == id) return batch;
    }
    return null;
  }

  Future<void> add(ProductionBatch batch) async {
    final existing = await getById(batch.id);
    if (existing != null) {
      throw StateError('Production batch "${batch.id}" already exists.');
    }
    final batches = await getAll();
    batches.add(batch);
    await LocalStore.instance.writeList(
      _key,
      batches.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> update(ProductionBatch batch) async {
    final batches = await getAll();
    final index = batches.indexWhere((item) => item.id == batch.id);
    if (index == -1) {
      throw StateError('Production batch "${batch.id}" پیدا نشد.');
    }
    batches[index] = batch;
    await LocalStore.instance.writeList(
      _key,
      batches.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async => LocalStore.instance.remove(_key);
}
