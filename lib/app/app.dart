import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/finance/financial_store.dart';
import '../core/people/person_migration_service.dart';
import '../core/people/person_store.dart';
import '../core/sales/customer_store.dart';
import '../core/sales/supplier_store.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
import '../features/people/presentation/pages/people_page.dart';
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

  @override
  void initState() {
    super.initState();
    _migratePeople();
  }

  Future<void> _migratePeople() async {
    await PersonMigrationService(
      personStore: PersonStore.instance,
      customerStore: CustomerStore.instance,
      supplierStore: SupplierStore.instance,
      financialStore: FinancialStore.instance,
    ).migrateLegacyPeople();
  }

  final List<Widget> _pages = [
    InventoryPage(),
    SalesOrderPage(),
    DashboardPage(),
    WorkshopDashboardScreen(),
    PeoplePage(),
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
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'انبار',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'فروش',
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
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'اشخاص',
            ),
          ],
        ),
      ),
    );
  }
}
