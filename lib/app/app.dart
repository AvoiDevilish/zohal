import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../core/finance/financial_store.dart';
import '../core/people/person_migration_service.dart';
import '../core/people/person_store.dart';
import '../core/sales/customer_store.dart';
import '../core/sales/supplier_store.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/sales/presentation/pages/sales_order_page.dart';
import '../features/operations/presentation/pages/operations_page.dart';
import '../features/assistant/presentation/pages/assistant_page.dart';

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
  int _currentIndex = 1;

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
    SalesOrderPage(),
    DashboardPage(),
    OperationsPage(),
    AssistantPage(),
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
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'عملیات',
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
