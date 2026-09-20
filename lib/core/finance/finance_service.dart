import '../customers/customer_store.dart';
import '../sales/sale.dart';
import 'payment.dart';
import 'payment_store.dart';
import 'payment_validator.dart';
import 'receivable.dart';
import 'receivable_store.dart';
import 'receivable_validator.dart';

class PaymentExecutionResult {
  final Payment payment;
  final Receivable receivable;

  const PaymentExecutionResult({
    required this.payment,
    required this.receivable,
  });

  double get remainingAmount => receivable.remainingAmount;
}

class FinanceService {
  final ReceivableStore receivableStore;
  final PaymentStore paymentStore;
  final CustomerStore customerStore;

  const FinanceService({
    required this.receivableStore,
    required this.paymentStore,
    required this.customerStore,
  });

  Future<Receivable> createReceivableFromSale(Sale sale) async {
    if (sale.customerId == null || sale.customerName == null) {
      throw StateError('A receivable requires a customer.');
    }

    final customer = await customerStore.getById(sale.customerId!);

    if (customer == null) {
      throw StateError('Customer with id "${sale.customerId}" does not exist.');
    }

    if (!customer.active) {
      throw StateError('Customer with id "${sale.customerId}" is inactive.');
    }

    if (sale.customerName != customer.name) {
      throw StateError(
        'Customer name snapshot does not match the current customer.',
      );
    }

    final receivable = Receivable(
      id: 'receivable-${sale.id}',
      saleId: sale.id,
      customerId: sale.customerId!,
      customerName: sale.customerName!,
      totalAmount: sale.totalAmount,
      createdAt: sale.saleDate,
    );

    const validator = ReceivableValidator();
    validator.validate(receivable);

    await receivableStore.add(receivable);

    return receivable;
  }

  Future<PaymentExecutionResult> registerPayment(Payment payment) async {
    const validator = PaymentValidator();
    validator.validate(payment);

    final existingPayment = await paymentStore.getById(payment.id);

    if (existingPayment != null) {
      final receivable = await receivableStore.getById(
        existingPayment.receivableId,
      );

      if (receivable == null) {
        throw StateError('Receivable for existing payment does not exist.');
      }

      return PaymentExecutionResult(
        payment: existingPayment,
        receivable: receivable,
      );
    }

    final receivable = await receivableStore.getById(payment.receivableId);

    if (receivable == null) {
      throw StateError(
        'Receivable with id "${payment.receivableId}" does not exist.',
      );
    }

    if (receivable.status == ReceivableStatus.cancelled) {
      throw StateError('Cannot pay a cancelled receivable.');
    }

    if (payment.customerId != receivable.customerId) {
      throw StateError(
        'Payment customer does not match the receivable customer.',
      );
    }

    if (payment.customerName != receivable.customerName) {
      throw StateError('Payment customer name does not match the receivable.');
    }

    if (payment.amount > receivable.remainingAmount) {
      throw StateError('Payment amount exceeds remaining receivable.');
    }

    final newPaidAmount = receivable.paidAmount + payment.amount;

    final newStatus = newPaidAmount >= receivable.totalAmount
        ? ReceivableStatus.paid
        : ReceivableStatus.partiallyPaid;

    final updatedReceivable = receivable.copyWith(
      paidAmount: newPaidAmount,
      status: newStatus,
    );

    await paymentStore.add(payment);
    await receivableStore.update(updatedReceivable);

    return PaymentExecutionResult(
      payment: payment,
      receivable: updatedReceivable,
    );
  }
}
