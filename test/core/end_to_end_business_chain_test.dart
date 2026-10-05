import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/costing/cost_allocation_store.dart';
import 'package:zohal_android_test/core/costing/cost_layer.dart';
import 'package:zohal_android_test/core/costing/cost_layer_store.dart';
import 'package:zohal_android_test/core/costing/cost_consumption_service.dart';
import 'package:zohal_android_test/core/costing/production_cost_service.dart';
import 'package:zohal_android_test/core/costing/production_cost_store.dart';
import 'package:zohal_android_test/core/finance/financial_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/purchase.dart';
import 'package:zohal_android_test/core/purchase_service.dart';
import 'package:zohal_android_test/core/purchase_return_store.dart';
import 'package:zohal_android_test/core/purchase_store.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_service.dart';
import 'package:zohal_android_test/core/sales/sales_delivery_store.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/sales/sales_order_store.dart';
import 'package:zohal_android_test/core/sales/sales_return_service.dart';
import 'package:zohal_android_test/core/sales/sales_return_store.dart';
import 'package:zohal_android_test/core/finance/sales_financial_service.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';
import 'package:zohal_android_test/core/workshop/production_calculator.dart';
import 'package:zohal_android_test/core/workshop/production_requirement.dart';
import 'package:zohal_android_test/core/workshop/production_service.dart';
import 'package:zohal_android_test/core/workshop/production_workflow_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final inventoryStore = InventoryStore.instance;
  final purchaseStore = PurchaseStore.instance;
  final purchaseReturnStore = PurchaseReturnStore.instance;
  final financialStore = FinancialStore.instance;
  final costLayerStore = CostLayerStore.instance;
  final allocationStore = CostAllocationStore.instance;
  final productionCostStore = ProductionCostStore.instance;
  final productionBatchStore = ProductionBatchStore.instance;
  final orderStore = SalesOrderStore.instance;
  final deliveryStore = SalesDeliveryStore.instance;
  final returnStore = SalesReturnStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});

    await inventoryStore.clear();
    await purchaseStore.clear();
    await purchaseReturnStore.clear();
    await financialStore.clear();
    await costLayerStore.clear();
    await allocationStore.clear();
    await productionCostStore.clear();
    await productionBatchStore.clear();
    await orderStore.clear();
    await deliveryStore.clear();
    await returnStore.clear();
  });

  Purchase purchase() => Purchase(
    id: 'e2e-purchase-1',
    supplierId: 'supplier-e2e',
    supplierName: 'تأمین‌کننده E2E',
    createdAt: DateTime(2026, 10, 5),
    lines: const [
      PurchaseLine(
        itemId: 'date',
        itemName: 'خرما',
        itemType: 'rawMaterial',
        quantity: 1000,
        unit: 'g',
        unitCost: 10,
      ),
      PurchaseLine(
        itemId: 'box',
        itemName: 'ظرف',
        itemType: 'packaging',
        quantity: 10,
        unit: 'unit',
        unitCost: 500,
      ),
    ],
    totalAmount: 15000,
  );

  ProductionBatch batch() => ProductionBatch(
    id: 'e2e-production-1',
    productVariantId: 'energy-bar-100g',
    productName: 'انرژی بار ۱۰۰ گرمی',
    units: 10,
    unitWeightGrams: 100,
    recipeId: 'recipe-e2e',
    recipeVersion: 1,
    createdAt: DateTime(2026, 10, 5),
    status: ProductionBatchStatus.ready,
    expiryDate: DateTime(2026, 12, 31),
  );

  const calculation = ProductionCalculation(
    units: 10,
    unitWeightGrams: 100,
    totalWeightGrams: 1000,
    requirements: [
      ProductionRequirement(
        materialId: 'date',
        materialName: 'خرما',
        quantity: 1000,
        unit: 'g',
      ),
      ProductionRequirement(
        materialId: 'box',
        materialName: 'ظرف',
        quantity: 10,
        unit: 'unit',
        type: ProductionRequirementType.packaging,
      ),
    ],
  );

  SalesOrder order() => SalesOrder(
    id: 'e2e-order-1',
    customerId: 'customer-e2e',
    customerName: 'مشتری E2E',
    orderDate: DateTime(2026, 10, 5),
    lines: const [
      SalesOrderLine(
        productVariantId: 'energy-bar-100g',
        productName: 'انرژی بار ۱۰۰ گرمی',
        flavor: 'ساده',
        packageLabel: '۱۰۰ گرمی',
        quantity: 6,
        unitSellingPrice: 100000,
        lineTotal: 600000,
      ),
    ],
    totalAmount: 600000,
    status: SalesOrderStatus.productionCompleted,
  );

  PurchaseService purchaseService() => PurchaseService(
    inventoryStore: inventoryStore,
    purchaseStore: purchaseStore,
    financialStore: financialStore,
    purchaseReturnStore: purchaseReturnStore,
  );

  ProductionWorkflowService productionService() => ProductionWorkflowService(
    productionService: ProductionService(inventoryStore: inventoryStore),
    productionCostService: ProductionCostService(
      costConsumptionService: CostConsumptionService(
        costLayerStore: costLayerStore,
        allocationStore: allocationStore,
      ),
    ),
    productionBatchStore: productionBatchStore,
    productionCostStore: productionCostStore,
  );

  SalesDeliveryService deliveryService() => SalesDeliveryService(
    inventoryStore: inventoryStore,
    orderStore: orderStore,
    deliveryStore: deliveryStore,
    financialService: SalesFinancialService(store: financialStore),
  );

  SalesReturnService returnService() => SalesReturnService(
    inventoryStore: inventoryStore,
    deliveryStore: deliveryStore,
    returnStore: returnStore,
    financialService: SalesFinancialService(store: financialStore),
  );

  test('runs the complete purchase-to-production-to-sale-to-return chain', () async {
    final purchaseItem = purchase();
    final purchaseSvc = purchaseService();

    await purchaseSvc.recordPurchase(purchaseItem);
    await purchaseSvc.recordPurchase(purchaseItem);

    expect(await inventoryStore.getStock('date'), 1000);
    expect(await inventoryStore.getStock('box'), 10);
    expect((await financialStore.getTransactions()), hasLength(1));

    await costLayerStore.add(
      CostLayer(
        id: 'e2e-date-layer',
        materialId: 'date',
        materialName: 'خرما',
        quantity: 1000,
        remainingQuantity: 1000,
        unit: 'g',
        unitCost: 10,
        createdAt: purchaseItem.createdAt,
        purchaseId: purchaseItem.id,
        lotNumber: 'LOT-DATE-E2E',
        expiryDate: DateTime(2026, 11, 30),
      ),
    );
    await costLayerStore.add(
      CostLayer(
        id: 'e2e-box-layer',
        materialId: 'box',
        materialName: 'ظرف',
        quantity: 10,
        remainingQuantity: 10,
        unit: 'unit',
        unitCost: 500,
        createdAt: purchaseItem.createdAt,
        purchaseId: purchaseItem.id,
        lotNumber: 'LOT-BOX-E2E',
      ),
    );

    final productionSvc = productionService();
    final firstProduction = await productionSvc.execute(
      batch: batch(),
      calculation: calculation,
    );
    final secondProduction = await productionSvc.execute(
      batch: batch(),
      calculation: calculation,
    );

    expect(firstProduction.execution.executed, isTrue);
    expect(secondProduction.execution.alreadyExecuted, isTrue);
    expect(secondProduction.cost.totalCost, 15000);
    expect(
      (await inventoryStore.getMovements())
          .where((movement) => movement.referenceId == batch().id),
      hasLength(3),
    );
    expect(await inventoryStore.getStock('date'), 0);
    expect(await inventoryStore.getStock('box'), 0);
    expect(await inventoryStore.getStock('energy-bar-100g'), 10);
    expect(
      (await productionBatchStore.getById(batch().id))!.sourceLotNumbers,
      ['LOT-DATE-E2E'],
    );
    expect(
      (await costLayerStore.getById('e2e-date-layer'))!.remainingQuantity,
      0,
    );
    expect(
      (await costLayerStore.getById('e2e-box-layer'))!.remainingQuantity,
      0,
    );

    final currentOrder = order();
    await orderStore.create(currentOrder);
    final readyOrder = await deliveryService().markReadyForDelivery(currentOrder);

    final firstDelivery = await deliveryService().deliver(
      order: readyOrder,
      deliveryId: 'e2e-delivery-1',
      quantities: const {'energy-bar-100g': 6},
    );
    final retryDelivery = await deliveryService().deliver(
      order: firstDelivery.order,
      deliveryId: 'e2e-delivery-1',
      quantities: const {'energy-bar-100g': 6},
    );

    expect(firstDelivery.changed, isTrue);
    expect(retryDelivery.changed, isFalse);
    expect(retryDelivery.order.status, SalesOrderStatus.delivered);
    expect(await inventoryStore.getStock('energy-bar-100g'), 4);
    expect(await financialStore.getBalance('customer-customer-e2e'), 600000);

    final firstReturn = await returnService().returnItems(
      delivery: firstDelivery.delivery,
      returnId: 'e2e-return-1',
      customerName: 'مشتری E2E',
      quantities: const {'energy-bar-100g': 2},
    );
    final retryReturn = await returnService().returnItems(
      delivery: firstDelivery.delivery,
      returnId: 'e2e-return-1',
      customerName: 'نام دیگر نباید اثر بگذارد',
      quantities: const {'energy-bar-100g': 2},
    );

    expect(firstReturn.changed, isTrue);
    expect(retryReturn.changed, isFalse);
    expect(await inventoryStore.getStock('energy-bar-100g'), 6);
    expect(await financialStore.getBalance('customer-customer-e2e'), 400000);
    expect(await financialStore.getBalance('sales-revenue'), -400000);
    expect(await financialStore.getBalance('supplier-supplier-e2e'), -15000);
    expect(await financialStore.getBalance('inventory-asset'), 15000);

    expect((await purchaseStore.getAll()), hasLength(1));
    expect((await productionBatchStore.getAll()), hasLength(1));
    expect((await productionCostStore.getAll()), hasLength(1));
    expect((await orderStore.getAll()), hasLength(1));
    expect((await deliveryStore.getAll()), hasLength(1));
    expect((await returnStore.getAll()), hasLength(1));
    expect((await financialStore.getTransactions()), hasLength(3));
  });
}
