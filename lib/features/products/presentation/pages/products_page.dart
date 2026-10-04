import 'package:flutter/material.dart';

import '../../../../core/sales/product_variant.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/utils/persian_number_formatter.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _store = ProductVariantStore.instance;
  List<ProductVariant> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    await _store.ensureSeeded();
    final products = await _store.getAll();
    if (!mounted) return;
    setState(() {
      _products = products.where((item) => item.isActive).toList();
      _loading = false;
    });
  }

  Future<void> _editPrice(ProductVariant product) async {
    final value = await Navigator.of(context).push<int>(
      MaterialPageRoute<int>(
        builder: (_) => _ProductPriceEditPage(product: product),
      ),
    );
    if (value == null) return;

    await _store.upsert(product.copyWith(currentSellingPrice: value));
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('محصولات'),
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              tooltip: 'به‌روزرسانی',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _products.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return Card(
                      child: InkWell(
                        onTap: () => _editPrice(product),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                child: Text(
                                  PersianNumberFormatter.digits(index + 1),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      product.displayName,
                                      textAlign: TextAlign.right,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'قیمت فروش: ' +
                                          PersianNumberFormatter.money(
                                            product.currentSellingPrice,
                                          ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _editPrice(product),
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'ویرایش قیمت',
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _ProductPriceEditPage extends StatefulWidget {
  const _ProductPriceEditPage({required this.product});

  final ProductVariant product;

  @override
  State<_ProductPriceEditPage> createState() => _ProductPriceEditPageState();
}

class _ProductPriceEditPageState extends State<_ProductPriceEditPage> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.product.currentSellingPrice.toString(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final value = int.parse(_controller.text.replaceAll(',', '').trim());
    if (!mounted) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ویرایش قیمت محصول')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.product.displayName,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: _controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.right,
                        decoration: const InputDecoration(
                          labelText: 'قیمت فروش',
                          suffixText: 'تومان',
                        ),
                        validator: (text) {
                          final amount = int.tryParse(
                            (text ?? '').replaceAll(',', '').trim(),
                          );
                          return amount == null || amount < 0
                              ? 'مبلغ معتبر وارد کنید'
                              : null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('ذخیره'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
