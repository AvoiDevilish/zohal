import '../storage/local_store.dart';
import 'payment.dart';
import 'payment_validator.dart';

class PaymentStore {
  PaymentStore._();

  static final PaymentStore instance = PaymentStore._();

  static const String _storageKey = 'payments';

  Future<List<Payment>> getPayments() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final payments = rows.map(Payment.fromMap).toList();

    payments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));

    return payments;
  }

  Future<Payment?> getById(String id) async {
    final payments = await getPayments();

    for (final payment in payments) {
      if (payment.id == id) {
        return payment;
      }
    }

    return null;
  }

  Future<void> add(Payment payment) async {
    const validator = PaymentValidator();
    validator.validate(payment);

    final payments = await getPayments();

    if (payments.any((item) => item.id == payment.id)) {
      throw StateError('Payment with id "${payment.id}" already exists.');
    }

    payments.add(payment);

    await LocalStore.instance.writeList(
      _storageKey,
      payments.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
