import 'sale.dart';

class SaleValidator {
  const SaleValidator();

  void validate(Sale sale) {
    if (sale.id.trim().isEmpty) {
      throw ArgumentError('Sale id cannot be empty.');
    }

    if (sale.items.isEmpty) {
      throw ArgumentError('Sale must contain at least one item.');
    }

    if (sale.customerId != null) {
      if (sale.customerId!.trim().isEmpty) {
        throw ArgumentError('Customer id cannot be empty when provided.');
      }

      if (sale.customerName == null || sale.customerName!.trim().isEmpty) {
        throw ArgumentError(
          'Customer name snapshot is required when customer id is provided.',
        );
      }
    }

    for (final item in sale.items) {
      if (item.productVariantId.trim().isEmpty) {
        throw ArgumentError('Sale item product variant id cannot be empty.');
      }

      if (item.productName.trim().isEmpty) {
        throw ArgumentError('Sale item product name cannot be empty.');
      }

      if (item.quantity <= 0) {
        throw ArgumentError('Sale item quantity must be greater than zero.');
      }

      if (item.unitPrice < 0) {
        throw ArgumentError('Sale item unit price cannot be negative.');
      }
    }
  }
}
