import 'package:flutter/material.dart';

import '../../../../core/storage/local_store.dart';

enum MaterialType { rawMaterial, consumable, packaging, supplies }

extension MaterialTypeX on MaterialType {
  String get title {
    switch (this) {
      case MaterialType.rawMaterial:
        return 'مواد اولیه';
      case MaterialType.consumable:
        return 'مواد مصرفی';
      case MaterialType.packaging:
        return 'بسته‌بندی';
      case MaterialType.supplies:
        return 'ملزومات';
    }
  }

  IconData get icon {
    switch (this) {
      case MaterialType.rawMaterial:
        return Icons.grain;
      case MaterialType.consumable:
        return Icons.science_outlined;
      case MaterialType.packaging:
        return Icons.inventory_2_outlined;
      case MaterialType.supplies:
        return Icons.build_outlined;
    }
  }
}

class MaterialItem {
  MaterialItem({
    required this.name,
    required this.type,
    required this.unit,
    this.purchaseUnit,
    this.stock = 0,
    this.minimumStock = 0,
    this.lastPurchasePrice = 0,
    this.supplier,
    this.expiryTracking = false,
  });

  String name;
  MaterialType type;
  String unit;
  String? purchaseUnit;
  double stock;
  double minimumStock;
  int lastPurchasePrice;
  String? supplier;
  bool expiryTracking;
}

class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  static const _storageKey = 'materials';
  MaterialType? _filter;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final saved = await LocalStore.instance.readList(_storageKey);

    if (!mounted || saved.isEmpty) return;

    setState(() {
      _items
        ..clear()
        ..addAll(saved.map(_fromMap));
    });
  }

  Future<void> _saveItems() async {
    await LocalStore.instance.writeList(
      _storageKey,
      _items.map(_toMap).toList(),
    );
  }

  Map<String, dynamic> _toMap(MaterialItem item) {
    return {
      'name': item.name,
      'type': item.type.name,
      'unit': item.unit,
      'purchaseUnit': item.purchaseUnit,
      'stock': item.stock,
      'minimumStock': item.minimumStock,
      'lastPurchasePrice': item.lastPurchasePrice,
      'supplier': item.supplier,
      'expiryTracking': item.expiryTracking,
    };
  }

  MaterialItem _fromMap(Map<String, dynamic> map) {
    final typeName = map['type'] as String? ?? 'rawMaterial';

    final type = MaterialType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => MaterialType.rawMaterial,
    );

    return MaterialItem(
      name: map['name'] as String? ?? '',
      type: type,
      unit: map['unit'] as String? ?? 'عدد',
      purchaseUnit: map['purchaseUnit'] as String?,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      minimumStock: (map['minimumStock'] as num?)?.toDouble() ?? 0,
      lastPurchasePrice: (map['lastPurchasePrice'] as num?)?.toInt() ?? 0,
      supplier: map['supplier'] as String?,
      expiryTracking: map['expiryTracking'] as bool? ?? false,
    );
  }

  final List<MaterialItem> _items = [
    MaterialItem(
      name: 'خرما کبکاب برازجان',
      type: MaterialType.rawMaterial,
      unit: 'کیلوگرم',
      stock: 35,
      minimumStock: 10,
      lastPurchasePrice: 185000,
      supplier: 'تأمین‌کننده نمونه',
      expiryTracking: true,
    ),
    MaterialItem(
      name: 'گردو',
      type: MaterialType.rawMaterial,
      unit: 'کیلوگرم',
      stock: 8,
      minimumStock: 5,
      lastPurchasePrice: 680000,
      expiryTracking: true,
    ),
    MaterialItem(
      name: 'جعبه محصول',
      type: MaterialType.packaging,
      unit: 'عدد',
      stock: 120,
      minimumStock: 30,
      lastPurchasePrice: 12500,
    ),
    MaterialItem(
      name: 'لیبل',
      type: MaterialType.packaging,
      unit: 'عدد',
      stock: 240,
      minimumStock: 50,
      lastPurchasePrice: 1800,
    ),
  ];

  List<MaterialItem> get _filteredItems {
    if (_filter == null) return _items;
    return _items.where((item) => item.type == _filter).toList();
  }

  Future<void> _addItem() async {
    final result = await showDialog<MaterialItem>(
      context: context,
      builder: (_) => const _MaterialDialog(),
    );

    if (result != null) {
      setState(() {
        _items.add(result);
      });
      await _saveItems();
    }
  }

  Future<void> _editItem(MaterialItem item) async {
    final result = await showDialog<MaterialItem>(
      context: context,
      builder: (_) => _MaterialDialog(item: item),
    );

    if (result != null) {
      setState(() {
        final index = _items.indexOf(item);
        _items[index] = result;
      });
      await _saveItems();
    }
  }

  void _deleteItem(MaterialItem item) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف قلم'),
        content: Text('«${item.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () async {
              setState(() {
                _items.remove(item);
              });

              await _saveItems();

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _showQuickAdd() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'افزودن سریع',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'فقط نام قلم را وارد کن؛ دسته و واحد پیشنهادی را ZOHAL تعیین می‌کند.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openSmartDialog();
                },
                icon: const Icon(Icons.auto_awesome),
                label: const Text('افزودن هوشمند'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _addItem();
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text('ثبت دستی'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSmartDialog() async {
    var name = '';

    final result = await showDialog<MaterialItem>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('افزودن هوشمند'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'نام قلم',
              hintText: 'مثلاً خرما کبکاب، جعبه، لیبل...',
              prefixIcon: Icon(Icons.auto_awesome),
            ),
            onChanged: (value) {
              name = value;
            },
            onSubmitted: (_) {
              final value = name.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop(_suggestItem(value));
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('انصراف'),
            ),
            FilledButton(
              onPressed: () {
                final value = name.trim();

                if (value.isEmpty) return;

                Navigator.of(dialogContext).pop(_suggestItem(value));
              },
              child: const Text('ادامه'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) return;

    final confirmed = await showDialog<MaterialItem>(
      context: context,
      builder: (dialogContext) {
        return _SuggestionDialog(item: result);
      },
    );

    if (!mounted || confirmed == null) return;

    setState(() {
      _items.add(confirmed);
    });

    await _saveItems();
  }

  MaterialItem _suggestItem(String name) {
    final normalized = name.toLowerCase();

    if (_containsAny(normalized, [
      'جعبه',
      'لیبل',
      'سلفون',
      'کارتن',
      'نایلون',
      'پاکت',
      'بسته',
    ])) {
      return MaterialItem(
        name: name,
        type: MaterialType.packaging,
        unit: 'عدد',
      );
    }

    if (_containsAny(normalized, [
      'دستکش',
      'شوینده',
      'دستمال',
      'کاغذ',
      'روغن',
    ])) {
      return MaterialItem(
        name: name,
        type: MaterialType.consumable,
        unit: 'عدد',
      );
    }

    if (_containsAny(normalized, [
      'خرما',
      'گردو',
      'بادام',
      'کنجد',
      'فندق',
      'پسته',
      'بادام زمینی',
      'کشمش',
      'شیره',
    ])) {
      return MaterialItem(
        name: name,
        type: MaterialType.rawMaterial,
        unit: 'کیلوگرم',
        expiryTracking: true,
      );
    }

    return MaterialItem(name: name, type: MaterialType.supplies, unit: 'عدد');
  }

  bool _containsAny(String value, List<String> words) {
    return words.any(value.contains);
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مواد و اقلام'),
        actions: [
          IconButton(
            onPressed: _showQuickAdd,
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'افزودن هوشمند',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQuickAdd,
        icon: const Icon(Icons.add),
        label: const Text('افزودن'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 58,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                ChoiceChip(
                  label: const Text('همه'),
                  selected: _filter == null,
                  onSelected: (_) {
                    setState(() => _filter = null);
                  },
                ),
                const SizedBox(width: 8),
                ...MaterialType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ChoiceChip(
                      avatar: Icon(type.icon, size: 18),
                      label: Text(type.title),
                      selected: _filter == type,
                      onSelected: (_) {
                        setState(() => _filter = type);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Center(child: Text('قلمی در این دسته ثبت نشده است'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final lowStock =
                          item.minimumStock > 0 &&
                          item.stock <= item.minimumStock;

                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(child: Icon(item.type.icon)),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${item.type.title} • ${item.unit}\n'
                            'موجودی: ${item.stock} ${item.unit}'
                            '${lowStock ? ' • نیاز به خرید' : ''}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editItem(item);
                              } else if (value == 'delete') {
                                _deleteItem(item);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Text('ویرایش'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('حذف'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MaterialDialog extends StatefulWidget {
  const _MaterialDialog({this.item});

  final MaterialItem? item;

  @override
  State<_MaterialDialog> createState() => _MaterialDialogState();
}

class _MaterialDialogState extends State<_MaterialDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _stock;
  late final TextEditingController _minimum;
  late final TextEditingController _price;
  late final TextEditingController _supplier;

  late MaterialType _type;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _name = TextEditingController(text: item?.name ?? '');
    _unit = TextEditingController(text: item?.unit ?? 'کیلوگرم');
    _stock = TextEditingController(text: item?.stock.toString() ?? '0');
    _minimum = TextEditingController(
      text: item?.minimumStock.toString() ?? '0',
    );
    _price = TextEditingController(
      text: item?.lastPurchasePrice.toString() ?? '',
    );
    _supplier = TextEditingController(text: item?.supplier ?? '');

    _type = item?.type ?? MaterialType.rawMaterial;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _stock.dispose();
    _minimum.dispose();
    _price.dispose();
    _supplier.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.pop(
      context,
      MaterialItem(
        name: _name.text.trim(),
        type: _type,
        unit: _unit.text.trim(),
        stock: double.tryParse(_stock.text) ?? 0,
        minimumStock: double.tryParse(_minimum.text) ?? 0,
        lastPurchasePrice: int.tryParse(_price.text) ?? 0,
        supplier: _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'قلم جدید' : 'ویرایش قلم'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'نام را وارد کنید'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<MaterialType>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'دسته',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: MaterialType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.title),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(
                  labelText: 'واحد',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'موجودی',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimum,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'حداقل موجودی',
                  prefixIcon: Icon(Icons.warning_amber_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'آخرین قیمت خرید',
                  suffixText: 'تومان',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _supplier,
                decoration: const InputDecoration(
                  labelText: 'تأمین‌کننده',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('انصراف'),
        ),
        FilledButton(onPressed: _save, child: const Text('ذخیره')),
      ],
    );
  }
}

class _SuggestionDialog extends StatelessWidget {
  const _SuggestionDialog({required this.item});

  final MaterialItem item;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('پیشنهاد ZOHAL'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'دسته', value: item.type.title),
          _InfoRow(label: 'واحد پیشنهادی', value: item.unit),
          _InfoRow(
            label: 'پیگیری تاریخ انقضا',
            value: item.expiryTracking ? 'بله' : 'خیر',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('اصلاح'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, item),
          child: const Text('تأیید'),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label: '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
