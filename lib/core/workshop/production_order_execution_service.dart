import '../inventory/inventory_movement.dart';
import '../inventory/inventory_reservation.dart';
import '../inventory/inventory_store.dart';
import '../sales/sales_order.dart';
import '../sales/sales_order_store.dart';
import 'production_batch.dart';
import 'production_batch_store.dart';
import 'production_order_analyzer.dart';
import 'production_requirement.dart';

class ProductionOrderExecutionResult {
  final String orderId;
  final bool changed;
  final bool alreadyCompleted;
  final int reservationCount;
  final int movementCount;
  final SalesOrder order;

  const ProductionOrderExecutionResult({
    required this.orderId,
    required this.changed,
    required this.order,
    this.alreadyCompleted = false,
    this.reservationCount = 0,
    this.movementCount = 0,
  });
}

class ProductionOrderExecutionService {
  final InventoryStore inventoryStore;
  final SalesOrderStore orderStore;
  final ProductionBatchStore batchStore;

  const ProductionOrderExecutionService({
    required this.inventoryStore,
    required this.orderStore,
    required this.batchStore,
  });

  Future<ProductionOrderExecutionResult> reserve(
    SalesOrder order,
    ProductionOrderAnalysis analysis,
  ) async {
    _requireAnalysis(order, analysis);

    if (!analysis.canProduce) {
      throw StateError('این سفارش هنوز به دلیل کمبود موجودی آماده تولید نیست.');
    }

    if (order.status != SalesOrderStatus.readyForProduction) {
      throw StateError(
        'فقط سفارش «آماده تولید» را می‌توان برای تولید رزرو کرد.',
      );
    }

    final requirements = _aggregateRequirements(analysis);
    final active = await inventoryStore.getReservations(activeOnly: true);
    final orderReservations = active
        .where((reservation) => reservation.referenceId == order.id)
        .toList();

    if (orderReservations.isNotEmpty) {
      _validateExistingReservations(orderReservations, requirements);

      return ProductionOrderExecutionResult(
        orderId: order.id,
        changed: false,
        order: order,
        reservationCount: orderReservations.length,
      );
    }

    for (final requirement in requirements.values) {
      final available = await inventoryStore.getAvailableStock(
        requirement.materialId,
      );

      if (requirement.quantity > available + 0.000001) {
        throw StateError(
          'موجودی آزاد ${requirement.materialName} برای رزرو کافی نیست.',
        );
      }
    }

    final now = DateTime.now();
    for (final requirement in requirements.values) {
      await inventoryStore.reserve(
        InventoryReservation(
          id: _reservationId(order.id, requirement.materialId),
          itemId: requirement.materialId,
          quantity: requirement.quantity,
          referenceId: order.id,
          createdAt: now,
          note: 'رزرو مواد برای سفارش ${order.id}',
        ),
      );
    }

    return ProductionOrderExecutionResult(
      orderId: order.id,
      changed: true,
      order: order,
      reservationCount: requirements.length,
    );
  }

  Future<ProductionOrderExecutionResult> startProduction(
    SalesOrder order,
    ProductionOrderAnalysis analysis,
  ) async {
    _requireAnalysis(order, analysis);

    if (order.status == SalesOrderStatus.productionCompleted ||
        order.status == SalesOrderStatus.readyForDelivery ||
        order.status == SalesOrderStatus.partiallyDelivered ||
        order.status == SalesOrderStatus.delivered) {
      return ProductionOrderExecutionResult(
        orderId: order.id,
        changed: false,
        alreadyCompleted: true,
        order: order,
      );
    }

    if (order.status != SalesOrderStatus.readyForProduction &&
        order.status != SalesOrderStatus.inProduction) {
      throw StateError('این سفارش در وضعیت قابل تولید نیست.');
    }

    if (!analysis.canProduce) {
      throw StateError('سفارش به دلیل کمبود موجودی قابل تولید نیست.');
    }

    final requirements = _aggregateRequirements(analysis);
    final activeReservations = await inventoryStore.getReservations(
      activeOnly: true,
    );
    final orderReservations = activeReservations
        .where((reservation) => reservation.referenceId == order.id)
        .toList();

    if (orderReservations.isEmpty) {
      throw StateError('مواد اولیه این سفارش هنوز رزرو نشده‌اند.');
    }

    _validateExistingReservations(orderReservations, requirements);

    final movements = await inventoryStore.getMovements();
    final movementById = {
      for (final movement in movements) movement.id: movement,
    };

    final expectedMovements = <InventoryMovement>[];
    final now = DateTime.now();

    for (final requirement in requirements.values) {
      final id = _consumptionMovementId(order.id, requirement.materialId);
      expectedMovements.add(
        InventoryMovement(
          id: id,
          itemId: requirement.materialId,
          itemName: requirement.materialName,
          itemType: _inventoryItemType(requirement.type),
          quantity: requirement.quantity,
          unit: requirement.unit,
          movementType: InventoryMovementType.productionConsumption,
          timestamp: now,
          referenceId: order.id,
          note: 'مصرف مواد برای تولید سفارش ${order.id}',
        ),
      );
    }

    for (final line in analysis.lines) {
      final id = _outputMovementId(order.id, line.line.productVariantId);
      expectedMovements.add(
        InventoryMovement(
          id: id,
          itemId: line.line.productVariantId,
          itemName: line.line.productName,
          itemType: 'finishedProduct',
          quantity: line.line.quantity.toDouble(),
          unit: 'عدد',
          movementType: InventoryMovementType.productionOutput,
          timestamp: now,
          referenceId: order.id,
          note: 'خروجی تولید سفارش ${order.id}',
        ),
      );
    }

    for (final byproduct in analysis.byproducts) {
      final id = _byproductMovementId(order.id, byproduct.itemId);
      expectedMovements.add(
        InventoryMovement(
          id: id,
          itemId: byproduct.itemId,
          itemName: byproduct.itemName,
          itemType: byproduct.itemType,
          quantity: byproduct.quantity,
          unit: byproduct.unit,
          movementType: InventoryMovementType.productionOutput,
          timestamp: now,
          referenceId: order.id,
          note: 'محصول جانبی قابل استفاده: ${byproduct.itemName}',
        ),
      );
    }

    _validateExistingMovementQuantities(expectedMovements, movementById);

    final missing = expectedMovements
        .where((movement) => !movementById.containsKey(movement.id))
        .toList();

    if (missing.isNotEmpty) {
      await inventoryStore.addMovements(missing);
    }

    await _ensureBatches(order, analysis);

    for (final reservation in orderReservations) {
      await inventoryStore.releaseReservation(reservation.id);
    }

    final updatedOrder = _withStatus(
      order,
      SalesOrderStatus.productionCompleted,
    );

    await orderStore.update(updatedOrder);

    return ProductionOrderExecutionResult(
      orderId: order.id,
      changed: missing.isNotEmpty || order.status != updatedOrder.status,
      alreadyCompleted: missing.isEmpty &&
          order.status == SalesOrderStatus.productionCompleted,
      order: updatedOrder,
      movementCount: missing.length,
    );
  }

  Future<void> _ensureBatches(
    SalesOrder order,
    ProductionOrderAnalysis analysis,
  ) async {
    for (var index = 0; index < analysis.lines.length; index++) {
      final line = analysis.lines[index];
      final batchId = _batchId(order.id, index);
      final existing = await batchStore.getById(batchId);

      if (existing != null) continue;

      await batchStore.add(
        ProductionBatch(
          id: batchId,
          productVariantId: line.line.productVariantId,
          productName: line.line.productName,
          units: line.line.quantity,
          unitWeightGrams: line.calculation.unitWeightGrams,
          recipeId: 'recipe-${line.line.productVariantId}',
          recipeVersion: 1,
          createdAt: DateTime.now(),
          status: ProductionBatchStatus.completed,
          note: 'تولید از سفارش ${order.id}',
        ),
      );
    }
  }

  Map<String, ProductionRequirement> _aggregateRequirements(
    ProductionOrderAnalysis analysis,
  ) {
    final result = <String, ProductionRequirement>{};

    for (final line in analysis.lines) {
      for (final requirement in line.calculation.requirements) {
        final current = result[requirement.materialId];

        if (current == null) {
          result[requirement.materialId] = requirement;
        } else {
          result[requirement.materialId] = ProductionRequirement(
            materialId: current.materialId,
            materialName: current.materialName,
            quantity: current.quantity + requirement.quantity,
            unit: current.unit,
            type: current.type,
          );
        }
      }
    }

    return result;
  }

  void _validateExistingReservations(
    List<InventoryReservation> reservations,
    Map<String, ProductionRequirement> requirements,
  ) {
    final byItem = {
      for (final reservation in reservations) reservation.itemId: reservation,
    };

    if (byItem.length != requirements.length) {
      throw StateError('رزروهای این سفارش با نیاز تولید همخوانی ندارند.');
    }

    for (final requirement in requirements.values) {
      final reservation = byItem[requirement.materialId];

      if (reservation == null ||
          (reservation.quantity - requirement.quantity).abs() > 0.000001) {
        throw StateError(
          'مقدار رزرو ${requirement.materialName} با نیاز تولید همخوانی ندارد.',
        );
      }
    }
  }

  void _validateExistingMovementQuantities(
    List<InventoryMovement> expected,
    Map<String, InventoryMovement> existing,
  ) {
    for (final movement in expected) {
      final current = existing[movement.id];
      if (current == null) continue;

      if (current.itemId != movement.itemId ||
          current.movementType != movement.movementType ||
          (current.quantity - movement.quantity).abs() > 0.000001) {
        throw StateError(
          'حرکت انبار ${movement.id} با اطلاعات مورد انتظار همخوانی ندارد.',
        );
      }
    }
  }

  void _requireAnalysis(
    SalesOrder order,
    ProductionOrderAnalysis analysis,
  ) {
    if (analysis.orderId != order.id) {
      throw StateError('تحلیل تولید مربوط به این سفارش نیست.');
    }
  }

  SalesOrder _withStatus(SalesOrder order, SalesOrderStatus status) {
    return SalesOrder(
      id: order.id,
      customerId: order.customerId,
      customerName: order.customerName,
      orderDate: order.orderDate,
      lines: order.lines,
      totalAmount: order.totalAmount,
      status: status,
    );
  }

  String _reservationId(String orderId, String materialId) =>
      'reservation-${orderId}-${materialId}';

  String _consumptionMovementId(String orderId, String materialId) =>
      'production-consumption-${orderId}-${materialId}';

  String _outputMovementId(String orderId, String productVariantId) =>
      'production-output-${orderId}-${productVariantId}';

  String _byproductMovementId(String orderId, String itemId) =>
      'production-byproduct-${orderId}-${itemId}';

  String _batchId(String orderId, int lineIndex) =>
      'production-batch-${orderId}-${lineIndex}';

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
