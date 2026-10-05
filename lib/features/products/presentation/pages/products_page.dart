import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/sales/product_variant.dart';
import '../../../../core/sales/product_variant_store.dart';
import '../../../../core/utils/persian_number_formatter.dart';
import '../../../../core/widgets/zohal_card.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});
  @override State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final store = ProductVariantStore.instance;
  List<ProductVariant> products = [];
  bool loading = true;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    setState(() => loading = true);
    await store.ensureSeeded();
    final rows = await store.getAll();
    if (!mounted) return;
    setState(() { products = rows.where((x) => x.isActive).toList(); loading = false; });
  }

  Future<void> create() async {
    final value = await Navigator.of(context).push<ProductVariant>(
      MaterialPageRoute(builder: (_) => const _ProductForm()),
    );
    if (value == null) return;
    await store.upsert(value);
    await load();
  }

  Future<void> edit(ProductVariant p) async {
    final value = await Navigator.of(context).push<ProductVariant>(
      MaterialPageRoute(builder: (_) => _ProductForm(existing: p)),
    );
    if (value == null) return;
    await store.upsert(value);
    await load();
  }

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      appBar: AppBar(title: const Text('محصولات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: create, icon: const Icon(Icons.add), label: const Text('محصول جدید'),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: loading ? const Center(child: CircularProgressIndicator()) : ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(22)),
              child: Row(children: [
                const Icon(Icons.sell_rounded, color: AppColors.yellow, size: 30),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('کاتالوگ فروش', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(products.length.toString() + ' محصول فعال', style: const TextStyle(color: Colors.white70)),
                ])),
              ]),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty) const ZohalCard(child: Text('هنوز محصولی ثبت نشده است.')),
            ...products.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ZohalCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => edit(p),
                  leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
                  title: Text(p.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(p.packageGrams.toString() + ' گرم • ' + PersianNumberFormatter.money(p.currentSellingPrice)),
                  trailing: const Icon(Icons.chevron_left_rounded),
                ),
              ),
            )),
          ],
        ),
      ),
    ),
  );
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({this.existing});
  final ProductVariant? existing;
  @override State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final key = GlobalKey<FormState>();
  late final TextEditingController name, flavor, pack, grams, price;

  @override void initState() {
    super.initState();
    final p = widget.existing;
    name = TextEditingController(text: p?.productName ?? '');
    flavor = TextEditingController(text: p?.flavor ?? '');
    pack = TextEditingController(text: p?.packageLabel ?? '');
    grams = TextEditingController(text: p?.packageGrams.toString() ?? '');
    price = TextEditingController(text: p?.currentSellingPrice.toString() ?? '');
  }

  @override
  void dispose() {
    name.dispose(); flavor.dispose(); pack.dispose(); grams.dispose(); price.dispose(); super.dispose();
  }

  void save() {
    if (!key.currentState!.validate()) return;
    final p = widget.existing;
    Navigator.pop(context, ProductVariant(
      id: p?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      productName: name.text.trim(),
      flavor: flavor.text.trim(),
      packageLabel: pack.text.trim(),
      packageGrams: int.parse(grams.text),
      currentSellingPrice: int.parse(price.text.replaceAll(',', '')),
      isActive: p?.isActive ?? true,
    ));
  }

  String? requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? label + ' را وارد کنید' : null;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.existing == null ? 'محصول جدید' : 'ویرایش محصول')),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ZohalCard(child: Column(children: [
            TextFormField(controller: name, decoration: const InputDecoration(labelText: 'نام محصول'), validator: (v) => requiredText(v, 'نام محصول')),
            const SizedBox(height: 12),
            TextFormField(controller: flavor, decoration: const InputDecoration(labelText: 'طعم / مدل'), validator: (v) => requiredText(v, 'طعم / مدل')),
            const SizedBox(height: 12),
            TextFormField(controller: pack, decoration: const InputDecoration(labelText: 'نوع بسته‌بندی'), validator: (v) => requiredText(v, 'بسته‌بندی')),
            const SizedBox(height: 12),
            TextFormField(controller: grams, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'وزن بسته (گرم)'), validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n <= 0 ? 'وزن معتبر وارد کنید' : null;
            }),
            const SizedBox(height: 12),
            TextFormField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'قیمت فروش', suffixText: 'تومان'), validator: (v) {
              final n = int.tryParse((v ?? '').replaceAll(',', ''));
              return n == null || n < 0 ? 'قیمت معتبر وارد کنید' : null;
            }),
          ])),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('ذخیره محصول')),
        ],
      ),
    ),
  );
}
