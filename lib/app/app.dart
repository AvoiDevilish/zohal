import 'package:flutter/material.dart';

import '../core/design/app_theme.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/products/presentation/pages/products_page.dart';
import '../features/materials/presentation/pages/materials_page.dart';
import '../features/inventory/presentation/pages/inventory_page.dart';
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
  int _currentIndex = 0;

  final List<Widget> _pages = [
    DashboardPage(),
    Center(child: Text('فروش')),
    InventoryPage(),
    ProductsPage(),
    Center(child: Text('مشتریان')),
    MaterialsPage(),
    WorkshopDashboardScreen(),
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
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'خانه',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'فروش',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'انبار',
            ),
            NavigationDestination(
              icon: Icon(Icons.category_outlined),
              selectedIcon: Icon(Icons.category),
              label: 'محصولات',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'مشتریان',
            ),
            NavigationDestination(
              icon: Icon(Icons.layers_outlined),
              selectedIcon: Icon(Icons.layers),
              label: 'مواد و اقلام',
            ),
            NavigationDestination(
              icon: Icon(Icons.precision_manufacturing_outlined),
              selectedIcon: Icon(Icons.precision_manufacturing),
              label: 'کارگاه',
            ),
          ],
        ),
      ),
    );
  }
}
