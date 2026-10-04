import '../storage/local_store.dart';
import 'product_variant.dart';
import 'product_variant_catalog.dart';

class ProductVariantStore {
  ProductVariantStore._();

  static final ProductVariantStore instance = ProductVariantStore._();

  static const String _storageKey = 'product_variants';

  Future<List<ProductVariant>> getAll() async {
    final rows = await LocalStore.instance.readList(_storageKey);
    final items = rows.map(ProductVariant.fromMap).toList()
      ..sort((a, b) => a.packageGrams.compareTo(b.packageGrams));
    return items;
  }

  Future<ProductVariant?> getById(String id) async {
    final items = await getAll();
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> ensureSeeded() async {
    final items = await getAll();
    if (items.isNotEmpty) return;

    await LocalStore.instance.writeList(
      _storageKey,
      initialProductVariants.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> upsert(ProductVariant item) async {
    final items = await getAll();
    final index = items.indexWhere((current) => current.id == item.id);

    if (index == -1) {
      items.add(item);
    } else {
      items[index] = item;
    }

    await LocalStore.instance.writeList(
      _storageKey,
      items.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
