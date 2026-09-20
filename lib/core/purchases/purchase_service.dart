import '../costing/cost_layer.dart';
import '../costing/cost_layer_store.dart';
import '../inventory/inventory_movement.dart';
import '../inventory/inventory_store.dart';
import '../suppliers/supplier_store.dart';
import '../units/unit.dart';
import 'purchase.dart';
import 'purchase_store.dart';
import 'purchase_validator.dart';

class PurchaseExecutionResult {
  final Purchase purchase;
  final InventoryMovement movement;
  final CostLayer costLayer;
  final bool alreadyExecuted;

  const PurchaseExecutionResult({
    required this.purchase,
    required this.movement,
    required this.costLayer,
    this.alreadyExecuted = false,
  });

  double get totalPrice => purchase.totalPrice;
}

class PurchaseService {
  final PurchaseStore purchaseStore;
  final InventoryStore inventoryStore;
  final SupplierStore supplierStore;
  final CostLayerStore costLayerStore;

  const PurchaseService({
    required this.purchaseStore,
    required this.inventoryStore,
    required this.supplierStore,
    required this.costLayerStore,
  });

  Future<PurchaseExecutionResult> registerPurchase(Purchase purchase) async {
    const validator = PurchaseValidator();
    validator.validate(purchase);

    final existingPurchase = await purchaseStore.getById(purchase.id);

    if (existingPurchase != null) {
      final existingMovements = (await inventoryStore.getMovements())
          .where(
            (movement) =>
                movement.referenceId == purchase.id &&
                movement.movementType == InventoryMovementType.purchase,
          )
          .toList();

      final existingLayer = await costLayerStore.getById(
        'cost-layer-${purchase.id}',
      );

      if (existingMovements.isNotEmpty && existingLayer != null) {
        return PurchaseExecutionResult(
          purchase: existingPurchase,
          movement: existingMovements.first,
          costLayer: existingLayer,
          alreadyExecuted: true,
        );
      }
    }

    if (purchase.supplierId != null) {
      final supplier = await supplierStore.getById(purchase.supplierId!);

      if (supplier == null) {
        throw StateError(
          'Supplier with id "${purchase.supplierId}" does not exist.',
        );
      }

      if (!supplier.active) {
        throw StateError(
          'Supplier with id "${purchase.supplierId}" is inactive.',
        );
      }

      if (purchase.supplierName != supplier.name) {
        throw StateError(
          'Supplier name snapshot does not match the current supplier.',
        );
      }
    }

    final purchaseUnit = Unit.fromKey(purchase.unit);

    final baseQuantity = purchaseUnit.toBase(purchase.quantity);

    final baseUnitCost = purchase.unitPrice / purchaseUnit.baseMultiplier;

    final movement = InventoryMovement(
      id: 'purchase-${purchase.id}',
      itemId: purchase.materialId,
      itemName: purchase.materialName,
      itemType: 'rawMaterial',
      quantity: purchase.quantity,
      unit: purchase.unit,
      movementType: InventoryMovementType.purchase,
      timestamp: purchase.purchaseDate,
      referenceId: purchase.id,
      unitCost: purchase.unitPrice,
      note: purchase.note,
    );

    final costLayer = CostLayer(
      id: 'cost-layer-${purchase.id}',
      materialId: purchase.materialId,
      materialName: purchase.materialName,
      quantity: baseQuantity,
      remainingQuantity: baseQuantity,
      unit: purchaseUnit.type == UnitType.weight ? 'g' : 'unit',
      unitCost: baseUnitCost,
      createdAt: purchase.purchaseDate,
      purchaseId: purchase.id,
    );

    await purchaseStore.add(purchase);
    await inventoryStore.addMovement(movement);
    await costLayerStore.add(costLayer);

    return PurchaseExecutionResult(
      purchase: purchase,
      movement: movement,
      costLayer: costLayer,
    );
  }
}
