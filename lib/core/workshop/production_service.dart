import '../inventory/inventory_movement.dart';
import '../inventory/inventory_store.dart';
import 'production_batch.dart';
import 'production_calculator.dart';
import 'production_inventory_checker.dart';
import 'production_lifecycle.dart';
import 'production_requirement.dart';
import 'production_stock_check.dart';

class ProductionExecutionResult {
  final String productionId;
  final ProductionStockCheck stockCheck;
  final bool executed;
  final bool alreadyExecuted;
  final ProductionBatch batch;

  const ProductionExecutionResult({
    required this.productionId,
    required this.stockCheck,
    required this.executed,
    required this.batch,
    this.alreadyExecuted = false,
  });
}

class ProductionService {
  final InventoryStore inventoryStore;

  const ProductionService({required this.inventoryStore});

  Future<ProductionExecutionResult> execute({
    required ProductionCalculation calculation,
    required String productId,
    required String productName,
    String? productionId,
  }) async {
    final id =
        productionId ?? 'production-${DateTime.now().microsecondsSinceEpoch}';

    final stockCheck = await ProductionInventoryChecker(
      inventoryStore: inventoryStore,
    ).check(calculation);

    final batch = ProductionBatch(
      id: id,
      productVariantId: productId,
      productName: productName,
      units: calculation.units,
      unitWeightGrams: calculation.unitWeightGrams,
      recipeId: 'legacy',
      recipeVersion: 1,
      createdAt: DateTime.now(),
    );

    if (!stockCheck.canProduce) {
      return ProductionExecutionResult(
        productionId: id,
        stockCheck: stockCheck,
        executed: false,
        batch: batch,
      );
    }

    final readyBatch = const ProductionLifecycle().moveToReady(batch);
    return executeBatch(batch: readyBatch, calculation: calculation);
  }

  Future<ProductionExecutionResult> executeBatch({
    required ProductionBatch batch,
    required ProductionCalculation calculation,
  }) async {
    final existingMovements = await inventoryStore.getMovements();

    final expectedMovements = _buildMovements(
      batch: batch,
      calculation: calculation,
    );
    final movementsById = {
      for (final movement in existingMovements) movement.id: movement,
    };
    final relatedMovements = existingMovements.where(
      (movement) => movement.referenceId == batch.id &&
          (movement.movementType == InventoryMovementType.productionConsumption ||
              movement.movementType == InventoryMovementType.productionOutput),
    );

    for (final expected in expectedMovements) {
      final existing = movementsById[expected.id];
      if (existing != null && !_sameMovement(existing, expected)) {
        throw StateError(
          'حرکت تولید "${expected.id}" با اطلاعات مورد انتظار همخوانی ندارد.',
        );
      }
    }

    final alreadyExecuted = relatedMovements.isNotEmpty;

    final stockCheck = await ProductionInventoryChecker(
      inventoryStore: inventoryStore,
    ).check(calculation);

    if (alreadyExecuted && relatedMovements.length == expectedMovements.length) {
      final completedBatch = batch.copyWith(
        status: ProductionBatchStatus.completed,
      );
      return ProductionExecutionResult(
        productionId: batch.id,
        stockCheck: stockCheck,
        executed: false,
        alreadyExecuted: true,
        batch: completedBatch,
      );
    }

    if (!stockCheck.canProduce && !alreadyExecuted) {
      return ProductionExecutionResult(
        productionId: batch.id,
        stockCheck: stockCheck,
        executed: false,
        batch: batch,
      );
    }

    final lifecycle = const ProductionLifecycle();
    final inProductionBatch = lifecycle.start(batch);
    final missingMovements = expectedMovements.where(
      (movement) => !movementsById.containsKey(movement.id),
    ).toList();

    if (missingMovements.isNotEmpty) {
      await inventoryStore.addMovements(missingMovements);
    }

    final completedBatch = lifecycle.complete(inProductionBatch);
    return ProductionExecutionResult(
      productionId: batch.id,
      stockCheck: stockCheck,
      executed: true,
      batch: completedBatch,
    );
  }

  List<InventoryMovement> _buildMovements({
    required ProductionBatch batch,
    required ProductionCalculation calculation,
  }) {
    final timestamp = DateTime.now();
    return [
      for (final requirement in calculation.requirements)
        InventoryMovement(
          id: '${batch.id}-consumption-${requirement.materialId}',
          itemId: requirement.materialId,
          itemName: requirement.materialName,
          itemType: _inventoryItemType(requirement.type),
          quantity: requirement.quantity,
          unit: requirement.unit,
          movementType: InventoryMovementType.productionConsumption,
          timestamp: timestamp,
          referenceId: batch.id,
          note: 'مصرف مواد برای تولید ${batch.productName}',
        ),
      InventoryMovement(
        id: '${batch.id}-output-${batch.productVariantId}',
        itemId: batch.productVariantId,
        itemName: batch.productName,
        itemType: 'finishedProduct',
        quantity: batch.units.toDouble(),
        unit: 'عدد',
        movementType: InventoryMovementType.productionOutput,
        timestamp: timestamp,
        referenceId: batch.id,
        note: 'خروجی تولید',
      ),
      for (final byproduct in calculation.byproducts)
        InventoryMovement(
          id: '${batch.id}-byproduct-${byproduct.itemId}',
          itemId: byproduct.itemId,
          itemName: byproduct.itemName,
          itemType: byproduct.itemType,
          quantity: byproduct.quantity,
          unit: byproduct.unit,
          movementType: InventoryMovementType.productionOutput,
          timestamp: timestamp,
          referenceId: batch.id,
          note: 'محصول جانبی قابل استفاده: ${byproduct.itemName}',
        ),
    ];
  }

  bool _sameMovement(InventoryMovement left, InventoryMovement right) {
    return left.id == right.id &&
        left.itemId == right.itemId &&
        left.itemName == right.itemName &&
        left.itemType == right.itemType &&
        (left.quantity - right.quantity).abs() <= 0.000001 &&
        left.unit == right.unit &&
        left.movementType == right.movementType &&
        left.referenceId == right.referenceId;
  }

  String _inventoryItemType(ProductionRequirementType type) {
    switch (type) {
      case ProductionRequirementType.rawMaterial:
        return 'rawMaterial';
      case ProductionRequirementType.consumable:
        return 'consumable';
      case ProductionRequirementType.packaging:
        return 'packaging';
    }
  }
}
