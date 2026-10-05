import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/finance/financial_store.dart';
import '../../../../core/inventory/inventory_item.dart';
import '../../../../core/inventory/inventory_item_store.dart';
import '../../../../core/inventory/inventory_store.dart';
import '../../../../core/purchase.dart';
import '../../../../core/purchase_return_store.dart';
import '../../../../core/purchase_service.dart';
import '../../../../core/purchase_store.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/sales_delivery.dart';
import '../../../../core/sales/sales_delivery_service.dart';
import '../../../../core/sales/sales_delivery_store.dart';
import '../../../../core/sales/sales_order.dart';
import '../../../../core/sales/sales_order_store.dart';
import '../../../../core/sales/sales_return.dart';
import '../../../../core/sales/sales_return_service.dart';
import '../../../../core/sales/sales_return_store.dart';
import '../../../../core/finance/sales_financial_service.dart';
import '../../../../core/sales/supplier.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/utils/persian_number_formatter.dart';
import '../../../../core/widgets/zohal_card.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عملیات کسب‌وکار')),
        body: IndexedStack(
          index: tab,
          children: const [_PurchasesTab(), _DeliveryTab(), _ReturnsTab(), _FinanceTab()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: (value) => setState(() => tab = value),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.shopping_cart_outlined), selectedIcon: Icon(Icons.shopping_cart), label: 'خرید'),
            NavigationDestination(icon: Icon(Icons.local_shipping_outlined), selectedIcon: Icon(Icons.local_shipping), label: 'تحویل'),
            NavigationDestination(icon: Icon(Icons.assignment_return_outlined), selectedIcon: Icon(Icons.assignment_return), label: 'برگشت'),
            NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'مالی'),
          ],
        ),
      ),
    );
  }
}

class _PurchasesTab extends StatefulWidget {
  const _PurchasesTab();
  @override State<_PurchasesTab> createState() => _PurchasesTabState();
}

class _PurchasesTabState extends State<_PurchasesTab> {
  List<Purchase> purchases = [];
  List<Supplier> suppliers = [];
  List<InventoryItem> items = [];
  bool loading = true;

  PurchaseService get service => PurchaseService(
    inventoryStore: InventoryStore.instance,
    purchaseStore: PurchaseStore.instance,
    financialStore: FinancialStore.instance,
    purchaseReturnStore: PurchaseReturnStore.instance,
  );

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    await InventoryItemStore.instance.ensureSeeded();
    final p = await PurchaseStore.instance.getAll();
    final s = await SupplierStore.instance.getAll();
    final i = await InventoryItemStore.instance.getItems();
    if (!mounted) return;
    setState(() {
      purchases = p;
      suppliers = s.where((x) => x.isActive).toList();
      items = i;
      loading = false;
    });
  }

  Future<void> addPurchase() async {
    if (suppliers.isEmpty) return _message('ابتدا یک تأمین‌کننده در بخش اشخاص ثبت کنید.');
    final purchase = await Navigator.of(context).push<Purchase>(
      MaterialPageRoute(builder: (_) => _PurchaseForm(suppliers: suppliers, items: items)),
    );
    if (purchase == null) return;
    try {
      await service.recordPurchase(purchase);
      await load();
      if (mounted) _message('خرید ثبت شد؛ موجودی و سند مالی ایجاد شد.');
    } catch (e) {
      if (mounted) _message(e.toString(), error: true);
    }
  }

  void _message(String value, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value.replaceFirst('Exception: ', ''))));
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            children: [
              _Hero(icon: Icons.shopping_cart_rounded, title: 'خرید و تأمین',
                text: 'ثبت خرید، افزایش موجودی و ایجاد بدهی تأمین‌کننده.',
                action: 'خرید جدید', onTap: addPurchase),
              const SizedBox(height: 18),
              _Title('آخرین خریدها', purchases.length),
              const SizedBox(height: 10),
              if (purchases.isEmpty) const ZohalCard(child: Text('هنوز خریدی ثبت نشده است.')),
              ...purchases.take(20).map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZohalCard(child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
                  title: Text(p.supplierName, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(p.lines.length.toString() + ' قلم'),
                  trailing: Text(PersianNumberFormatter.money(p.totalAmount)),
                )),
              )),
            ],
          ),
  );
}

class _PurchaseForm extends StatefulWidget {
  const _PurchaseForm({required this.suppliers, required this.items});
  final List<Supplier> suppliers;
  final List<InventoryItem> items;
  @override State<_PurchaseForm> createState() => _PurchaseFormState();
}

class _PurchaseFormState extends State<_PurchaseForm> {
  late String supplierId;
  final rows = <_PurchaseRow>[];

  @override
  void initState() { super.initState(); supplierId = widget.suppliers.first.id; _add(); }
  @override
  void dispose() { for (final x in rows) { x.q.dispose(); x.c.dispose(); } super.dispose(); }

  void _add() {
    final used = rows.map((x) => x.itemId).toSet();
    final available = widget.items.where((x) => !used.contains(x.id));
    if (available.isEmpty) return;
    final item = available.first;
    setState(() => rows.add(_PurchaseRow(itemId: item.id, q: TextEditingController(text: '1'), c: TextEditingController()));
  }

  InventoryItem item(_PurchaseRow row) => widget.items.firstWhere((x) => x.id == row.itemId);

  int get total => rows.fold(0, (sum, row) =>
      sum + ((double.tryParse(row.q.text) ?? 0) * (int.tryParse(row.c.text.replaceAll(',', '')) ?? 0)).round());

  void save() {
    final supplier = widget.suppliers.firstWhere((x) => x.id == supplierId);
    final lines = <PurchaseLine>[];
    for (final row in rows) {
      final q = double.tryParse(row.q.text);
      final c = int.tryParse(row.c.text.replaceAll(',', ''));
      if (q == null || q <= 0 || c == null || c <= 0) return;
      final x = item(row);
      lines.add(PurchaseLine(itemId: x.id, itemName: x.name, itemType: x.type.key, quantity: q, unit: x.unit, unitCost: c));
    }
    if (lines.isEmpty) return;
    Navigator.pop(context, Purchase(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      supplierId: supplier.id, supplierName: supplier.name, createdAt: DateTime.now(),
      lines: lines, totalAmount: total,
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('خرید جدید')),
    floatingActionButton: FloatingActionButton.extended(onPressed: save, icon: const Icon(Icons.check), label: const Text('ثبت خرید')),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        DropdownButtonFormField<String>(
          initialValue: supplierId,
          decoration: const InputDecoration(labelText: 'تأمین‌کننده'),
          items: widget.suppliers.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
          onChanged: (v) { if (v != null) setState(() => supplierId = v); },
        ),
        const SizedBox(height: 18),
        Row(children: [
          const Expanded(child: Text('اقلام خرید', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))),
          OutlinedButton.icon(onPressed: rows.length < widget.items.length ? _add : null, icon: const Icon(Icons.add), label: const Text('قلم')),
        ]),
        ...List.generate(rows.length, (index) {
          final row = rows[index];
          final x = item(row);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ZohalCard(child: Column(children: [
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  initialValue: row.itemId, isExpanded: true,
                  decoration: const InputDecoration(labelText: 'قلم انبار'),
                  items: widget.items.map((i) => DropdownMenuItem(value: i.id, child: Text(i.name, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) { if (v != null) setState(() => row.itemId = v); },
                )),
                if (rows.length > 1) IconButton(onPressed: () { final r = rows.removeAt(index); r.q.dispose(); r.c.dispose(); setState(() {}); }, icon: const Icon(Icons.delete_outline)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: TextField(controller: row.q, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'مقدار ' + x.unit), onChanged: (_) => setState(() {}))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: row.c, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت واحد', suffixText: 'تومان'), onChanged: (_) => setState(() {}))),
              ]),
            ])),
          );
        }),
        const Divider(height: 30),
        Row(children: [
          const Expanded(child: Text('جمع خرید', style: TextStyle(fontWeight: FontWeight.w900))),
          Text(PersianNumberFormatter.money(total), style: const TextStyle(fontWeight: FontWeight.w900)),
        ]),
      ],
    ),
  );
}

class _PurchaseRow {
  _PurchaseRow({required this.itemId, required this.q, required this.c});
  String itemId;
  final TextEditingController q;
  final TextEditingController c;
}

class _DeliveryTab extends StatefulWidget {
  const _DeliveryTab();
  @override State<_DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<_DeliveryTab> {
  List<SalesOrder> orders = [];
  List<SalesDelivery> deliveries = [];
  bool loading = true;

  SalesDeliveryService get service => SalesDeliveryService(
    inventoryStore: InventoryStore.instance, orderStore: SalesOrderStore.instance,
    deliveryStore: SalesDeliveryStore.instance,
    financialService: SalesFinancialService(store: FinancialStore.instance),
  );

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() => loading = true);
    final a = await SalesOrderStore.instance.getAll();
    final b = await SalesDeliveryStore.instance.getAll();
    if (!mounted) return;
    setState(() { orders = a; deliveries = b; loading = false; });
  }

  Future<void> prepare(SalesOrder o) async {
    try { await service.markReadyForDelivery(o); await load(); }
    catch (e) { if (mounted) _message(e.toString()); }
  }

  Future<void> deliver(SalesOrder o) async {
    try {
      await service.deliver(
        order: o,
        deliveryId: DateTime.now().microsecondsSinceEpoch.toString(),
        quantities: {for (final x in o.lines) x.productVariantId: x.quantity},
      );
      await load();
      if (mounted) _message('تحویل ثبت شد و حساب مشتری به‌روزرسانی شد.');
    } catch (e) { if (mounted) _message(e.toString()); }
  }

  void _message(String x) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x.replaceFirst('Exception: ', ''))));

  @override
  Widget build(BuildContext context) {
    final ready = orders.where((o) => {
      SalesOrderStatus.productionCompleted, SalesOrderStatus.readyForDelivery, SalesOrderStatus.partiallyDelivered,
    }.contains(o.status)).toList();
    return RefreshIndicator(
      onRefresh: load,
      child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _Hero(icon: Icons.local_shipping_rounded, title: 'تحویل و فروش',
            text: 'تولید تکمیل‌شده را آماده تحویل کن و فروش را به مالی وصل نگه دار.',
            action: ready.isEmpty ? 'بدون مورد آماده' : 'آماده‌سازی اولین مورد',
            onTap: ready.isEmpty ? null : () => prepare(ready.first)),
          const SizedBox(height: 18),
          _Title('سفارش‌های آماده عملیات', ready.length),
          const SizedBox(height: 10),
          if (ready.isEmpty) const ZohalCard(child: Text('سفارشی برای تحویل آماده نیست.')),
          ...ready.map((o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ZohalCard(child: Row(children: [
              const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(o.customerName, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(o.status.title),
                Text(PersianNumberFormatter.money(o.totalAmount)),
              ])),
              if (o.status == SalesOrderStatus.productionCompleted) IconButton(onPressed: () => prepare(o), icon: const Icon(Icons.playlist_add_check)),
              if (o.status == SalesOrderStatus.readyForDelivery || o.status == SalesOrderStatus.partiallyDelivered)
                FilledButton(onPressed: () => deliver(o), child: const Text('تحویل')),
            ])),
          )),
          const SizedBox(height: 10),
          _Title('تحویل‌های ثبت‌شده', deliveries.length),
          const SizedBox(height: 10),
          ...deliveries.take(10).map((d) => ZohalCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.receipt_long_outlined),
              title: Text('تحویل ' + d.id), subtitle: Text('سفارش ' + d.orderId),
              trailing: Text(PersianNumberFormatter.money(d.totalAmount))),
          )),
        ],
      ),
    );
  }
}

class _ReturnsTab extends StatefulWidget {
  const _ReturnsTab();
  @override State<_ReturnsTab> createState() => _ReturnsTabState();
}

class _ReturnsTabState extends State<_ReturnsTab> {
  int mode = 0;
  List<SalesDelivery> deliveries = [];
  List<Purchase> purchases = [];
  List<SalesReturn> salesReturns = [];
  List<PurchaseReturn> purchaseReturns = [];
  bool loading = true;

  SalesReturnService get salesService => SalesReturnService(
    inventoryStore: InventoryStore.instance, deliveryStore: SalesDeliveryStore.instance,
    returnStore: SalesReturnStore.instance,
    financialService: SalesFinancialService(store: FinancialStore.instance),
  );
  PurchaseService get purchaseService => PurchaseService(
    inventoryStore: InventoryStore.instance, purchaseStore: PurchaseStore.instance,
    financialStore: FinancialStore.instance, purchaseReturnStore: PurchaseReturnStore.instance,
  );

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() => loading = true);
    final d = await SalesDeliveryStore.instance.getAll();
    final p = await PurchaseStore.instance.getAll();
    final sr = await SalesReturnStore.instance.getAll();
    final pr = await PurchaseReturnStore.instance.getAll();
    if (!mounted) return;
    setState(() { deliveries = d; purchases = p; salesReturns = sr; purchaseReturns = pr; loading = false; });
  }

  Future<double?> quantity(double max) async {
    final c = TextEditingController(text: '1');
    final value = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('مقدار برگشت'),
        content: TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'حداکثر ' + max.toString())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
          FilledButton(onPressed: () {
            final v = double.tryParse(c.text);
            if (v != null && v > 0 && v <= max) Navigator.pop(context, v);
          }, child: const Text('ثبت')),
        ],
      ),
    );
    c.dispose();
    return value;
  }

  Future<void> salesReturn(SalesDelivery d) async {
    if (d.lines.isEmpty) return;
    final q = await quantity(d.lines.first.quantity.toDouble());
    if (q == null) return;
    try {
      final customer = await CustomerStore.instance.getById(d.customerId);
      await salesService.returnItems(
        delivery: d, returnId: DateTime.now().microsecondsSinceEpoch.toString(),
        customerName: customer?.name ?? 'مشتری',
        quantities: {d.lines.first.productVariantId: q.toInt()},
      );
      await load(); if (mounted) _message('برگشت فروش ثبت شد.');
    } catch (e) { if (mounted) _message(e.toString()); }
  }

  Future<void> purchaseReturn(Purchase p) async {
    if (p.lines.isEmpty) return;
    final q = await quantity(p.lines.first.quantity);
    if (q == null) return;
    try {
      await purchaseService.returnPurchase(
        purchase: p, returnId: DateTime.now().microsecondsSinceEpoch.toString(),
        quantities: {p.lines.first.itemId: q},
      );
      await load(); if (mounted) _message('برگشت خرید ثبت شد.');
    } catch (e) { if (mounted) _message(e.toString()); }
  }

  void _message(String x) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x.replaceFirst('Exception: ', ''))));

  @override
  Widget build(BuildContext context) {
    final sales = mode == 0;
    return RefreshIndicator(
      onRefresh: load,
      child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        children: [
          _Hero(icon: Icons.assignment_return_rounded, title: 'برگشت‌ها',
            text: 'برگشت فروش و خرید با اصلاح موجودی و حساب مالی.',
            action: sales ? 'برگشت فروش' : 'برگشت خرید',
            onTap: sales ? (deliveries.isEmpty ? null : () => salesReturn(deliveries.first)) : (purchases.isEmpty ? null : () => purchaseReturn(purchases.first))),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            segments: const [ButtonSegment(value: 0, label: Text('فروش')), ButtonSegment(value: 1, label: Text('خرید'))],
            selected: {mode}, onSelectionChanged: (v) => setState(() => mode = v.first),
          ),
          const SizedBox(height: 14),
          if (sales) ...deliveries.take(15).map((d) => ZohalCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(contentPadding: EdgeInsets.zero, title: Text('تحویل ' + d.id),
              subtitle: Text('سفارش ' + d.orderId), trailing: IconButton(onPressed: () => salesReturn(d), icon: const Icon(Icons.assignment_return_outlined))),
          )) else ...purchases.take(15).map((p) => ZohalCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(contentPadding: EdgeInsets.zero, title: Text(p.supplierName),
              subtitle: Text(p.lines.length.toString() + ' قلم'), trailing: IconButton(onPressed: () => purchaseReturn(p), icon: const Icon(Icons.assignment_return_outlined))),
          )),
          const SizedBox(height: 12),
          _Title('سوابق برگشت', sales ? salesReturns.length : purchaseReturns.length),
        ],
      ),
    );
  }
}

class _FinanceTab extends StatefulWidget {
  const _FinanceTab();
  @override State<_FinanceTab> createState() => _FinanceTabState();
}

class _FinanceTabState extends State<_FinanceTab> {
  bool loading = true;
  List<dynamic> transactions = [];
  int cash = 0, customers = 0, suppliers = 0;

  @override void initState() { super.initState(); load(); }
  Future<void> load() async {
    setState(() => loading = true);
    final store = FinancialStore.instance;
    final tx = await store.getTransactions();
    final accounts = await store.getAccounts();
    var c = 0, cu = 0, su = 0;
    for (final a in accounts) {
      final b = await store.getBalance(a.id);
      if (a.id == 'cash') c += b;
      if (a.type.name == 'customer') cu += b;
      if (a.type.name == 'supplier') su += b;
    }
    if (!mounted) return;
    setState(() { transactions = tx; cash = c; customers = cu; suppliers = su; loading = false; });
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      children: [
        _Hero(icon: Icons.account_balance_wallet_rounded, title: 'مرکز مالی',
          text: 'مانده حساب‌ها و اسناد مالی ایجادشده توسط عملیات.',
          action: 'به‌روزرسانی', onTap: load),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _Metric('صندوق', cash)), const SizedBox(width: 8),
          Expanded(child: _Metric('مشتریان', customers)), const SizedBox(width: 8),
          Expanded(child: _Metric('تأمین‌کنندگان', suppliers)),
        ]),
        const SizedBox(height: 18),
        _Title('اسناد اخیر', transactions.length),
        const SizedBox(height: 10),
        if (transactions.isEmpty) const ZohalCard(child: Text('هنوز سند مالی ثبت نشده است.')),
        ...transactions.take(20).map((tx) => ZohalCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.receipt_long_outlined)),
            title: Text(tx.type.toString()), subtitle: Text(tx.note ?? tx.referenceId),
            trailing: Text(PersianNumberFormatter.money(tx.entries.fold<int>(0, (s, e) => s + e.amount)))),
        )),
      ],
    ),
  );
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.text, required this.action, required this.onTap});
  final IconData icon; final String title; final String text; final String action; final VoidCallback? onTap;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.yellow.withValues(alpha: .16), borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: AppColors.yellow, size: 28)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(text, style: TextStyle(color: Colors.white70, height: 1.4)),
        const SizedBox(height: 14),
        FilledButton(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.black), child: Text(action)),
      ])),
    ]),
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text, this.count);
  final String text; final int count;
  @override Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))),
    CircleAvatar(radius: 13, backgroundColor: AppColors.yellow.withValues(alpha: .25), child: Text(count.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900))),
  ]);
}

class _Metric extends StatelessWidget {
  const _Metric(this.title, this.value);
  final String title; final int value;
  @override Widget build(BuildContext context) => ZohalCard(
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
    child: Column(children: [
      Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 6),
      Text(PersianNumberFormatter.money(value), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
    ]),
  );
}
