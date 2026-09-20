import 'payment.dart';

class PaymentValidator {
  const PaymentValidator();

  void validate(Payment payment) {
    if (payment.id.trim().isEmpty) {
      throw ArgumentError('Payment id cannot be empty.');
    }

    if (payment.receivableId.trim().isEmpty) {
      throw ArgumentError('Payment receivable id cannot be empty.');
    }

    if (payment.customerId.trim().isEmpty) {
      throw ArgumentError('Payment customer id cannot be empty.');
    }

    if (payment.customerName.trim().isEmpty) {
      throw ArgumentError('Payment customer name cannot be empty.');
    }

    if (payment.amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
  }
}
