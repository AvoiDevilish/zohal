import 'package:flutter/material.dart';

class Product {
  Product({
    required this.name,
    required this.code,
    required this.unit,
    required this.price,
    this.stock = 0,
  });

  String name;
  String code;
  String unit;
  int price;
  int stock;
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final List<Product> _products = [
    Product(
      name: 'خرمای مغزدار',
      code: 'Z-001',
      unit: 'بسته',
      price: 85000,
      stock: 24,
    ),
    Product(
      name: 'بار انرژی خرما و گردو',
      code: 'Z-002',
      unit: 'بسته',
      price: 120000,
      stock: 18,
    ),
  ];

  Future<void> _addProduct() async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => const _ProductDialog(),
    );

    if (result != null) {
      setState(() {
        _products.add(result);
      });
    }
  }

  Future<void> _editProduct(int index) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductDialog(product: _products[index]),
    );

    if (result != null) {
      setState(() {
        _products[index] = result;
      });
    }
  }

  void _deleteProduct(int index) {
    final product = _products[index];

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف محصول'),
        content: Text('محصول «${product.name}» حذف شود؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('انصراف'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                _products.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('محصولات'),
        actions: [
          IconButton(
            onPressed: _addProduct,
            icon: const Icon(Icons.add),
            tooltip: 'محصول جدید',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add),
        label: const Text('محصول جدید'),
      ),
      body: _products.isEmpty
          ? const Center(child: Text('هنوز محصولی ثبت نشده است'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final product = _products[index];

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${product.code}  •  ${product.unit}\n'
                      'موجودی: ${product.stock}',
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editProduct(index);
                        } else if (value == 'delete') {
                          _deleteProduct(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('ویرایش')),
                        PopupMenuItem(value: 'delete', child: Text('حذف')),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ProductDialog extends StatefulWidget {
  const _ProductDialog({this.product});

  final Product? product;

  @override
  State<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<_ProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _unitController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  @override
  void initState() {
    super.initState();

    final product = widget.product;

    _nameController = TextEditingController(text: product?.name ?? '');
    _codeController = TextEditingController(text: product?.code ?? '');
    _unitController = TextEditingController(text: product?.unit ?? 'بسته');
    _priceController = TextEditingController(
      text: product?.price.toString() ?? '',
    );
    _stockController = TextEditingController(
      text: product?.stock.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _unitController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final product = Product(
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      unit: _unitController.text.trim(),
      price: int.tryParse(_priceController.text.trim()) ?? 0,
      stock: int.tryParse(_stockController.text.trim()) ?? 0,
    );

    Navigator.pop(context, product);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.product != null;

    return AlertDialog(
      title: Text(editing ? 'ویرایش محصول' : 'محصول جدید'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'نام محصول',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'نام محصول را وارد کنید';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'کد محصول',
                  prefixIcon: Icon(Icons.qr_code_2),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'واحد',
                  prefixIcon: Icon(Icons.straighten),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'قیمت فروش',
                  suffixText: 'تومان',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'موجودی اولیه',
                  prefixIcon: Icon(Icons.warehouse_outlined),
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
        FilledButton(
          onPressed: _save,
          child: Text(editing ? 'ذخیره تغییرات' : 'ثبت محصول'),
        ),
      ],
    );
  }
}
