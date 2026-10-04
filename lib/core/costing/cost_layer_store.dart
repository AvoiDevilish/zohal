import '../storage/local_store.dart';
import 'cost_layer.dart';
import 'cost_layer_validator.dart';

class CostLayerStore {
  CostLayerStore._();
  static final CostLayerStore instance = CostLayerStore._();
  static const String _storageKey = 'cost_layers';

  Future<List<CostLayer>> getLayers({String? materialId}) async {
    final rows = await LocalStore.instance.readList(_storageKey);
    var layers = rows.map(CostLayer.fromMap).toList();
    if (materialId != null) {
      layers = layers.where((layer) => layer.materialId == materialId).toList();
    }
    layers.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return layers;
  }

  Future<CostLayer?> getById(String id) async {
    final layers = await getLayers();
    for (final layer in layers) {
      if (layer.id == id) return layer;
    }
    return null;
  }

  Future<void> add(CostLayer layer) async {
    const validator = CostLayerValidator();
    validator.validate(layer);
    final layers = await getLayers();
    if (layers.any((item) => item.id == layer.id)) {
      throw StateError('Cost layer with id "${layer.id}" already exists.');
    }
    layers.add(layer);
    await LocalStore.instance.writeList(
      _storageKey,
      layers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> update(CostLayer layer) async => updateAll([layer]);

  Future<void> updateAll(List<CostLayer> updatedLayers) async {
    if (updatedLayers.isEmpty) return;
    const validator = CostLayerValidator();
    final ids = <String>{};

    for (final layer in updatedLayers) {
      validator.validate(layer);
      if (!ids.add(layer.id)) {
        throw StateError('Duplicate cost layer id "${layer.id}" in batch.');
      }
    }

    final layers = await getLayers();
    final indexById = {
      for (var index = 0; index < layers.length; index++) layers[index].id: index,
    };

    for (final layer in updatedLayers) {
      if (!indexById.containsKey(layer.id)) {
        throw StateError('Cost layer with id "${layer.id}" does not exist.');
      }
    }

    for (final layer in updatedLayers) {
      layers[indexById[layer.id]!] = layer;
    }

    await LocalStore.instance.writeList(
      _storageKey,
      layers.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async => LocalStore.instance.remove(_storageKey);
}
