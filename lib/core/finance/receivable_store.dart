import '../storage/local_store.dart';
import 'receivable.dart';
import 'receivable_validator.dart';

class ReceivableStore {
  ReceivableStore._();

  static final ReceivableStore instance = ReceivableStore._();

  static const String _storageKey = 'receivables';

  Future<List<Receivable>> getReceivables() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final receivables = rows.map(Receivable.fromMap).toList();

    receivables.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return receivables;
  }

  Future<Receivable?> getById(String id) async {
    final receivables = await getReceivables();

    for (final receivable in receivables) {
      if (receivable.id == id) {
        return receivable;
      }
    }

    return null;
  }

  Future<void> add(Receivable receivable) async {
    const validator = ReceivableValidator();
    validator.validate(receivable);

    final receivables = await getReceivables();

    if (receivables.any((item) => item.id == receivable.id)) {
      throw StateError('Receivable with id "${receivable.id}" already exists.');
    }

    receivables.add(receivable);

    await LocalStore.instance.writeList(
      _storageKey,
      receivables.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> update(Receivable receivable) async {
    const validator = ReceivableValidator();
    validator.validate(receivable);

    final receivables = await getReceivables();

    final index = receivables.indexWhere((item) => item.id == receivable.id);

    if (index == -1) {
      throw StateError('Receivable with id "${receivable.id}" does not exist.');
    }

    receivables[index] = receivable;

    await LocalStore.instance.writeList(
      _storageKey,
      receivables.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
