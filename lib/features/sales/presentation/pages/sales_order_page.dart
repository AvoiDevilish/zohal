import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/customer.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/product_variant.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../../core/utils/persian_number_formatter.dart';
import '../../../people/presentation/pages/people_page.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key, this.initialCustomerId});
  final String? initialCustomerId;

  @override
  State<SalesOrderPage> createState() => _SalesOrderPageState();
}

class _SalesOrderPageState extends State<SalesOrderPage> {
  final _products = ProductVariantStore.instance;
  final _customers = CustomerStore.instance;
  final _orders = SalesOrderStore.instance;

  List<ProductVariant> products = [];
  List<Customer> customers = [];
  List<SalesOrder> orders = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    await _products.ensureSeeded();
    final productRows = await _products.getAll();
    final customerRows = await _customers.getAll();
    final orderRows = await _orders.getAll();
    if (!mounted) return;
    setState(() {
      products = productRows.where((item) => item.isActive).toList();
      customers = customerRows.where((item) => item.isActive).toList();
      orders = orderRows;
      loading = false;
    });
  }

  Future<void> openPeople() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const PeoplePage(),
    ));
    await load();
  }

  Future<void> addOrder() async {
    if (customers.isEmpty) {
      await openPeople();
      if (customers.isEmpty) return;
    }
    final order = await Navigator.of(context).push<SalesOrder>(
      MaterialPageRoute<SalesOrder>(
        builder: (_) => _NewOrderPage(
          products: products,
          customers: customers,
          initialCustomerId: widget.initialCustomerId,
        ),
      ),
    );
    if (order == null || !mounted) return;
    await _orders.create(order);
    await load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سفارش ثبت شد و در صف کارگاه قرار گرفت.')),
    );
  }


  String date(DateTime value) {
    return value.year.toString() +
        '/' +
        value.month.toString().padLeft(2, '0') +
        '/' +
        value.day.toString().padLeft(2, '0');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ثبت سفارش')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addOrder,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('ثبت سفارش'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
                children: [
                  const Text(
                    'سفارش‌های ثبت‌شده',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (orders.isEmpty)
                    const ZohalCard(child: Text('هنوز سفارشی ثبت نشده است.')),
                  ...orders.map((order) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: ZohalCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('سفارش ' + order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          Text('مشتری: ' + order.customerName),
                          Text('اقلام: ' + order.lines.length.toString() + ' ردیف'),
                          Text('تاریخ: ' + date(order.orderDate)),
                          Text('مبلغ: ' + PersianNumberFormatter.money(order.totalAmount)),
                          const SizedBox(height: 6),
                          Chip(label: Text(order.status.title)),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
      ),
    );
  }


}

class _NewOrderPage extends StatefulWidget {
  const _NewOrderPage({required this.products, required this.customers, this.initialCustomerId});
  final List<ProductVariant> products;
  final List<Customer> customers;
  final String? initialCustomerId;
  @override State<_NewOrderPage> createState() => _NewOrderPageState();
}

class _NewOrderPageState extends State<_NewOrderPage> {
  late String customerId;
  final List<_DraftLine> lines = [];

  @override
  void initState() {
    super.initState();
    customerId = widget.customers.any((x) => x.id == widget.initialCustomerId)
        ? widget.initialCustomerId!
        : widget.customers.first.id;
    _addLine();
  }

  @override
  void dispose() {
    for (final line in lines) {
      line.quantityController.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    final available = widget.products.where(
      (p) => !lines.any((line) => line.productId == p.id),
    );
    if (available.isEmpty) return;
    setState(() => lines.add(_DraftLine(
      productId: available.first.id,
      quantityController: TextEditingController(text: '1'),
    )));
  }

  void _removeLine(int index) {
    final line = lines.removeAt(index);
    line.quantityController.dispose();
    setState(() {});
  }

  ProductVariant productFor(_DraftLine line) =>
      widget.products.firstWhere((item) => item.id == line.productId);

  int get total => lines.fold(0, (sum, line) {
    final q = int.tryParse(line.quantityController.text) ?? 0;
    return sum + productFor(line).currentSellingPrice * q;
  });

  void save() {
    final draftLines = <SalesOrderLine>[];
    for (final line in lines) {
      final q = int.tryParse(line.quantityController.text.trim());
      if (q == null || q <= 0) return;
      final p = productFor(line);
      draftLines.add(SalesOrderLine(
        productVariantId: p.id,
        productName: p.productName,
        flavor: p.flavor,
        packageLabel: p.packageLabel,
        quantity: q,
        unitSellingPrice: p.currentSellingPrice,
        lineTotal: p.currentSellingPrice * q,
      ));
    }
    if (draftLines.isEmpty) return;
    final customer = widget.customers.firstWhere((item) => item.id == customerId);
    Navigator.of(context).pop(SalesOrder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerId: customer.id,
      customerName: customer.name,
      orderDate: DateTime.now(),
      lines: List.unmodifiable(draftLines),
      totalAmount: total,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final canAddMore = lines.length < widget.products.length;
    return Scaffold(
      appBar: AppBar(title: const Text('سفارش جدید')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: save,
        icon: const Icon(Icons.send),
        label: const Text('ثبت و ارجاع به کارگاه'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
        children: [
          DropdownButtonFormField<String>(
            initialValue: customerId,
            decoration: const InputDecoration(labelText: 'مشتری'),
            items: widget.customers.map((item) => DropdownMenuItem(
              value: item.id, child: Text(item.name),
            )).toList(),
            onChanged: (value) {
              if (value != null) setState(() => customerId = value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(child: Text('اقلام سفارش', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
              OutlinedButton.icon(
                onPressed: canAddMore ? _addLine : null,
                icon: const Icon(Icons.add),
                label: const Text('افزودن محصول'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...List.generate(lines.length, (index) {
            final line = lines[index];
            final p = productFor(line);
            final selectedIds = lines.map((item) => item.productId).toSet();
            final options = widget.products.where(
              (item) => item.id == line.productId || !selectedIds.contains(item.id),
            );
            final q = int.tryParse(line.quantityController.text) ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: ZohalCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: line.productId,
                            decoration: const InputDecoration(labelText: 'محصول'),
                            items: options.map((item) => DropdownMenuItem(
                              value: item.id,
                              child: Text(
                                item.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (value) {
                              if (value != null) setState(() => line.productId = value);
                            },
                          ),
                        ),
                        if (lines.length > 1)
                          IconButton(
                            onPressed: () => _removeLine(index),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: line.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'تعداد'),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Expanded(child: Text('قیمت واحد')),
                        Text(PersianNumberFormatter.money(p.currentSellingPrice)),
                      ],
                    ),
                    Row(
                      children: [
                        const Expanded(child: Text('مبلغ ردیف')),
                        Text(PersianNumberFormatter.money(p.currentSellingPrice * q)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(child: Text('مبلغ کل سفارش', style: TextStyle(fontWeight: FontWeight.w800))),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  PersianNumberFormatter.money(total),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ZohalCard(
            child: Text(
              'به حروف: ' + PersianNumberFormatter.words(total) + ' تومان',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DraftLine {
  _DraftLine({required this.productId, required this.quantityController});
  String productId;
  final TextEditingController quantityController;
}
