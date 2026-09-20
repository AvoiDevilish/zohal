import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/purchases/purchase.dart';
import 'package:zohal_android_test/core/purchases/purchase_service.dart';
import 'package:zohal_android_test/core/purchases/purchase_store.dart';
import 'package:zohal_android_test/core/suppliers/supplier.dart';
import 'package:zohal_android_test/core/suppliers/supplier_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PurchaseStore purchaseStore;
  late InventoryStore inventoryStore;
  late SupplierStore supplierStore;
  late CostLayerStore costLayerStore;
  late PurchaseService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    purchaseStore = PurchaseStore.instance;
    inventoryStore = InventoryStore.instance;
    supplierStore = SupplierStore.instance;
    costLayerStore = CostLayerStore.instance;

    await purchaseStore.clear();
    await inventoryStore.clear();
    await supplierStore.clear();
    await costLayerStore.clear();

    service = PurchaseService(
      purchaseStore: purchaseStore,
      inventoryStore: inventoryStore,
      supplierStore: supplierStore,
      costLayerStore: costLayerStore,
    );
  });

  test('registers purchase and increases inventory', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final purchase = Purchase(
      id: 'purchase-1',
      materialId: 'peanut',
      materialName: 'بادام زمینی',
      quantity: 20,
      unit: 'کیلوگرم',
      unitPrice: 250000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    final result = await service.registerPurchase(purchase);

    expect(result.purchase.supplierId, 'supplier-gholami');
    expect(result.purchase.supplierName, 'آقای غلامی');
    expect(await inventoryStore.getStock('peanut'), 20);
    expect(result.totalPrice, 5000000);

    expect(result.costLayer.materialId, 'peanut');
    expect(result.costLayer.quantity, 20000);
    expect(result.costLayer.remainingQuantity, 20000);
    expect(result.costLayer.unit, 'g');
    expect(result.costLayer.unitCost, 250);
    expect(result.costLayer.purchaseId, 'purchase-1');
  });

  test('keeps separate purchase events and accumulates inventory', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final firstPurchase = Purchase(
      id: 'purchase-1',
      materialId: 'walnut',
      materialName: 'گردوی ایرانی خرد شده',
      quantity: 5,
      unit: 'کیلوگرم',
      unitPrice: 800000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    final secondPurchase = Purchase(
      id: 'purchase-2',
      materialId: 'walnut',
      materialName: 'گردوی ایرانی خرد شده',
      quantity: 3,
      unit: 'کیلوگرم',
      unitPrice: 850000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 2),
    );

    await service.registerPurchase(firstPurchase);
    await service.registerPurchase(secondPurchase);

    final purchases = await purchaseStore.getPurchases();

    expect(purchases, hasLength(2));
    expect(await inventoryStore.getStock('walnut'), 8);
  });

  test('creates a separate cost layer for each purchase', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final firstPurchase = Purchase(
      id: 'purchase-1',
      materialId: 'walnut',
      materialName: 'گردوی ایرانی خرد شده',
      quantity: 5,
      unit: 'کیلوگرم',
      unitPrice: 800000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    final secondPurchase = Purchase(
      id: 'purchase-2',
      materialId: 'walnut',
      materialName: 'گردوی ایرانی خرد شده',
      quantity: 3,
      unit: 'کیلوگرم',
      unitPrice: 850000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 2),
    );

    await service.registerPurchase(firstPurchase);
    await service.registerPurchase(secondPurchase);

    final layers = await costLayerStore.getLayers(materialId: 'walnut');

    expect(layers, hasLength(2));

    expect(layers[0].quantity, 5000);
    expect(layers[0].remainingQuantity, 5000);
    expect(layers[0].unit, 'g');
    expect(layers[0].unitCost, 800);

    expect(layers[1].quantity, 3000);
    expect(layers[1].remainingQuantity, 3000);
    expect(layers[1].unit, 'g');
    expect(layers[1].unitCost, closeTo(850, 0.000001));
  });

  test('registering the same purchase twice is idempotent', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final purchase = Purchase(
      id: 'purchase-idempotent',
      materialId: 'peanut',
      materialName: 'بادام زمینی',
      quantity: 10,
      unit: 'کیلوگرم',
      unitPrice: 250000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    final first = await service.registerPurchase(purchase);
    final second = await service.registerPurchase(purchase);

    expect(first.alreadyExecuted, isFalse);
    expect(second.alreadyExecuted, isTrue);

    expect(await inventoryStore.getStock('peanut'), 10);

    final purchases = await purchaseStore.getPurchases();
    expect(purchases, hasLength(1));

    final layers = await costLayerStore.getLayers(materialId: 'peanut');
    expect(layers, hasLength(1));
    expect(layers.single.remainingQuantity, 10000);
  });

  test('stores purchase price on inventory movement for costing', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final purchase = Purchase(
      id: 'purchase-1',
      materialId: 'cashew',
      materialName: 'بادام هندی',
      quantity: 10,
      unit: 'کیلوگرم',
      unitPrice: 1200000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    final result = await service.registerPurchase(purchase);

    expect(result.movement.unitCost, 1200000);
  });

  test('rejects purchase when supplier does not exist', () async {
    final purchase = Purchase(
      id: 'purchase-1',
      materialId: 'peanut',
      materialName: 'بادام زمینی',
      quantity: 10,
      unit: 'کیلوگرم',
      unitPrice: 250000,
      supplierId: 'supplier-missing',
      supplierName: 'تأمین‌کننده ناموجود',
      purchaseDate: DateTime(2026, 1, 1),
    );

    expect(
      () => service.registerPurchase(purchase),
      throwsA(isA<StateError>()),
    );

    expect(await inventoryStore.getStock('peanut'), 0);
  });

  test('rejects purchase from inactive supplier', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);
    await supplierStore.deactivate(supplier.id);

    final purchase = Purchase(
      id: 'purchase-1',
      materialId: 'peanut',
      materialName: 'بادام زمینی',
      quantity: 10,
      unit: 'کیلوگرم',
      unitPrice: 250000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    expect(
      () => service.registerPurchase(purchase),
      throwsA(isA<StateError>()),
    );

    expect(await inventoryStore.getStock('peanut'), 0);
  });

  test('preserves supplier name as historical snapshot', () async {
    final supplier = Supplier(id: 'supplier-gholami', name: 'آقای غلامی');

    await supplierStore.add(supplier);

    final purchase = Purchase(
      id: 'purchase-1',
      materialId: 'almond',
      materialName: 'بادام درختی',
      quantity: 4,
      unit: 'کیلوگرم',
      unitPrice: 900000,
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: DateTime(2026, 1, 1),
    );

    await service.registerPurchase(purchase);

    final stored = await purchaseStore.getPurchases();

    expect(stored.single.supplierId, 'supplier-gholami');
    expect(stored.single.supplierName, 'آقای غلامی');
  });
}
