import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/sales/presentation/pages/sales_order_page.dart';
import '../features/workshop/presentation/screens/workshop_dashboard_screen.dart';

class ZohalApp extends StatelessWidget {
  const ZohalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZOHAL',
      theme: buildZohalTheme(),
      locale: const Locale('fa'),
      home: const ZohalHomePage(),
    );
  }
}

class ZohalHomePage extends StatefulWidget {
  const ZohalHomePage({super.key});

  @override
  State<ZohalHomePage> createState() => _ZohalHomePageState();
}

class _ZohalHomePageState extends State<ZohalHomePage> {
  int _currentIndex = 2;

  final List<Widget> _pages = [
    InventoryPage(),
    SalesOrderPage(),
    DashboardPage(),
    WorkshopDashboardScreen(),
    _PlaceholderTab(
      title: 'دستیار',
      icon: Icons.auto_awesome,
      message: 'دستیار زحل در مرحله طراحی قرار دارد.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          indicatorColor: Theme.of(context).colorScheme.secondaryContainer,
          height: 76,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'انبار',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'صندوق',
            ),
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.precision_manufacturing_outlined),
              selectedIcon: Icon(Icons.precision_manufacturing),
              label: 'کارگاه',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined),
              selectedIcon: Icon(Icons.auto_awesome),
              label: 'دستیار',
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.title,
    required this.icon,
    required this.message,
  });

  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
