import 'package:flutter/material.dart';

import '../../../../core/design/app_colors.dart';
import '../../../../core/inventory/inventory_item.dart';
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
  late final TextEditingController kcal, protein, fat, saturated, carbs, sugar, fiber, sodium;
  bool nutritionEnabled = false;

  @override void initState() {
    super.initState();
    final p = widget.existing;
    name = TextEditingController(text: p?.productName ?? '');
    flavor = TextEditingController(text: p?.flavor ?? '');
    pack = TextEditingController(text: p?.packageLabel ?? '');
    grams = TextEditingController(text: p?.packageGrams.toString() ?? '');
    price = TextEditingController(text: p?.currentSellingPrice.toString() ?? '');
    final n = p?.nutrition;
    nutritionEnabled = n != null;
    kcal = TextEditingController(text: n?.energyKcal.toString() ?? '');
    protein = TextEditingController(text: n?.proteinG.toString() ?? '');
    fat = TextEditingController(text: n?.totalFatG.toString() ?? '');
    saturated = TextEditingController(text: n?.saturatedFatG.toString() ?? '');
    carbs = TextEditingController(text: n?.carbohydrateG.toString() ?? '');
    sugar = TextEditingController(text: n?.totalSugarG.toString() ?? '');
    fiber = TextEditingController(text: n?.fiberG.toString() ?? '');
    sodium = TextEditingController(text: n?.sodiumMg.toString() ?? '');
  }

  @override
  void dispose() {
    name.dispose(); flavor.dispose(); pack.dispose(); grams.dispose(); price.dispose();
    kcal.dispose(); protein.dispose(); fat.dispose(); saturated.dispose(); carbs.dispose(); sugar.dispose(); fiber.dispose(); sodium.dispose();
    super.dispose();
  }

  void save() {
    if (!key.currentState!.validate()) return;
    NutritionProfile? nutrition;
    if (nutritionEnabled) {
      final values = [
        double.tryParse(kcal.text),
        double.tryParse(protein.text),
        double.tryParse(fat.text),
        double.tryParse(saturated.text),
        double.tryParse(carbs.text),
        double.tryParse(sugar.text),
        double.tryParse(fiber.text),
        double.tryParse(sodium.text),
      ];
      if (values.any((value) => value == null || value < 0)) return;
      nutrition = NutritionProfile(
        energyKcal: values[0]!,
        proteinG: values[1]!,
        totalFatG: values[2]!,
        saturatedFatG: values[3]!,
        carbohydrateG: values[4]!,
        totalSugarG: values[5]!,
        fiberG: values[6]!,
        sodiumMg: values[7]!,
      );
    }
    final p = widget.existing;
    Navigator.pop(context, ProductVariant(
      id: p?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      productName: name.text.trim(),
      flavor: flavor.text.trim(),
      packageLabel: pack.text.trim(),
      packageGrams: int.parse(grams.text),
      currentSellingPrice: int.parse(price.text.replaceAll(',', '')),
      isActive: p?.isActive ?? true,
      nutrition: nutrition,
    ));
  }

  String? requiredText(String? value, String label) =>
      value == null || value.trim().isEmpty ? label + ' را وارد کنید' : null;

  Widget _nutritionField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          if (!nutritionEnabled) return null;
          final n = double.tryParse(value ?? '');
          return n == null || n < 0 ? 'مقدار معتبر وارد کنید' : null;
        },
      ),
    );
  }

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
            DropdownButtonFormField<String>(
              initialValue: ['زنجبیل', 'آرد نخودچی', 'ساده (پودر نشاسته ذرت)'].contains(flavor.text)
                  ? flavor.text
                  : null,
              decoration: const InputDecoration(labelText: 'طعم / مدل'),
              items: const [
                DropdownMenuItem(value: 'زنجبیل', child: Text('زنجبیل')),
                DropdownMenuItem(value: 'آرد نخودچی', child: Text('آرد نخودچی')),
                DropdownMenuItem(value: 'ساده (پودر نشاسته ذرت)', child: Text('ساده (پودر نشاسته ذرت)')),
              ],
              onChanged: (value) => setState(() => flavor.text = value ?? ''),
              validator: (v) => requiredText(v, 'طعم / مدل'),
            ),
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
          ZohalCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ارزش غذایی', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('اختیاری است و بعداً هم قابل تکمیل یا ویرایش است.'),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('ثبت ارزش غذایی'),
                  value: nutritionEnabled,
                  onChanged: (value) => setState(() => nutritionEnabled = value),
                ),
                if (nutritionEnabled) ...[
                  _nutritionField(kcal, 'انرژی (kcal)'),
                  _nutritionField(protein, 'پروتئین (g)'),
                  _nutritionField(fat, 'چربی کل (g)'),
                  _nutritionField(saturated, 'چربی اشباع (g)'),
                  _nutritionField(carbs, 'کربوهیدرات (g)'),
                  _nutritionField(sugar, 'قند کل (g)'),
                  _nutritionField(fiber, 'فیبر (g)'),
                  _nutritionField(sodium, 'سدیم (mg)'),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: save, icon: const Icon(Icons.save_outlined), label: const Text('ذخیره محصول')),
        ],
      ),
    ),
  );
}
