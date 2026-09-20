import '../customers/customer_store.dart';
import '../inventory/inventory_movement.dart';
import '../inventory/inventory_store.dart';
import 'sale.dart';
import 'sale_store.dart';
import 'sale_validator.dart';

class SaleExecutionResult {
  final Sale sale;
  final List<InventoryMovement> movements;
  final bool alreadyExecuted;

  const SaleExecutionResult({
    required this.sale,
    required this.movements,
    this.alreadyExecuted = false,
  });

  double get totalAmount => sale.totalAmount;
}

class SaleService {
  final SaleStore saleStore;
  final InventoryStore inventoryStore;
  final CustomerStore customerStore;

  const SaleService({
    required this.saleStore,
    required this.inventoryStore,
    required this.customerStore,
  });

  Future<SaleExecutionResult> registerSale(Sale sale) async {
    const validator = SaleValidator();
    validator.validate(sale);

    final existingSale = await saleStore.getById(sale.id);

    if (existingSale != null) {
      final existingMovements = (await inventoryStore.getMovements())
          .where(
            (movement) =>
                movement.referenceId == sale.id &&
                movement.movementType == InventoryMovementType.sale,
          )
          .toList();

      return SaleExecutionResult(
        sale: existingSale,
        movements: existingMovements,
        alreadyExecuted: true,
      );
    }

    if (sale.customerId != null) {
      final customer = await customerStore.getById(sale.customerId!);

      if (customer == null) {
        throw StateError(
          'Customer with id "${sale.customerId}" does not exist.',
        );
      }

      if (!customer.active) {
        throw StateError('Customer with id "${sale.customerId}" is inactive.');
      }

      if (sale.customerName != customer.name) {
        throw StateError(
          'Customer name snapshot does not match the current customer.',
        );
      }
    }

    final stockByItem = await inventoryStore.getAllStocks();

    for (final item in sale.items) {
      final available = stockByItem[item.productVariantId] ?? 0;

      if (available < item.quantity) {
        throw StateError(
          'Insufficient stock for "${item.productName}". '
          'Required: ${item.quantity}, available: $available.',
        );
      }
    }

    final movements = sale.items.map((item) {
      return InventoryMovement(
        id: 'sale-${sale.id}-${item.productVariantId}',
        itemId: item.productVariantId,
        itemName: item.productName,
        itemType: 'finishedProduct',
        quantity: item.quantity.toDouble(),
        unit: 'عدد',
        movementType: InventoryMovementType.sale,
        timestamp: sale.saleDate,
        referenceId: sale.id,
        note: sale.note,
      );
    }).toList();

    await saleStore.add(sale);
    await inventoryStore.addMovements(movements);

    return SaleExecutionResult(sale: sale, movements: movements);
  }
}
