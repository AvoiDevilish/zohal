import '../storage/local_store.dart';
import 'inventory_item.dart';
import 'inventory_item_catalog.dart';

class InventoryItemStore {
  InventoryItemStore._();

  static final InventoryItemStore instance = InventoryItemStore._();

  static const String _storageKey = 'inventory_items';

  Future<List<InventoryItem>> getItems() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<InventoryItem?> getById(String id) async {
    final items = await getItems();

    for (final item in items) {
      if (item.id == id) return item;
    }

    return null;
  }

  Future<void> ensureSeeded() async {
    final items = await getItems();
    if (items.isNotEmpty) return;

    await LocalStore.instance.writeList(
      _storageKey,
      initialInventoryItems.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> upsert(InventoryItem item) async {
    final items = await getItems();
    final index = items.indexWhere((current) => current.id == item.id);

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await LocalStore.instance.writeList(
      _storageKey,
      items.map((current) => current.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
