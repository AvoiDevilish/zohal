import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/customer.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/product_variant.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/widgets/zohal_card.dart';

class SalesOrderPage extends StatefulWidget {
  const SalesOrderPage({super.key});

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

  Future<void> addCustomer() async {
    final customer = await showDialog<Customer>(
      context: context,
      builder: (_) => const _CustomerDialog(),
    );
    if (customer == null || !mounted) return;
    await _customers.upsert(customer);
    await load();
  }

  Future<void> addOrder() async {
    if (customers.isEmpty) {
      await addCustomer();
      if (customers.isEmpty) return;
    }

    final order = await showDialog<SalesOrder>(
      context: context,
      builder: (_) => _NewOrderDialog(
        products: products,
        customers: customers,
      ),
    );
    if (order == null || !mounted) return;

    await _orders.create(order);
    await load();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('سفارش ثبت شد و به کارگاه ارجاع شد.')),
    );
  }

  Future<void> editPrice(ProductVariant product) async {
    final controller = TextEditingController(
      text: product.currentSellingPrice.toString(),
    );

    final price = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ویرایش قیمت ' + product.displayName),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'قیمت فروش جاری',
            suffixText: 'تومان',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(
                controller.text.trim().replaceAll(',', ''),
              );
              if (value == null || value <= 0) return;
              Navigator.pop(dialogContext, value);
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (price == null || !mounted) return;

    await _products.upsert(product.copyWith(currentSellingPrice: price));
    await load();
  }

  String money(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) buffer.write(',');
      buffer.write(raw[i]);
    }
    return buffer.toString() + ' تومان';
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
      appBar: AppBar(
        title: const Text('صندوق'),
        actions: [
          IconButton(
            onPressed: addCustomer,
            tooltip: 'افزودن مشتری',
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
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
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  const Text(
                    'قیمت فروش جاری',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ...products.map(
                    (product) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ZohalCard(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            child: Icon(Icons.sell_outlined),
                          ),
                          title: Text(
                            product.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(money(product.currentSellingPrice)),
                          trailing: IconButton(
                            onPressed: () => editPrice(product),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text(
                    'سفارش‌های فروش',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (orders.isEmpty)
                    const ZohalCard(child: Text('هنوز سفارشی ثبت نشده است.')),
                  ...orders.map(
                    (order) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: ZohalCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سفارش ' + order.id,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text('مشتری: ' + order.customerName),
                            Text(
                              'اقلام: ' +
                                  order.lines.length.toString() +
                                  ' ردیف',
                            ),
                            Text('تاریخ: ' + date(order.orderDate)),
                            Text('مبلغ: ' + money(order.totalAmount)),
                            const SizedBox(height: 6),
                            Chip(label: Text(order.status.title)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog();

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final key = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    super.dispose();
  }

  void save() {
    if (!key.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('افزودن مشتری'),
      content: Form(
        key: key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'نام مشتری'),
              validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'نام مشتری را وارد کنید'
                      : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'تلفن'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: save, child: const Text('ذخیره')),
      ],
    );
  }
}

class _NewOrderDialog extends StatefulWidget {
  const _NewOrderDialog({
    required this.products,
    required this.customers,
  });

  final List<ProductVariant> products;
  final List<Customer> customers;

  @override
  State<_NewOrderDialog> createState() => _NewOrderDialogState();
}

class _NewOrderDialogState extends State<_NewOrderDialog> {
  final key = GlobalKey<FormState>();
  late String customerId;
  late String productId;
  int quantity = 1;
  DateTime orderDate = DateTime.now();

  ProductVariant get product =>
      widget.products.firstWhere((item) => item.id == productId);

  Customer get customer =>
      widget.customers.firstWhere((item) => item.id == customerId);

  int get total => product.currentSellingPrice * quantity;

  @override
  void initState() {
    super.initState();
    customerId = widget.customers.first.id;
    productId = widget.products.first.id;
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => orderDate = picked);
  }

  void save() {
    if (!key.currentState!.validate()) return;

    final line = SalesOrderLine(
      productVariantId: product.id,
      productName: product.productName,
      flavor: product.flavor,
      packageLabel: product.packageLabel,
      quantity: quantity,
      unitSellingPrice: product.currentSellingPrice,
      lineTotal: total,
    );

    Navigator.pop(
      context,
      SalesOrder(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        customerId: customer.id,
        customerName: customer.name,
        orderDate: orderDate,
        lines: [line],
        totalAmount: total,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ثبت سفارش مشتری'),
      content: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: customerId,
                decoration: const InputDecoration(labelText: 'مشتری'),
                items: widget.customers
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => customerId = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: productId,
                decoration: const InputDecoration(labelText: 'نوع محصول'),
                items: widget.products
                    .map(
                      (item) => DropdownMenuItem(
                        value: item.id,
                        child: Text(item.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => productId = value);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                initialValue: '1',
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'تعداد'),
                validator: (value) {
                  final number = int.tryParse(value?.trim() ?? '');
                  return number == null || number <= 0
                      ? 'تعداد معتبر وارد کنید'
                      : null;
                },
                onChanged: (value) {
                  final number = int.tryParse(value.trim());
                  if (number != null && number > 0) {
                    setState(() => quantity = number);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تاریخ سفارش'),
                subtitle: Text(
                  orderDate.year.toString() +
                      '/' +
                      orderDate.month.toString().padLeft(2, '0') +
                      '/' +
                      orderDate.day.toString().padLeft(2, '0'),
                ),
                trailing: TextButton(
                  onPressed: pickDate,
                  child: const Text('انتخاب'),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(child: Text('قیمت واحد')),
                  Text(product.currentSellingPrice.toString() + ' تومان'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'مبلغ سفارش',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    total.toString() + ' تومان',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton.icon(
          onPressed: save,
          icon: const Icon(Icons.send),
          label: const Text('ثبت و ارجاع به کارگاه'),
        ),
      ],
    );
  }
}
