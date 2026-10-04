import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/sales/product_variant_catalog.dart';
import 'package:zohal_android_test/core/sales/product_variant_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProductVariantStore.instance.clear();
  });

  test('seeds three flavors across four package sizes', () async {
    final store = ProductVariantStore.instance;
    await store.ensureSeeded();
    final items = await store.getAll();

    expect(items.length, 12);
    expect(items.map((item) => item.flavor).toSet(), {
      'آرد نخودچی',
      'زنجبیل',
      'ساده (پودر نشاسته ذرت)',
    });
    expect(items.map((item) => item.packageGrams).toSet(), {
      100,
      400,
      500,
      1000,
    });
  });

  test('initial prices match current selling prices', () async {
    final store = ProductVariantStore.instance;
    await store.ensureSeeded();

    final items = await store.getAll();

    for (final item in items.where((item) => item.packageGrams == 100)) {
      expect(item.currentSellingPrice, 150000);
    }
    for (final item in items.where((item) => item.packageGrams == 400)) {
      expect(item.currentSellingPrice, 780000);
    }
    for (final item in items.where((item) => item.packageGrams == 500)) {
      expect(item.currentSellingPrice, 900000);
    }
    for (final item in items.where((item) => item.packageGrams == 1000)) {
      expect(item.currentSellingPrice, 1750000);
    }
  });

  test('price can be edited without changing product identity', () async {
    final store = ProductVariantStore.instance;
    await store.ensureSeeded();
    final original = (await store.getAll()).first;

    await store.upsert(original.copyWith(currentSellingPrice: 165000));
    final updated = await store.getById(original.id);

    expect(updated, isNotNull);
    expect(updated!.id, original.id);
    expect(updated.flavor, original.flavor);
    expect(updated.packageGrams, original.packageGrams);
    expect(updated.currentSellingPrice, 165000);
  });
}
