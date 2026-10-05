import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/customers/customer.dart';
import 'package:zohal_android_test/core/customers/customer_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_movement.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/sales/sale.dart';
import 'package:zohal_android_test/core/sales/sale_item.dart';
import 'package:zohal_android_test/core/sales/sale_service.dart';
import 'package:zohal_android_test/core/sales/sale_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SaleStore saleStore;
  late InventoryStore inventoryStore;
  late CustomerStore customerStore;
  late SaleService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    saleStore = SaleStore.instance;
    inventoryStore = InventoryStore.instance;
    customerStore = CustomerStore.instance;

    await saleStore.clear();
    await inventoryStore.clear();
    await customerStore.clear();

    service = SaleService(
      saleStore: saleStore,
      inventoryStore: inventoryStore,
      customerStore: customerStore,
    );
  });

  test('registers sale and decreases inventory', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'initial-stock-1',
        itemId: 'energy-100-ginger',
        itemName: 'انرژی بار ۱۰۰g زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 20,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
    );

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 5,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final result = await service.registerSale(sale);

    expect(result.totalAmount, 750000);
    expect(await inventoryStore.getStock('energy-100-ginger'), 15);
  });

  test('supports multiple sale items', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    await inventoryStore.addMovements([
      InventoryMovement(
        id: 'stock-100',
        itemId: 'energy-100-ginger',
        itemName: 'انرژی بار ۱۰۰g زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 20,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
      InventoryMovement(
        id: 'stock-500',
        itemId: 'energy-500-chickpea',
        itemName: 'انرژی بار ۵۰۰g نخودچی',
        itemType: 'finishedProduct',
        quantity: 10,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
    ]);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 5,
          unitPrice: 150000,
        ),
        SaleItem(
          productVariantId: 'energy-500-chickpea',
          productName: 'انرژی بار ۵۰۰g نخودچی',
          quantity: 2,
          unitPrice: 600000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final result = await service.registerSale(sale);

    expect(result.movements, hasLength(2));
    expect(result.totalAmount, 1950000);
    expect(await inventoryStore.getStock('energy-100-ginger'), 15);
    expect(await inventoryStore.getStock('energy-500-chickpea'), 8);
  });

  test('rejects sale when customer does not exist', () async {
    final sale = Sale(
      id: 'sale-1',
      customerId: 'customer-missing',
      customerName: 'مشتری ناموجود',
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 1,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    expect(() => service.registerSale(sale), throwsA(isA<StateError>()));
  });

  test('rejects sale from inactive customer', () async {
    final customer = Customer(
      id: 'customer-1',
      name: 'مشتری غیرفعال',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);
    await customerStore.deactivate(customer.id);

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 1,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    expect(() => service.registerSale(sale), throwsA(isA<StateError>()));
  });

  test('rejects sale when stock is insufficient', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'stock-1',
        itemId: 'energy-100-ginger',
        itemName: 'انرژی بار ۱۰۰g زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 2,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
    );

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 5,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    expect(() => service.registerSale(sale), throwsA(isA<StateError>()));

    expect(await inventoryStore.getStock('energy-100-ginger'), 2);
    expect(await saleStore.getSales(), isEmpty);
  });

  test('does not execute the same sale twice', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'stock-1',
        itemId: 'energy-100-ginger',
        itemName: 'انرژی بار ۱۰۰g زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 10,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
    );

    final sale = Sale(
      id: 'sale-idempotent-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 3,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    final first = await service.registerSale(sale);
    final second = await service.registerSale(sale);

    expect(first.alreadyExecuted, isFalse);
    expect(second.alreadyExecuted, isTrue);

    expect(first.movements, hasLength(1));
    expect(second.movements, hasLength(1));

    expect(await inventoryStore.getStock('energy-100-ginger'), 7);

    final sales = await saleStore.getSales();
    expect(sales, hasLength(1));
  });

  test('preserves customer name as historical snapshot', () async {
    final customer = Customer(
      id: 'customer-gholami',
      name: 'آقای غلامی',
      createdAt: DateTime(2026, 1, 1),
    );

    await customerStore.add(customer);

    await inventoryStore.addMovement(
      InventoryMovement(
        id: 'stock-1',
        itemId: 'energy-100-ginger',
        itemName: 'انرژی بار ۱۰۰g زنجبیلی',
        itemType: 'finishedProduct',
        quantity: 5,
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: DateTime(2026, 1, 1),
      ),
    );

    final sale = Sale(
      id: 'sale-1',
      customerId: customer.id,
      customerName: customer.name,
      items: const [
        SaleItem(
          productVariantId: 'energy-100-ginger',
          productName: 'انرژی بار ۱۰۰g زنجبیلی',
          quantity: 1,
          unitPrice: 150000,
        ),
      ],
      saleDate: DateTime(2026, 1, 2),
    );

    await service.registerSale(sale);

    final stored = await saleStore.getById('sale-1');

    expect(stored, isNotNull);
    expect(stored!.customerId, 'customer-gholami');
    expect(stored.customerName, 'آقای غلامی');
  });

  test('rejects duplicate product variants in one sale', () async {
    final customer = Customer(id: 'customer-duplicate', name: 'مشتری تکراری', createdAt: DateTime(2026, 1, 1));
    await customerStore.add(customer);
    await inventoryStore.addMovement(InventoryMovement(
      id: 'stock-duplicate', itemId: 'energy-100-ginger', itemName: 'انرژی بار',
      itemType: 'finishedProduct', quantity: 10, unit: 'عدد',
      movementType: InventoryMovementType.productionOutput, timestamp: DateTime(2026, 1, 1),
    ));
    final sale = Sale(
      id: 'sale-duplicate', customerId: customer.id, customerName: customer.name,
      items: const [
        SaleItem(productVariantId: 'energy-100-ginger', productName: 'انرژی بار', quantity: 6, unitPrice: 100000),
        SaleItem(productVariantId: 'energy-100-ginger', productName: 'انرژی بار', quantity: 6, unitPrice: 100000),
      ],
      saleDate: DateTime(2026, 1, 2),
    );
    expect(() => service.registerSale(sale), throwsA(isA<ArgumentError>()));
    expect(await saleStore.getSales(), isEmpty);
    expect(await inventoryStore.getStock('energy-100-ginger'), 10);
  });

  test('reconciles a sale whose inventory movement was missing', () async {
    final customer = Customer(id: 'customer-recovery', name: 'مشتری بازیابی', createdAt: DateTime(2026, 1, 1));
    await customerStore.add(customer);
    final sale = Sale(
      id: 'sale-recovery', customerId: customer.id, customerName: customer.name,
      items: const [SaleItem(productVariantId: 'energy-100-ginger', productName: 'انرژی بار', quantity: 3, unitPrice: 100000)],
      saleDate: DateTime(2026, 1, 2),
    );
    await saleStore.add(sale);
    await inventoryStore.addMovement(InventoryMovement(
      id: 'stock-recovery', itemId: 'energy-100-ginger', itemName: 'انرژی بار',
      itemType: 'finishedProduct', quantity: 5, unit: 'عدد',
      movementType: InventoryMovementType.productionOutput, timestamp: DateTime(2026, 1, 1),
    ));
    final result = await service.registerSale(sale);
    expect(result.alreadyExecuted, isTrue);
    expect(result.movements, hasLength(1));
    expect(await inventoryStore.getStock('energy-100-ginger'), 2);
  });

  test('rejects reusing a sale id with different data', () async {
    final customer = Customer(id: 'customer-mismatch', name: 'مشتری', createdAt: DateTime(2026, 1, 1));
    await customerStore.add(customer);
    final original = Sale(
      id: 'sale-mismatch', customerId: customer.id, customerName: customer.name,
      items: const [SaleItem(productVariantId: 'energy-100-ginger', productName: 'انرژی بار', quantity: 1, unitPrice: 100000)],
      saleDate: DateTime(2026, 1, 2),
    );
    await saleStore.add(original);
    final changed = original.copyWith(items: const [
      SaleItem(productVariantId: 'energy-100-ginger', productName: 'انرژی بار', quantity: 2, unitPrice: 100000),
    ]);
    expect(() => service.registerSale(changed), throwsA(isA<StateError>()));
  });

}
