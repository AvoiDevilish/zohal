import 'package:flutter/material.dart';

import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/utils/persian_number_formatter.dart';
import '../../../../core/widgets/zohal_card.dart';

enum PersonType { customer, supplier }

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

  @override
  void initState() {
    super.initState();
    _load();
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
    final isCustomer = widget.type == PersonType.customer;
    final totalOrders = _orders.length;
    final totalValue = _orders.fold<int>(
      0,
      (sum, order) => sum + order.totalAmount,
    );
    final completedValue = _orders
        .where((order) => order.status == SalesOrderStatus.delivered)
        .fold<int>(0, (sum, order) => sum + order.totalAmount);

    return Scaffold(
      appBar: AppBar(title: Text(widget.name)),
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
                                widget.name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(isCustomer ? 'مشتری' : 'تأمین‌کننده'),
                              if (widget.phone != null && widget.phone!.isNotEmpty)
                                Text(widget.phone!),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  if (widget.notes != null && widget.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ZohalCard(
                      child: Text(
                        'یادداشت: ' + widget.notes!,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Text(
                    isCustomer ? 'سفارش‌های این مشتری' : 'خریدها و گردش این تأمین‌کننده',
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
    );
  }
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            value,
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
