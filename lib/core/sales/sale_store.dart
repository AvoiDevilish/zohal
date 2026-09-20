import '../storage/local_store.dart';
import 'sale.dart';
import 'sale_validator.dart';

class SaleStore {
  SaleStore._();

  static final SaleStore instance = SaleStore._();

  static const String _storageKey = 'sales';

  Future<List<Sale>> getSales() async {
    final rows = await LocalStore.instance.readList(_storageKey);

    final sales = rows.map(Sale.fromMap).toList();

    sales.sort((a, b) => b.saleDate.compareTo(a.saleDate));

    return sales;
  }

  Future<Sale?> getById(String id) async {
    final sales = await getSales();

    for (final sale in sales) {
      if (sale.id == id) {
        return sale;
      }
    }

    return null;
  }

  Future<void> add(Sale sale) async {
    const validator = SaleValidator();
    validator.validate(sale);

    final sales = await getSales();

    if (sales.any((item) => item.id == sale.id)) {
      throw StateError('Sale with id "${sale.id}" already exists.');
    }

    sales.add(sale);

    await LocalStore.instance.writeList(
      _storageKey,
      sales.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_storageKey);
  }
}
