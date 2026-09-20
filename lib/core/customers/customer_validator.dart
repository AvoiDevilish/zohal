import 'customer.dart';

class CustomerValidator {
  const CustomerValidator();

  void validate(Customer customer) {
    if (customer.id.trim().isEmpty) {
      throw ArgumentError('Customer id cannot be empty.');
    }

    if (customer.name.trim().isEmpty) {
      throw ArgumentError('Customer name cannot be empty.');
    }

    if (customer.phone != null && customer.phone!.trim().isEmpty) {
      throw ArgumentError('Customer phone cannot be empty when provided.');
    }
  }
}
