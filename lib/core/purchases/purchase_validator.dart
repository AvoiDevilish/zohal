import 'purchase.dart';

class PurchaseValidator {
  const PurchaseValidator();

  void validate(Purchase purchase) {
    if (purchase.id.trim().isEmpty) {
      throw ArgumentError('Purchase id cannot be empty.');
    }

    if (purchase.materialId.trim().isEmpty) {
      throw ArgumentError('Purchase material id cannot be empty.');
    }

    if (purchase.materialName.trim().isEmpty) {
      throw ArgumentError('Purchase material name cannot be empty.');
    }

    if (purchase.quantity <= 0) {
      throw ArgumentError('Purchase quantity must be greater than zero.');
    }

    if (purchase.unit.trim().isEmpty) {
      throw ArgumentError('Purchase unit cannot be empty.');
    }

    if (purchase.unitPrice < 0) {
      throw ArgumentError('Purchase unit price cannot be negative.');
    }

    if (purchase.supplierId != null && purchase.supplierId!.trim().isEmpty) {
      throw ArgumentError('Supplier id cannot be empty when provided.');
    }

    if (purchase.supplierName != null &&
        purchase.supplierName!.trim().isEmpty) {
      throw ArgumentError('Supplier name cannot be empty when provided.');
    }

    if (purchase.supplierId != null && purchase.supplierName == null) {
      throw ArgumentError(
        'Supplier name snapshot is required when supplier id is provided.',
      );
    }
  }
}
