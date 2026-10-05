import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../inventory/presentation/pages/inventory_page.dart';
import '../../../people/presentation/pages/people_page.dart';
import '../../../products/presentation/pages/products_page.dart';
import '../../../sales/presentation/pages/sales_order_page.dart';
import '../../../workshop/presentation/screens/workshop_dashboard_screen.dart';

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
  int pendingWorkshop = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _orders.addListener(_refreshFromStore);
    load();
  }

  void _refreshFromStore() {
    if (mounted) load();
  }

  @override
  void dispose() {
    _orders.removeListener(_refreshFromStore);
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
      orderCount = rows.length;
      customerCount = customers.where((item) => item.isActive).length;
      supplierCount = suppliers.where((item) => item.isActive).length;
      productCount = products.where((item) => item.isActive).length;
      pendingWorkshop = rows.where((item) => const {
        SalesOrderStatus.workshopPending,
        SalesOrderStatus.workshopAnalyzing,
        SalesOrderStatus.readyForProduction,
        SalesOrderStatus.materialsReserved,
        SalesOrderStatus.shortage,
        SalesOrderStatus.inProduction,
      }.contains(item.status)).length;
      loading = false;
    });
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
    await load();
  }

  Future<void> _openPeople() => _open(const PeoplePage());
  Future<void> _openProducts() => _open(const ProductsPage());
  Future<void> _openOrders() => _open(const SalesOrderPage());
  Future<void> _openInventory() => _open(const InventoryPage());
  Future<void> _openWorkshop() => _open(WorkshopDashboardScreen());

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildHero(),
                const SizedBox(height: 18),
                _buildSectionTitle('وضعیت زحل', 'نمای کلی عملیات'),
                const SizedBox(height: 10),
                _buildMetrics(),
                const SizedBox(height: 20),
                _buildSectionTitle('دسترسی سریع', 'کارهای اصلی'),
                const SizedBox(height: 10),
                _buildQuickActions(),
                const SizedBox(height: 20),
                _buildWorkshopCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: AppColors.yellow,
            size: 26,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'زحل',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
              ),
              SizedBox(height: 2),
              Text(
                'مدیریت کسب‌وکار',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => load(),
          tooltip: 'به‌روزرسانی',
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'همه‌چیز تحت کنترل است.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  loading
                      ? 'در حال دریافت وضعیت...'
                      : '$pendingWorkshop سفارش در جریان عملیات کارگاه است.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openOrders,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                  ),
                  icon: const Icon(Icons.add_shopping_cart_outlined),
                  label: const Text('ثبت سفارش'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bolt_rounded,
              color: AppColors.yellow,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetrics() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.shopping_bag_outlined,
            value: orderCount.toString(),
            label: 'سفارش',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            icon: Icons.people_outline_rounded,
            value: customerCount.toString(),
            label: 'مشتری',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            icon: Icons.inventory_2_outlined,
            value: productCount.toString(),
            label: 'محصول',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            icon: Icons.local_shipping_outlined,
            value: supplierCount.toString(),
            label: 'تأمین‌کننده',
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.35,
      children: [
        _QuickAction(
          icon: Icons.people_alt_outlined,
          title: 'اشخاص',
          subtitle: '$customerCount مشتری • $supplierCount تأمین‌کننده',
          onTap: _openPeople,
        ),
        _QuickAction(
          icon: Icons.sell_outlined,
          title: 'محصولات',
          subtitle: '$productCount محصول فعال',
          onTap: _openProducts,
        ),
        _QuickAction(
          icon: Icons.inventory_2_outlined,
          title: 'انبار',
          subtitle: 'موجودی و گردش‌ها',
          onTap: _openInventory,
        ),
        _QuickAction(
          icon: Icons.precision_manufacturing_outlined,
          title: 'کارگاه',
          subtitle: '$pendingWorkshop مورد در جریان',
          onTap: _openWorkshop,
        ),
      ],
    );
  }

  Widget _buildWorkshopCard() {
    return ZohalCard(
      padding: const EdgeInsets.all(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _openOrders,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.timeline_rounded),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'زنجیره عملیات',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'سفارش ← کارگاه ← تحویل ← مالی',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ZohalCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 21),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ZohalCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 21),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
