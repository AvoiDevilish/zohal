import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/inventory/inventory_item.dart';
import '../../../../core/inventory/inventory_item_store.dart';
import '../../../../core/inventory/inventory_movement.dart';
import '../../../../core/inventory/inventory_store.dart';
import '../../../../core/widgets/zohal_card.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final InventoryStore _store = InventoryStore.instance;
  final InventoryItemStore _itemStore = InventoryItemStore.instance;

  Map<String, double> _stocks = {};
  Map<String, double> _reservedStocks = {};
  List<InventoryMovement> _movements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _loading = true;
    });

    await _itemStore.ensureSeeded();

    final stocks = await _store.getAllStocks();
    final movements = await _store.getMovements();
    final reservedStocks = <String, double>{};
    for (final itemId in stocks.keys) {
      final reserved = await _store.getReservedStock(itemId);
      if (reserved > 0) reservedStocks[itemId] = reserved;
    }

    if (!mounted) return;

    setState(() {
      _stocks = stocks;
      _reservedStocks = reservedStocks;
      _movements = movements;
      _loading = false;
    });
  }

  int get _reservedItemCount => _reservedStocks.keys.length;

  Future<void> _openAddItem() async {
    final item = await showDialog<InventoryItem>(
      context: context,
      builder: (_) => const _InventoryItemDialog(),
    );
    if (item == null) return;
    await _itemStore.upsert(item);
    await _loadInventory();
  }

  Future<void> _openAddMovement() async {
    final result = await showDialog<InventoryMovement>(
      context: context,
      builder: (_) => const _AddMovementDialog(),
    );

    if (!mounted || result == null) return;

    await _store.addMovement(result);
    await _loadInventory();
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  String _movementText(InventoryMovement movement) {
    final prefix = movement.movementType.increasesStock ? '+' : '-';

    return '$prefix${_formatNumber(movement.quantity)} ${movement.unit}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('انبار'),
        actions: [
          IconButton(onPressed: _openAddItem, icon: const Icon(Icons.add_box_outlined), tooltip: 'قلم جدید'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMovement,
        icon: const Icon(Icons.add),
        label: const Text('ثبت گردش'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadInventory,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  100,
                ),
                children: [
                  _buildSummary(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('موجودی فعلی'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildStockList(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('آخرین گردش‌ها'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMovementList(),
                ],
              ),
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: ZohalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.inventory_2_outlined, color: AppColors.yellow),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _stocks.length.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('قلم دارای موجودی'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ZohalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_vert, color: AppColors.yellow),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _movements.length.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('گردش ثبت‌شده'),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ZohalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.bookmark_border, color: AppColors.yellow),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  _reservedItemCount.toString(),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text('قلم رزروشده'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _buildStockList() {
    if (_stocks.isEmpty) {
      return const ZohalCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Text('هنوز هیچ گردش موجودی ثبت نشده است.'),
        ),
      );
    }

    final stockItems = _stocks.entries.toList();

    return Column(
      children: stockItems.map((entry) {
        final movement = _movements.firstWhere(
          (item) => item.itemId == entry.key,
          orElse: () => _movements.first,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ZohalCard(
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        movement.unit,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'آزاد: ' +
                            _formatNumber(
                              entry.value - (_reservedStocks[entry.key] ?? 0),
                            ) +
                            '  •  رزرو: ' +
                            _formatNumber(_reservedStocks[entry.key] ?? 0),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatNumber(entry.value),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMovementList() {
    if (_movements.isEmpty) {
      return const ZohalCard(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: Text('آخرین گردش‌ها اینجا نمایش داده می‌شوند.'),
        ),
      );
    }

    final visibleMovements = _movements.take(10);

    return Column(
      children: visibleMovements.map((movement) {
        final incoming = movement.movementType.increasesStock;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ZohalCard(
            child: Row(
              children: [
                Icon(
                  incoming
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: incoming ? AppColors.success : AppColors.danger,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movement.itemName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        movement.movementType.title,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  _movementText(movement),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: incoming ? AppColors.success : AppColors.danger,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddMovementDialog extends StatefulWidget {
  const _AddMovementDialog();

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _itemName;
  late final TextEditingController _quantity;
  late final TextEditingController _unit;
  late final TextEditingController _note;

  InventoryMovementType _movementType = InventoryMovementType.purchase;

  @override
  void initState() {
    super.initState();

    _itemName = TextEditingController();
    _quantity = TextEditingController();
    _unit = TextEditingController(text: 'کیلوگرم');
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _itemName.dispose();
    _quantity.dispose();
    _unit.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantity.text.trim().replaceAll(',', '.'));

    final name = _itemName.text.trim();

    final movement = InventoryMovement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      itemId: _makeItemId(name),
      itemName: name,
      itemType: 'manual',
      quantity: quantity,
      unit: _unit.text.trim(),
      movementType: _movementType,
      timestamp: DateTime.now(),
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );

    Navigator.of(context).pop(movement);
  }

  String _makeItemId(String name) {
    return name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('ثبت گردش موجودی'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _itemName,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام قلم',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام قلم را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<InventoryMovementType>(
                initialValue: _movementType,
                decoration: const InputDecoration(
                  labelText: 'نوع گردش',
                  prefixIcon: Icon(Icons.swap_vert),
                ),
                items: InventoryMovementType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.title));
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _movementType = value;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _quantity,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'مقدار',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  final number = double.tryParse(
                    value?.trim().replaceAll(',', '.') ?? '',
                  );

                  if (number == null || number <= 0) {
                    return 'مقدار معتبر وارد کنید';
                  }

                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'واحد',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'واحد را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'یادداشت',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _submit, child: const Text('ثبت')),
      ],
    );
  }
}


class _InventoryItemDialog extends StatefulWidget {
  const _InventoryItemDialog();

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final unit = TextEditingController(text: 'عدد');
  final minimum = TextEditingController(text: '0');
  InventoryItemType type = InventoryItemType.rawMaterial;

  @override
  void dispose() {
    name.dispose();
    unit.dispose();
    minimum.dispose();
    super.dispose();
  }

  void save() {
    if (!formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      InventoryItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        type: type,
        unit: unit.text.trim(),
        minimumStock: double.parse(minimum.text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('قلم جدید انبار'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'نام قلم'),
            validator: (v) => v == null || v.trim().isEmpty ? 'نام قلم را وارد کنید' : null,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<InventoryItemType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'دسته'),
            items: InventoryItemType.values.map((x) => DropdownMenuItem(value: x, child: Text(x.title))).toList(),
            onChanged: (v) { if (v != null) setState(() => type = v); },
          ),
          const SizedBox(height: 10),
          TextFormField(controller: unit, decoration: const InputDecoration(labelText: 'واحد')),
          const SizedBox(height: 10),
          TextFormField(
            controller: minimum,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'حداقل موجودی'),
            validator: (v) => double.tryParse(v ?? '') == null ? 'عدد معتبر وارد کنید' : null,
          ),
        ]),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton(onPressed: save, child: const Text('ذخیره')),
    ],
  );
}
