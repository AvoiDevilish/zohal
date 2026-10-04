import 'package:flutter/material.dart';

import 'package:zohal_android_test/core/costing/production_cost_store.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';
import 'package:zohal_android_test/core/inventory/inventory_store.dart';
import 'package:zohal_android_test/core/workshop/production_order_analyzer.dart';
import 'package:zohal_android_test/core/sales/sales_order.dart';
import 'package:zohal_android_test/core/sales/sales_order_store.dart';

class WorkshopDashboardScreen extends StatefulWidget {
  final ProductionBatchStore batchStore;
  final ProductionCostStore costStore;

  WorkshopDashboardScreen({
    super.key,
    ProductionBatchStore? batchStore,
    ProductionCostStore? costStore,
  })  : batchStore = batchStore ?? ProductionBatchStore.instance,
        costStore = costStore ?? ProductionCostStore.instance;

  @override
  State<WorkshopDashboardScreen> createState() => _WorkshopDashboardScreenState();
}

class _WorkshopDashboardScreenState extends State<WorkshopDashboardScreen> {
  final SalesOrderStore _orderStore = SalesOrderStore.instance;

  @override
  void initState() {
    super.initState();
  }

  Future<_WorkshopDashboardData> _load() async {
    final batches = await widget.batchStore.getAll();
    final orders = await _orderStore.getAll();
    final costs = await widget.costStore.getAll();
    final now = DateTime.now();

    final active = batches.where((b) =>
        b.status == ProductionBatchStatus.ready ||
        b.status == ProductionBatchStatus.inProduction).length;

    final completedToday = batches.where((b) =>
        b.status == ProductionBatchStatus.completed &&
        b.createdAt.year == now.year &&
        b.createdAt.month == now.month &&
        b.createdAt.day == now.day).length;

    final totalCost = costs.fold<double>(0, (sum, cost) => sum + cost.totalCost);
    final output = costs.fold<int>(0, (sum, cost) => sum + cost.outputQuantity);
    final unitCost = output == 0 ? 0.0 : totalCost / output;

    final recent = [...batches]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _WorkshopDashboardData(
      active: active,
      completedToday: completedToday,
      totalCost: totalCost,
      unitCost: unitCost,
      recent: recent.take(5).toList(),
      incomingOrders: orders.where((order) => order.status == SalesOrderStatus.workshopPending || order.status == SalesOrderStatus.workshopAnalyzing).toList(),
    );
  }

  Future<void> _analyzeOrder(SalesOrder order) async {
    try {
      final analysis = await ProductionOrderAnalyzer(
        inventoryStore: InventoryStore.instance,
      ).analyze(order);

      await _orderStore.update(SalesOrder(
        id: order.id,
        customerId: order.customerId,
        customerName: order.customerName,
        orderDate: order.orderDate,
        lines: order.lines,
        totalAmount: order.totalAmount,
        status: analysis.canProduce
            ? SalesOrderStatus.readyForProduction
            : SalesOrderStatus.shortage,
      ));

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            analysis.canProduce
                ? 'تحلیل کارگاه: آماده تولید'
                : 'تحلیل کارگاه: کمبود موجودی',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...analysis.stockCheck.items.map(
                  (item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(item.materialName),
                    subtitle: Text(
                      'نیاز: ${item.requiredQuantity.toStringAsFixed(2)} ${item.unit} '
                      '• موجود: ${item.availableQuantity.toStringAsFixed(2)} ${item.unit}',
                    ),
                    trailing: item.isSufficient
                        ? const Icon(Icons.check_circle_outline)
                        : Text(
                            'کمبود ${item.shortageQuantity.toStringAsFixed(2)}',
                          ),
                  ),
                ),
                if (analysis.byproducts.isNotEmpty) ...[
                  const Divider(),
                  const Text(
                    'محصولات جانبی قابل استفاده',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ...analysis.byproducts.map(
                    (item) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.itemName),
                      trailing: Text(
                        '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('تأیید'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تحلیل سفارش انجام نشد: $error')),
      );
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کارگاه تولید'),
        actions: [
          IconButton(
            key: const Key('workshop_refresh'),
            onPressed: () => setState(() {}),
            tooltip: 'به‌روزرسانی',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _orderStore,
        builder: (context, _) => FutureBuilder<_WorkshopDashboardData>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: FilledButton(
                  onPressed: () => setState(() {}),
                  child: const Text('تلاش دوباره'),
                ),
              );
            }

            final data = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _IncomingOrders(
                  orders: data.incomingOrders,
                  onAnalyze: (order) async {
                    await _analyzeOrder(order);
                  },
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'وضعیت تولید',
                  children: [
                    _Metric('تولید فعال', data.active.toString(), Icons.precision_manufacturing_outlined),
                    _Metric('تکمیل شده امروز', data.completedToday.toString(), Icons.task_alt),
                  ],
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'هزینه تولید',
                  children: [
                    _Metric('هزینه کل', data.totalCost.toStringAsFixed(2), Icons.account_balance_wallet_outlined),
                    _Metric('هزینه واحد', data.unitCost.toStringAsFixed(2), Icons.price_check_outlined),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'آخرین تولیدها',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (data.recent.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text('هنوز تولیدی ثبت نشده است.'),
                          )
                        else
                          ...data.recent.map(
                            (batch) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(batch.productName),
                              subtitle: Text(
                                batch.status.title + ' • ' + batch.units.toString() + ' واحد',
                              ),
                              trailing: Text(batch.unitWeightGrams.toString() + ' گرم'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WorkshopDashboardData {
  final int active;
  final int completedToday;
  final double totalCost;
  final double unitCost;
  final List<ProductionBatch> recent;
  final List<SalesOrder> incomingOrders;

  const _WorkshopDashboardData({
    required this.active,
    required this.completedToday,
    required this.totalCost,
    required this.unitCost,
    required this.recent,
    required this.incomingOrders,
  });
}

class _IncomingOrders extends StatelessWidget {
  const _IncomingOrders({required this.orders, required this.onAnalyze});
  final List<SalesOrder> orders;
  final Future<void> Function(SalesOrder order) onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('سفارش‌های ورودی کارگاه', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (orders.isEmpty)
            const Text('سفارش جدیدی در صف کارگاه نیست.')
          else
            ...orders.map((order) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('سفارش ' + order.id),
              subtitle: Text(order.customerName + ' • ' + order.lines.length.toString() + ' ردیف • ' + order.status.title),
              trailing: order.status == SalesOrderStatus.workshopPending
                  ? FilledButton(onPressed: () => onAnalyze(order), child: const Text('تحلیل'))
                  : const Chip(label: Text('در حال تحلیل')),
            )),
        ]),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _Metric(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
