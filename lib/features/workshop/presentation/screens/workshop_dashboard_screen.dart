import 'package:flutter/material.dart';

import 'package:zohal_android_test/core/costing/production_cost_store.dart';
import 'package:zohal_android_test/core/workshop/production_batch.dart';
import 'package:zohal_android_test/core/workshop/production_batch_store.dart';

class WorkshopDashboardScreen extends StatefulWidget {
  final ProductionBatchStore batchStore;
  final ProductionCostStore costStore;

  const WorkshopDashboardScreen({
    super.key,
    this.batchStore = ProductionBatchStore.instance,
    this.costStore = ProductionCostStore.instance,
  });

  @override
  State<WorkshopDashboardScreen> createState() => _WorkshopDashboardScreenState();
}

class _WorkshopDashboardScreenState extends State<WorkshopDashboardScreen> {
  late Future<_WorkshopDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_WorkshopDashboardData> _load() async {
    final batches = await widget.batchStore.getAll();
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
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کارگاه تولید'),
        actions: [
          IconButton(
            key: const Key('workshop_refresh'),
            onPressed: _refresh,
            tooltip: 'به‌روزرسانی',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_WorkshopDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: _refresh,
                child: const Text('تلاش دوباره'),
              ),
            );
          }

          final data = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                      const Text('آخرین تولیدها',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (data.recent.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Text('هنوز تولیدی ثبت نشده است.'),
                        )
                      else
                        ...data.recent.map((batch) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(batch.productName),
                              subtitle: Text(
                                batch.status.title + ' • ' + batch.units.toString() + ' واحد',
                              ),
                              trailing: Text(batch.unitWeightGrams.toString() + ' گرم'),
                            )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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

  const _WorkshopDashboardData({
    required this.active,
    required this.completedToday,
    required this.totalCost,
    required this.unitCost,
    required this.recent,
  });
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
