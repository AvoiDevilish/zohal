import '../finance/sales_financial_service.dart';
import '../inventory/inventory_movement.dart';
import '../inventory/inventory_store.dart';
import 'sales_delivery.dart';
import 'sales_delivery_store.dart';
import 'sales_return.dart';
import 'sales_return_store.dart';

class SalesReturnResult {
  const SalesReturnResult({
    required this.salesReturn,
    required this.changed,
  });

  final SalesReturn salesReturn;
  final bool changed;
}

class SalesReturnService {
  final InventoryStore inventoryStore;
  final SalesDeliveryStore deliveryStore;
  final SalesReturnStore returnStore;
  final SalesFinancialService financialService;

  const SalesReturnService({
    required this.inventoryStore,
    required this.deliveryStore,
    required this.returnStore,
    required this.financialService,
  });

  Future<SalesReturnResult> returnItems({
    required SalesDelivery delivery,
    required String returnId,
    required String customerName,
    required Map<String, int> quantities,
    String? note,
  }) async {
    if (quantities.isEmpty) {
      throw ArgumentError('حداقل یک قلم برای برگشت لازم است.');
    }

    final existingReturn = await returnStore.getById(returnId);
    if (existingReturn != null) {
      if (existingReturn.deliveryId != delivery.id) {
        throw StateError('شناسه برگشت برای تحویل دیگری استفاده شده است.');
      }
      return SalesReturnResult(salesReturn: existingReturn, changed: false);
    }

    final deliveryLines = {
      for (final line in delivery.lines) line.productVariantId: line,
    };
    final alreadyReturned = <String, int>{};
    for (final salesReturn in await returnStore.getByDeliveryId(delivery.id)) {
      for (final line in salesReturn.lines) {
        alreadyReturned.update(
          line.productVariantId,
          (current) => current + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }
    }

    final requested = <String, int>{};
    var totalAmount = 0;
    final now = DateTime.now();

    for (final entry in quantities.entries) {
      if (entry.value <= 0) {
        throw ArgumentError('مقدار برگشت باید بیشتر از صفر باشد.');
      }

      final line = deliveryLines[entry.key];
      if (line == null) {
        throw StateError('قلم موردنظر در تحویل وجود ندارد.');
      }

      final remaining = line.quantity - (alreadyReturned[entry.key] ?? 0);
      if (entry.value > remaining) {
        throw StateError('مقدار برگشت از مقدار تحویل‌شده بیشتر است.');
      }

      final availableAfterReturn = await inventoryStore.getStock(entry.key);
      if (availableAfterReturn < -0.000001) {
        throw StateError('موجودی فعلی قلم برگشتی معتبر نیست.');
      }

      requested[entry.key] = entry.value;
      totalAmount += entry.value * line.unitSellingPrice;
    }

    final movements = requested.entries.map((entry) {
      final line = deliveryLines[entry.key]!;
      return InventoryMovement(
        id: 'sale-return-' + returnId + '-' + entry.key,
        itemId: entry.key,
        itemName: line.productName ?? entry.key,
        itemType: 'finishedProduct',
        quantity: entry.value.toDouble(),
        unit: 'عدد',
        movementType: InventoryMovementType.saleReturn,
        timestamp: now,
        referenceId: returnId,
        note: 'برگشت فروش از تحویل ' + delivery.id,
      );
    }).toList();

    final existingMovements = await inventoryStore.getMovements();
    final byId = {for (final movement in existingMovements) movement.id: movement};
    for (final movement in movements) {
      final current = byId[movement.id];
      if (current != null &&
          (current.itemId != movement.itemId ||
              current.movementType != movement.movementType ||
              (current.quantity - movement.quantity).abs() > 0.000001)) {
        throw StateError('حرکت برگشت با اطلاعات مورد انتظار همخوانی ندارد.');
      }
    }

    final missing = movements.where((movement) => !byId.containsKey(movement.id)).toList();
    if (missing.isNotEmpty) {
      await inventoryStore.addMovements(missing);
    }

    final salesReturn = SalesReturn(
      id: returnId,
      deliveryId: delivery.id,
      orderId: delivery.orderId,
      customerId: delivery.customerId,
      customerName: customerName,
      createdAt: now,
      lines: requested.entries.map((entry) {
        final line = deliveryLines[entry.key]!;
        return SalesReturnLine(
          productVariantId: entry.key,
          quantity: entry.value,
          unitSellingPrice: line.unitSellingPrice,
          totalAmount: entry.value * line.unitSellingPrice,
        );
      }).toList(),
      totalAmount: totalAmount,
      note: note,
    );

    await returnStore.add(salesReturn);
    await financialService.postSaleReturn(
      salesReturn,
      customerName: customerName,
    );

    return SalesReturnResult(salesReturn: salesReturn, changed: true);
  }
}
