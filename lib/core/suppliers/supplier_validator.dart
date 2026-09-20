import 'supplier.dart';

class SupplierValidationException implements Exception {
  final String message;

  const SupplierValidationException(this.message);

  @override
  String toString() => message;
}

class SupplierValidator {
  const SupplierValidator();

  void validate(Supplier supplier) {
    if (supplier.id.trim().isEmpty) {
      throw const SupplierValidationException(
        'شناسه تأمین‌کننده نمی‌تواند خالی باشد.',
      );
    }

    if (supplier.name.trim().isEmpty) {
      throw const SupplierValidationException(
        'نام تأمین‌کننده نمی‌تواند خالی باشد.',
      );
    }

    if (supplier.phone != null && supplier.phone!.trim().isEmpty) {
      throw const SupplierValidationException(
        'شماره تماس تأمین‌کننده نمی‌تواند خالی باشد.',
      );
    }
  }
}
