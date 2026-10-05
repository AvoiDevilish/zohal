import 'package:flutter/material.dart';

import '../../../../core/sales/customer.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/supplier.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/utils/persian_number_formatter.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../sales/presentation/pages/sales_order_page.dart';
import '../../../operations/presentation/pages/operations_page.dart';

enum PersonType { customer, supplier, both }

class PersonProfilePage extends StatefulWidget {
  const PersonProfilePage({
    super.key,
    required this.personId,
    required this.name,
    required this.type,
    this.phone,
    this.notes,
  });

  final String personId;
  final String name;
  final PersonType type;
  final String? phone;
  final String? notes;

  @override
  State<PersonProfilePage> createState() => _PersonProfilePageState();
}

class _PersonProfilePageState extends State<PersonProfilePage> {
  List<SalesOrder> _orders = [];
  bool _loading = true;
  late String _name;
  String? _phone;
  String? _notes;

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _phone = widget.phone;
    _notes = widget.notes;
    _load();
  }

  Future<void> _editPerson() async {
    final result = await showDialog<_PersonEditResult>(
      context: context,
      builder: (_) => _PersonEditDialog(
        title: widget.type == PersonType.both
            ? 'ویرایش شخص'
            : widget.type == PersonType.customer
                ? 'ویرایش مشتری'
                : 'ویرایش تأمین‌کننده',
        name: _name,
        phone: _phone,
        notes: _notes,
      ),
    );

    if (result == null || !mounted) return;

    if (widget.type == PersonType.customer || widget.type == PersonType.both) {
      final currentRows = await CustomerStore.instance.getAll();
      final matching = currentRows.where((item) => item.id == widget.personId);
      final existing = matching.isEmpty ? null : matching.first;
      await CustomerStore.instance.upsert(
        Customer(
          id: widget.personId,
          name: result.name,
          phone: result.phone,
          notes: result.notes,
          isActive: existing?.isActive ?? true,
        ),
      );
    }

    if (widget.type == PersonType.supplier || widget.type == PersonType.both) {
      final currentRows = await SupplierStore.instance.getAll();
      final matching = currentRows.where((item) => item.id == widget.personId);
      final existing = matching.isEmpty ? null : matching.first;
      await SupplierStore.instance.upsert(
        Supplier(
          id: widget.personId,
          name: result.name,
          phone: result.phone,
          notes: result.notes,
          isActive: existing?.isActive ?? true,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _name = result.name;
      _phone = result.phone;
      _notes = result.notes;
    });
  }

  Future<void> _load() async {
    final orders = await SalesOrderStore.instance.getAll();
    if (!mounted) return;
    setState(() {
      _orders = widget.type == PersonType.customer
          ? orders.where((item) => item.customerId == widget.personId).toList()
          : [];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCustomer = widget.type == PersonType.customer || widget.type == PersonType.both;
    final isSupplier = widget.type == PersonType.supplier || widget.type == PersonType.both;
    final totalOrders = _orders.length;
    final totalValue = _orders.fold<int>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final completedValue = _orders
        .where((order) => order.status == SalesOrderStatus.delivered)
        .fold<int>(0, (sum, order) => sum + order.totalAmount);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
      appBar: AppBar(
        title: Text(_name, textAlign: TextAlign.right),
        actions: [
          IconButton(
            onPressed: _editPerson,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'ویرایش',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  ZohalCard(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 30,
                          child: Icon(Icons.person_outline, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                widget.type == PersonType.both
                                    ? 'مشتری • تأمین‌کننده'
                                    : isCustomer ? 'مشتری' : 'تأمین‌کننده',
                                textAlign: TextAlign.right,
                              ),
                              if (_phone != null && _phone!.isNotEmpty)
                                Text(_phone!, textAlign: TextAlign.right),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (isCustomer)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SalesOrderPage(initialCustomerId: widget.personId),
                                ),
                              );
                              await _load();
                            },
                            icon: const Icon(Icons.point_of_sale_outlined),
                            label: const Text('ثبت سفارش فروش'),
                          ),
                        ),
                      if (isCustomer && isSupplier) const SizedBox(width: 8),
                      if (isSupplier)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => OperationsPage(initialSupplierId: widget.personId),
                                ),
                              );
                              await _load();
                            },
                            icon: const Icon(Icons.shopping_cart_outlined),
                            label: const Text('ثبت خرید'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ReportCard(
                          icon: Icons.receipt_long_outlined,
                          title: 'تعداد سفارش',
                          value: isCustomer ? totalOrders.toString() : '—',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ReportCard(
                          icon: Icons.payments_outlined,
                          title: 'گردش سفارش',
                          value: isCustomer
                              ? PersianNumberFormatter.money(totalValue)
                              : '—',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _ReportCard(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'گردش حساب',
                    value: isCustomer && completedValue > 0
                        ? PersianNumberFormatter.money(completedValue)
                        : 'هنوز تراکنش مالی ثبت نشده',
                    subtitle: 'جزئیات دریافت، بدهی و تسویه از هسته مالی تغذیه خواهد شد.',
                  ),
                  if (_notes != null && _notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ZohalCard(
                      child: Text(
                        'یادداشت: ' + _notes!,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    widget.type == PersonType.both ? 'سفارش‌ها و گردش این شخص' : isCustomer ? 'سفارش‌های این مشتری' : 'خریدها و گردش این تأمین‌کننده',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  if (!isCustomer)
                    const ZohalCard(
                      child: Text('به‌محض اتصال خرید و حساب تأمین‌کننده، این بخش به‌صورت خودکار گزارش خواهد شد.'),
                    )
                  else if (_orders.isEmpty)
                    const ZohalCard(child: Text('هنوز سفارشی برای این مشتری ثبت نشده است.'))
                  else
                    ..._orders.map(
                      (order) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ZohalCard(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('سفارش ' + order.id),
                            subtitle: Text(
                              order.lines.length.toString() +
                                  ' ردیف • ' +
                                  order.status.title,
                            ),
                            trailing: Text(
                              PersianNumberFormatter.money(order.totalAmount),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
      ),
    );
  }
}

class _PersonEditDialog extends StatefulWidget {
  const _PersonEditDialog({
    required this.title,
    required this.name,
    this.phone,
    this.notes,
  });

  final String title;
  final String name;
  final String? phone;
  final String? notes;

  @override
  State<_PersonEditDialog> createState() => _PersonEditDialogState();
}

class _PersonEditDialogState extends State<_PersonEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _phoneController = TextEditingController(text: widget.phone ?? '');
    _notesController = TextEditingController(text: widget.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PersonEditResult(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: Text(widget.title),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  textAlign: TextAlign.right,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'نام'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'نام را وارد کنید'
                          : null,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _phoneController,
                  textAlign: TextAlign.right,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'تلفن'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(labelText: 'یادداشت'),
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
          FilledButton(
            onPressed: _save,
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
  }
}

class _PersonEditResult {
  const _PersonEditResult({
    required this.name,
    this.phone,
    this.notes,
  });

  final String name;
  final String? phone;
  final String? notes;
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ZohalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.right, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      ),
    );
  }
}
