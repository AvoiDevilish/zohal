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
  List<InventoryMovement> _buildMovements(Sale sale) {
    return sale.items.map((item) {
      return InventoryMovement(
        id: 'sale-' + sale.id + '-' + item.productVariantId,
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
  }

  bool _sameMovement(InventoryMovement left, InventoryMovement right) {
    return left.itemId == right.itemId &&
        left.itemName == right.itemName &&
        left.movementType == right.movementType &&
        (left.quantity - right.quantity).abs() <= 0.000001 &&
        left.unit == right.unit &&
        left.referenceId == right.referenceId;
  }

  bool _sameSale(Sale left, Sale right) {
    if (left.id != right.id ||
        left.customerId != right.customerId ||
        left.customerName != right.customerName ||
        left.saleDate != right.saleDate ||
        left.note != right.note ||
        left.items.length != right.items.length) {
      return false;
    }
    for (var index = 0; index < left.items.length; index++) {
      final a = left.items[index];
      final b = right.items[index];
      if (a.productVariantId != b.productVariantId ||
          a.productName != b.productName ||
          (a.quantity - b.quantity).abs() > 0.000001 ||
          a.unitPrice != b.unitPrice) {
        return false;
      }
    }
    return true;
  }
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
      if (!_sameSale(existingSale, sale)) {
        throw StateError('شناسه فروش برای اطلاعات دیگری استفاده شده است.');
      }

      final existingMovements = (await inventoryStore.getMovements())
          .where((movement) =>
              movement.referenceId == sale.id &&
              movement.movementType == InventoryMovementType.sale)
          .toList();

      final expectedMovements = _buildMovements(existingSale);
      final byId = {for (final movement in existingMovements) movement.id: movement};

      for (final movement in expectedMovements) {
        final current = byId[movement.id];
        if (current != null && !_sameMovement(current, movement)) {
          throw StateError('حرکت فروش با اطلاعات مورد انتظار همخوانی ندارد.');
        }
      }

      final missing = expectedMovements.where((movement) => !byId.containsKey(movement.id)).toList();
      if (missing.isNotEmpty) {
        await inventoryStore.addMovements(missing);
      }

      final reconciledMovements = (await inventoryStore.getMovements())
          .where((movement) =>
              movement.referenceId == existingSale.id &&
              movement.movementType == InventoryMovementType.sale)
          .toList();

      return SaleExecutionResult(
        sale: existingSale,
        movements: reconciledMovements,
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

    final movements = _buildMovements(sale);

    // Persist inventory before the sale record so a failed inventory write
    // cannot leave a sale without its stock movements.
    await inventoryStore.addMovements(movements);
    await saleStore.add(sale);

    return SaleExecutionResult(sale: sale, movements: movements);
  }
}
