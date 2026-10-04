import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../people/presentation/pages/people_page.dart';
import '../../../sales/presentation/pages/sales_order_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _orders = SalesOrderStore.instance;
  int orderCount = 0;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final rows = await _orders.getAll();
    if (!mounted) return;
    setState(() => orderCount = rows.length);
  }

  Future<void> openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SalesOrderPage()),
    );
    await load();
  }

  Future<void> openPeople() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PeoplePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          const Text(
            'خانه',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'خلاصه وضعیت کسب‌وکار',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _DashboardCard(
            icon: Icons.point_of_sale_outlined,
            title: 'فروش امروز',
            onTap: () {},
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MetricRow(label: 'تعداد فروش', value: '—'),
                _MetricRow(label: 'مجموع فروش', value: '— تومان'),
                _MetricRow(label: 'سود امروز', value: '— تومان'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardCard(
                  icon: Icons.arrow_downward_rounded,
                  title: 'بستانکاری',
                  onTap: () {},
                  child: const Text(
                    '— تومان',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardCard(
                  icon: Icons.arrow_upward_rounded,
                  title: 'بدهکاری',
                  onTap: () {},
                  child: const Text(
                    '— تومان',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _DashboardCard(
            icon: Icons.people_outline,
            title: 'اشخاص',
            onTap: openPeople,
            child: Row(
              children: [
                Expanded(child: _PersonMetric(title: 'مشتریان', value: '—')),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _PersonMetric(title: 'تأمین‌کنندگان', value: '—'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DashboardCard(
            icon: Icons.inventory_2_outlined,
            title: 'موجودی‌ها',
            onTap: () {},
            child: const Column(
              children: [
                _MetricRow(label: 'موجودی قابل فروش', value: '—'),
                _MetricRow(label: 'مواد و اقلام', value: '—'),
                _MetricRow(label: 'کمبودها', value: '—'),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'دسترسی سریع',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.add_shopping_cart,
                  title: 'ثبت سفارش',
                  onTap: openOrders,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.warning_amber_outlined,
                  title: 'هشدار کمبود',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.child,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: ZohalCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_left_rounded),
                ],
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _PersonMetric extends StatelessWidget {
  const _PersonMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: ZohalCard(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
