import '../inventory/inventory_movement.dart';
import '../inventory/inventory_store.dart';
import 'sales_delivery.dart';
import 'sales_delivery_store.dart';
import 'sales_order.dart';
import 'sales_order_store.dart';
import '../finance/sales_financial_service.dart';

class SalesDeliveryResult {
  const SalesDeliveryResult({
    required this.delivery,
    required this.order,
    required this.changed,
  });

  final SalesDelivery delivery;
  final SalesOrder order;
  final bool changed;
}

class SalesDeliveryService {
  final InventoryStore inventoryStore;
  final SalesOrderStore orderStore;
  final SalesDeliveryStore deliveryStore;
  final SalesFinancialService financialService;

  const SalesDeliveryService({
    required this.inventoryStore,
    required this.orderStore,
    required this.deliveryStore,
    required this.financialService,
  });

  Future<SalesOrder> markReadyForDelivery(SalesOrder order) async {
    if (order.status == SalesOrderStatus.readyForDelivery) return order;
    if (order.status != SalesOrderStatus.productionCompleted) {
      throw StateError('فقط سفارش با تولید تکمیل‌شده آماده تحویل می‌شود.');
    }
    final updated = _withStatus(order, SalesOrderStatus.readyForDelivery);
    await orderStore.update(updated);
    return updated;
  }

  Future<SalesDeliveryResult> deliver({
    required SalesOrder order,
    required String deliveryId,
    required Map<String, int> quantities,
  }) async {
    if (quantities.isEmpty) throw ArgumentError('حداقل یک قلم برای تحویل لازم است.');
    if (order.status != SalesOrderStatus.readyForDelivery &&
        order.status != SalesOrderStatus.partiallyDelivered) {
      throw StateError('این سفارش در وضعیت قابل تحویل نیست.');
    }

    final existingDelivery = await deliveryStore.getById(deliveryId);
    if (existingDelivery != null) {
      if (existingDelivery.orderId != order.id) {
        throw StateError('شناسه تحویل برای سفارش دیگری استفاده شده است.');
      }

      // Reconcile any previous partial completion: delivery may have been
      // persisted before its financial entry or order status was persisted.
      await financialService.postSaleReceivable(
        existingDelivery,
        customerName: order.customerName,
      );

      final currentOrder = await _getCurrentOrder(order.id);
      final delivered = await _deliveredQuantities(order.id);
      final fullyDelivered = currentOrder.lines.every(
        (line) =>
            (delivered[line.productVariantId] ?? 0) >= line.quantity,
      );
      final expectedStatus = fullyDelivered
          ? SalesOrderStatus.delivered
          : SalesOrderStatus.partiallyDelivered;
      final reconciledOrder = currentOrder.status == expectedStatus
          ? currentOrder
          : _withStatus(currentOrder, expectedStatus);
      if (reconciledOrder.status != currentOrder.status) {
        await orderStore.update(reconciledOrder);
      }

      return SalesDeliveryResult(
        delivery: existingDelivery,
        order: reconciledOrder,
        changed: false,
      );
    }

    final delivered = await _deliveredQuantities(order.id);
    final lineById = {for (final line in order.lines) line.productVariantId: line};
    final requested = <String, int>{};

    for (final entry in quantities.entries) {
      if (entry.value <= 0) throw ArgumentError('مقدار تحویل باید بیشتر از صفر باشد.');
      final line = lineById[entry.key];
      if (line == null) throw StateError('قلم موردنظر در سفارش وجود ندارد.');
      final remaining = line.quantity - (delivered[entry.key] ?? 0);
      if (entry.value > remaining) throw StateError('مقدار تحویل از مانده سفارش بیشتر است.');
      requested[entry.key] = entry.value;
    }

    final movements = <InventoryMovement>[];
    final now = DateTime.now();
    var totalAmount = 0;

    for (final entry in requested.entries) {
      final line = lineById[entry.key]!;
      final quantity = entry.value;
      final available = await inventoryStore.getAvailableStock(line.productVariantId);
      if (quantity > available + 0.000001) {
        throw StateError('موجودی ' + line.productName + ' برای تحویل کافی نیست.');
      }

      totalAmount += quantity * line.unitSellingPrice;
      movements.add(
        InventoryMovement(
          id: 'sale-' + deliveryId + '-' + line.productVariantId,
          itemId: line.productVariantId,
          itemName: line.productName,
          itemType: 'finishedProduct',
          quantity: quantity.toDouble(),
          unit: 'عدد',
          movementType: InventoryMovementType.sale,
          timestamp: now,
          referenceId: deliveryId,
          note: 'تحویل سفارش ' + order.id,
        ),
      );
    }

    final existingMovements = await inventoryStore.getMovements();
    final byId = {for (final movement in existingMovements) movement.id: movement};
    for (final movement in movements) {
      final current = byId[movement.id];
      if (current != null &&
          (current.itemId != movement.itemId ||
              current.movementType != movement.movementType ||
              (current.quantity - movement.quantity).abs() > 0.000001)) {
        throw StateError('حرکت تحویل با اطلاعات مورد انتظار همخوانی ندارد.');
      }
    }

    final missing = movements.where((movement) => !byId.containsKey(movement.id)).toList();
    if (missing.isNotEmpty) await inventoryStore.addMovements(missing);

    final delivery = SalesDelivery(
      id: deliveryId,
      orderId: order.id,
      customerId: order.customerId,
      createdAt: now,
      lines: requested.entries.map((entry) {
        final line = lineById[entry.key]!;
        return SalesDeliveryLine(
          productVariantId: entry.key,
          quantity: entry.value,
          unitSellingPrice: line.unitSellingPrice,
          totalAmount: entry.value * line.unitSellingPrice,
          productName: line.productName,
        );
      }).toList(),
      totalAmount: totalAmount,
    );
    await deliveryStore.add(delivery);
    await financialService.postSaleReceivable(
      delivery,
      customerName: order.customerName,
    );

    final nextDelivered = Map<String, int>.from(delivered);
    for (final entry in requested.entries) {
      nextDelivered.update(entry.key, (current) => current + entry.value, ifAbsent: () => entry.value);
    }

    final fullyDelivered = order.lines.every(
      (line) => (nextDelivered[line.productVariantId] ?? 0) >= line.quantity,
    );
    final updatedOrder = _withStatus(
      order,
      fullyDelivered ? SalesOrderStatus.delivered : SalesOrderStatus.partiallyDelivered,
    );
    await orderStore.update(updatedOrder);

    return SalesDeliveryResult(delivery: delivery, order: updatedOrder, changed: true);
  }

  Future<SalesOrder> _getCurrentOrder(String orderId) async {
    final orders = await orderStore.getAll();
    return orders.firstWhere(
      (item) => item.id == orderId,
      orElse: () => throw StateError('سفارش پیدا نشد.'),
    );
  }

  Future<Map<String, int>> _deliveredQuantities(String orderId) async {
    final rows = await deliveryStore.getByOrderId(orderId);
    final result = <String, int>{};
    for (final delivery in rows) {
      for (final line in delivery.lines) {
        result.update(line.productVariantId, (current) => current + line.quantity, ifAbsent: () => line.quantity);
      }
    }
    return result;
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
}
