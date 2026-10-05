import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/design/app_spacing.dart';
import '../../../../core/inventory/inventory_item.dart';
import '../../../../core/inventory/inventory_item_store.dart';
import '../../../../core/inventory/inventory_movement.dart';
import '../../../../core/inventory/inventory_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import '../../../operations/presentation/pages/operations_page.dart';

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
  List<InventoryItem> _items = [];
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

    final items = await _itemStore.getItems();
    final stocks = await _store.getAllStocks();
    final movements = await _store.getMovements();
    final reservedStocks = <String, double>{};
    for (final itemId in stocks.keys) {
      final reserved = await _store.getReservedStock(itemId);
      if (reserved > 0) reservedStocks[itemId] = reserved;
    }

    if (!mounted) return;

    setState(() {
      _items = items;
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
      builder: (_) => _AddMovementDialog(items: _items),
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
                  const SizedBox(height: AppSpacing.md),
                  ZohalCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(child: Icon(Icons.shopping_cart_outlined)),
                      title: const Text('خرید مواد و اقلام', style: TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: const Text('ثبت خرید، افزایش موجودی و حساب تأمین‌کننده'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const OperationsPage()));
                        await _loadInventory();
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _buildSectionTitle('لیست اقلام'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildItemCatalog(),
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

  Widget _buildItemCatalog() {
    if (_items.isEmpty) {
      return const ZohalCard(child: Text('هنوز قلمی در انبار تعریف نشده است.'));
    }
    return Column(
      children: _items.map((item) {
        final stock = _stocks[item.id] ?? 0;
        final reserved = _reservedStocks[item.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ZohalCard(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.inventory_2_outlined),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 3),
                      Text(
                        '${item.category ?? 'بدون دسته'} • ${item.type.title} • ${item.unit}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'موجودی: ${_formatNumber(stock)} ${item.unit} • رزرو: ${_formatNumber(reserved)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
    final stockItems = _items.where((item) => _stocks.containsKey(item.id)).toList();
    return Column(
      children: stockItems.map((item) {
        final value = _stocks[item.id] ?? 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ZohalCard(
            child: Row(
              children: [
                const Icon(Icons.inventory_2_outlined),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                Text(
                  '${_formatNumber(value)} ${item.unit}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
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
  const _AddMovementDialog({required this.items});
  final List<InventoryItem> items;

  @override
  State<_AddMovementDialog> createState() => _AddMovementDialogState();
}

class _AddMovementDialogState extends State<_AddMovementDialog> {
  final _formKey = GlobalKey<FormState>();
  late String itemId;
  late final TextEditingController quantity;
  late final TextEditingController note;
  InventoryMovementType movementType = InventoryMovementType.purchase;
  String? selectedUnit;

  @override
  void initState() {
    super.initState();
    itemId = widget.items.first.id;
    selectedUnit = widget.items.first.unit;
    quantity = TextEditingController(text: '1');
    note = TextEditingController();
  }

  InventoryItem get item => widget.items.firstWhere((x) => x.id == itemId);

  List<InventoryUnitConversion> get conversions {
    final values = <InventoryUnitConversion>[
      InventoryUnitConversion(unit: item.unit, toBaseFactor: 1),
      ...item.unitConversions,
    ];
    final seen = <String>{};
    return values.where((x) => seen.add(x.unit)).toList();
  }

  @override
  void dispose() {
    quantity.dispose();
    note.dispose();
    super.dispose();
  }

  void submit() {
    if (!_formKey.currentState!.validate()) return;
    final q = double.parse(quantity.text.trim().replaceAll(',', '.'));
    final conversion = conversions.firstWhere((x) => x.unit == selectedUnit);
    final baseQuantity = q * conversion.toBaseFactor;
    final noteParts = <String>[
      if (selectedUnit != item.unit) 'مقدار ورودی: $q $selectedUnit',
      if (note.text.trim().isNotEmpty) note.text.trim(),
    ];
    Navigator.of(context).pop(
      InventoryMovement(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        itemId: item.id,
        itemName: item.name,
        itemType: item.type.key,
        quantity: baseQuantity,
        unit: item.unit,
        movementType: movementType,
        timestamp: DateTime.now(),
        note: noteParts.isEmpty ? null : noteParts.join(' • '),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ثبت گردش موجودی'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: itemId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'نام قلم'),
              items: widget.items.map((x) => DropdownMenuItem(value: x.id, child: Text(x.name))).toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  itemId = value;
                  selectedUnit = item.unit;
                });
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            DropdownButtonFormField<InventoryMovementType>(
              initialValue: movementType,
              decoration: const InputDecoration(labelText: 'نوع گردش'),
              items: InventoryMovementType.values.map((x) => DropdownMenuItem(value: x, child: Text(x.title))).toList(),
              onChanged: (value) => setState(() => movementType = value ?? movementType),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quantity,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'مقدار'),
                    validator: (value) {
                      final n = double.tryParse(value?.replaceAll(',', '.') ?? '');
                      return n == null || n <= 0 ? 'مقدار معتبر وارد کنید' : null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedUnit,
                    decoration: const InputDecoration(labelText: 'واحد'),
                    items: conversions.map((x) => DropdownMenuItem(value: x.unit, child: Text(x.unit))).toList(),
                    onChanged: (value) => setState(() => selectedUnit = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'یادداشت')),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton(onPressed: submit, child: const Text('ثبت')),
    ],
  );
}

class _InventoryItemDialog extends StatefulWidget {
  const _InventoryItemDialog();

  @override
  State<_InventoryItemDialog> createState() => _InventoryItemDialogState();
}

class _InventoryItemDialogState extends State<_InventoryItemDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final minimum = TextEditingController(text: '0');
  String category = 'مواد اولیه';
  String unit = 'g';

  static const categories = [
    'مواد اولیه',
    'خرما',
    'آجیل',
    'اقلام مصرفی',
    'بسته‌بندی',
    'محصول نیمه‌آماده',
    'محصول',
  ];
  static const units = ['g', 'kg', 'piece', 'ml', 'liter', 'box', 'package'];

  InventoryItemType get type {
    switch (category) {
      case 'بسته‌بندی': return InventoryItemType.packaging;
      case 'اقلام مصرفی': return InventoryItemType.consumable;
      case 'محصول نیمه‌آماده': return InventoryItemType.semiFinished;
      case 'محصول': return InventoryItemType.product;
      default: return InventoryItemType.rawMaterial;
    }
  }

  @override
  void dispose() {
    name.dispose();
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
        category: category,
        unit: unit,
        minimumStock: double.parse(minimum.text.replaceAll(',', '.')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('قلم جدید انبار'),
    content: Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'نام قلم'),
              validator: (v) => v == null || v.trim().isEmpty ? 'نام قلم را وارد کنید' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'دسته'),
              items: categories.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => category = v ?? category),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: unit,
              decoration: const InputDecoration(labelText: 'واحد اندازه‌گیری'),
              items: units.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setState(() => unit = v ?? unit),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: minimum,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'حداقل موجودی'),
              validator: (v) => double.tryParse(v?.replaceAll(',', '.') ?? '') == null ? 'عدد معتبر وارد کنید' : null,
            ),
            const SizedBox(height: 10),
            const Text('ارزش غذایی از همین فرم اجباری نیست و در نسخه بعدی قابل تکمیل خواهد بود.'),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton(onPressed: save, child: const Text('ذخیره')),
    ],
  );
}
