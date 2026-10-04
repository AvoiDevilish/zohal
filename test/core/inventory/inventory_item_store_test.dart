import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zohal_android_test/core/inventory/inventory_item.dart';
import 'package:zohal_android_test/core/inventory/inventory_item_catalog.dart';
import 'package:zohal_android_test/core/inventory/inventory_item_store.dart';

void main() {
  group('InventoryItemStore catalog', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await InventoryItemStore.instance.clear();
    });

    test('seeds the requested initial food and packaging items', () async {
      final store = InventoryItemStore.instance;
      await store.ensureSeeded();
      final items = await store.getItems();

      expect(items.length, initialInventoryItems.length);
      expect(items.where((item) => item.isFood).length, 12);
      expect(items.where((item) => !item.isFood).length, 7);
      expect(items.any((item) => item.name == 'خرما کبکاب'), isTrue);
      expect(items.any((item) => item.name == 'ظرف یک کیلویی'), isTrue);
    });

    test('stores food nutrition per 100 grams and kg conversion', () async {
      final store = InventoryItemStore.instance;
      await store.ensureSeeded();
      final almond = await store.getById('raw_almond');

      expect(almond, isNotNull);
      expect(almond!.unit, 'g');
      expect(almond.unitConversions.single.unit, 'kg');
      expect(almond.unitConversions.single.toBaseFactor, 1000);
      expect(almond.nutrition!.energyKcal, 579);
      expect(almond.nutrition!.proteinG, 21.15);
      expect(almond.nutrition!.totalFatG, 49.93);
    });

    test('packaging items use piece as the base unit and have no nutrition', () async {
      final store = InventoryItemStore.instance;
      await store.ensureSeeded();
      final container = await store.getById('pack_container_100g');

      expect(container, isNotNull);
      expect(container!.unit, 'piece');
      expect(container.isFood, isFalse);
      expect(container.nutrition, isNull);
    });

    test('seeding does not overwrite an existing custom catalog', () async {
      final store = InventoryItemStore.instance;
      final original = initialInventoryItems.first;

      await store.upsert(
        InventoryItem(
          id: original.id,
          name: 'custom date',
          type: original.type,
          unit: original.unit,
          minimumStock: original.minimumStock,
          category: original.category,
          englishName: original.englishName,
          isFood: original.isFood,
          unitConversions: original.unitConversions,
          nutrition: original.nutrition,
          notes: original.notes,
        ),
      );

      await store.ensureSeeded();

      final items = await store.getItems();
      expect(items.length, 1);
      expect(items.single.name, 'custom date');
    });
  });
}
