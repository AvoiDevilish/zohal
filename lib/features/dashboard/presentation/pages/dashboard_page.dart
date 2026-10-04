import 'package:flutter/material.dart';

import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../../core/design/app_colors.dart';
import '../../../people/presentation/pages/people_page.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../sales/presentation/pages/sales_order_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _orders = SalesOrderStore.instance;
  int orderCount = 0;
  int customerCount = 0;
  int supplierCount = 0;
  int productCount = 0;

  @override
  void initState() {
    super.initState();
    _orders.addListener(_onOrdersChanged);
    load();
  }

  void _onOrdersChanged() {
    if (mounted) load();
  }

  @override
  void dispose() {
    _orders.removeListener(_onOrdersChanged);
    super.dispose();
  }

  Future<void> load() async {
    final rows = await _orders.getAll();
    final customers = await CustomerStore.instance.getAll();
    final suppliers = await SupplierStore.instance.getAll();
    await ProductVariantStore.instance.ensureSeeded();
    final products = await ProductVariantStore.instance.getAll();
    if (!mounted) return;
    setState(() {
      orderCount = rows.where((item) => item.status == SalesOrderStatus.delivered).length;
      customerCount = customers.where((item) => item.isActive).length;
      supplierCount = suppliers.where((item) => item.isActive).length;
      productCount = products.where((item) => item.isActive).length;
    });
  }

  Future<void> openOrders() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SalesOrderPage()),
    );
    await load();
  }

  Future<void> openPeople() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PeoplePage()));
    await load();
  }

  Future<void> openProducts() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ProductsPage()));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ClipRect(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: constraints.maxWidth,
                height: 720,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DashboardCard(
                        icon: Icons.point_of_sale_outlined,
                        title: 'فروش امروز',
                        onTap: () {},
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _MetricRow(label: 'تعداد فروش', value: orderCount.toString()),
                            _MetricRow(label: 'مجموع فروش', value: '— تومان'),
                            _MetricRow(label: 'سود امروز', value: '— تومان'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              icon: Icons.arrow_downward_rounded,
                              title: 'بستانکاری',
                              onTap: () {},
                              child: const Text(
                                '— تومان',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _DashboardCard(
                              icon: Icons.arrow_upward_rounded,
                              title: 'بدهکاری',
                              onTap: () {},
                              child: const Text(
                                '— تومان',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _DashboardCard(
                        icon: Icons.people_outline,
                        title: 'اشخاص',
                        onTap: openPeople,
                        child: Row(
                          children: [
                            Expanded(child: _PersonMetric(title: 'مشتریان', value: customerCount.toString())),
                            const VerticalDivider(width: 1),
                            Expanded(child: _PersonMetric(title: 'تأمین‌کنندگان', value: supplierCount.toString())),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _DashboardCard(
                        icon: Icons.sell_outlined,
                        title: 'محصولات',
                        onTap: openProducts,
                        child: _MetricRow(label: 'محصولات فعال', value: productCount.toString()),
                      ),
                      const SizedBox(height: 8),
                      _DashboardCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'موجودی‌ها',
                        onTap: () {},
                        child: const Row(
                          children: [
                            Expanded(child: _MetricRow(label: 'موجودی قابل فروش', value: '—')),
                            Expanded(child: _MetricRow(label: 'کمبودها', value: '—')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'دسترسی سریع',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _QuickAction(
                              icon: Icons.add_shopping_cart,
                              title: 'ثبت سفارش',
                              onTap: openOrders,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                ),
              ),
            ),
          );
        },
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
