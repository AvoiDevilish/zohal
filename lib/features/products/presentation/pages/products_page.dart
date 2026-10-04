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
    setState(() => _loading = true);
    await _store.ensureSeeded();
    final products = await _store.getAll();
    if (!mounted) return;
    setState(() {
      _products = products.where((item) => item.isActive).toList();
      _loading = false;
    });
  }

  Future<void> _editPrice(ProductVariant product) async {
    final controller = TextEditingController(
      text: product.currentSellingPrice.toString(),
    );
    final formKey = GlobalKey<FormState>();
    final value = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('ویرایش قیمت • ' + product.displayName),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'قیمت فروش',
              suffixText: 'تومان',
            ),
            validator: (text) {
              final amount = int.tryParse(
                (text ?? '').replaceAll(',', '').trim(),
              );
              return amount == null || amount < 0 ? 'مبلغ معتبر وارد کنید' : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  int.parse(controller.text.replaceAll(',', '').trim()),
                );
              }
            },
            child: const Text('ذخیره'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _store.upsert(
      product.copyWith(currentSellingPrice: value),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        child: Text((index + 1).toString()),
                      ),
                      title: Text(
                        product.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'قیمت فروش: ' +
                            PersianNumberFormatter.money(
                              product.currentSellingPrice,
                            ),
                      ),
                      trailing: IconButton(
                        onPressed: () => _editPrice(product),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'ویرایش قیمت',
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
