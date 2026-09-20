import 'receivable.dart';

class ReceivableValidator {
  const ReceivableValidator();

  void validate(Receivable receivable) {
    if (receivable.id.trim().isEmpty) {
      throw ArgumentError('Receivable id cannot be empty.');
    }

    if (receivable.saleId.trim().isEmpty) {
      throw ArgumentError('Receivable sale id cannot be empty.');
    }

    if (receivable.customerId.trim().isEmpty) {
      throw ArgumentError('Receivable customer id cannot be empty.');
    }

    if (receivable.customerName.trim().isEmpty) {
      throw ArgumentError('Receivable customer name cannot be empty.');
    }

    if (receivable.totalAmount <= 0) {
      throw ArgumentError('Receivable total amount must be greater than zero.');
    }

    if (receivable.paidAmount < 0) {
      throw ArgumentError('Receivable paid amount cannot be negative.');
    }

    if (receivable.paidAmount > receivable.totalAmount) {
      throw ArgumentError('Receivable paid amount cannot exceed total amount.');
    }
  }
}
