import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/customer.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/supplier.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/widgets/zohal_card.dart';
import 'person_profile_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  final _customerStore = CustomerStore.instance;
  final _supplierStore = SupplierStore.instance;

  List<Customer> customers = [];
  List<Supplier> suppliers = [];
  int tab = 0;
  bool loading = true;
  bool showInactive = false;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    final customerRows = await _customerStore.getAll();
    final supplierRows = await _supplierStore.getAll();
    if (!mounted) return;
    setState(() {
      customers = customerRows.where((item) => showInactive ? !item.isActive : item.isActive).toList();
      suppliers = supplierRows.where((item) => showInactive ? !item.isActive : item.isActive).toList();
      loading = false;
    });
  }

  Future<void> addPerson() async {
    if (tab == 0) {
      final value = await showDialog<Customer>(
        context: context,
        builder: (_) => const _CustomerDialog(),
      );
      if (value != null) await _customerStore.upsert(value);
    } else {
      final value = await showDialog<Supplier>(
        context: context,
        builder: (_) => const _SupplierDialog(),
      );
      if (value != null) await _supplierStore.upsert(value);
    }
    await load();
  }

  Future<void> editCustomer(Customer value) async {
    final updated = await showDialog<Customer>(
      context: context,
      builder: (_) => _CustomerDialog(existing: value),
    );
    if (updated != null) await _customerStore.upsert(updated);
    await load();
  }

  Future<void> editSupplier(Supplier value) async {
    final updated = await showDialog<Supplier>(
      context: context,
      builder: (_) => _SupplierDialog(existing: value),
    );
    if (updated != null) await _supplierStore.upsert(updated);
    await load();
  }

  Future<void> deactivateCustomer(Customer value) async {
    final updated = Customer(
      id: value.id,
      name: value.name,
      phone: value.phone,
      notes: value.notes,
      isActive: false,
    );
    await _customerStore.upsert(updated);
    await load();
  }

  Future<void> deactivateSupplier(Supplier value) async {
    await _supplierStore.deactivate(value.id);
    await load();
  }

  Future<void> activateCustomer(Customer value) async {
    await _customerStore.setActive(value.id, true);
    await load();
  }

  Future<void> activateSupplier(Supplier value) async {
    await _supplierStore.setActive(value.id, true);
    await load();
  }

  @override
  Widget build(BuildContext context) {
    final people = tab == 0 ? customers : suppliers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('مدیریت اشخاص'),
        actions: [
          IconButton(
            onPressed: addPerson,
            tooltip: tab == 0 ? 'افزودن مشتری' : 'افزودن تأمین‌کننده',
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addPerson,
        icon: const Icon(Icons.add),
        label: Text(tab == 0 ? 'مشتری جدید' : 'تأمین‌کننده جدید'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('مشتریان')),
                ButtonSegment(value: 1, label: Text('تأمین‌کنندگان')),
              ],
              selected: {tab},
              onSelectionChanged: (value) {
                setState(() => tab = value.first);
              },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                FilterChip(
                  label: const Text('غیرفعال'),
                  selected: showInactive,
                  onSelected: (value) {
                    setState(() => showInactive = value);
                    load();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: load,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : people.isEmpty
                      ? ListView(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(32),
                              child: Center(
                                child: Text(
                                  tab == 0
                                      ? 'هنوز مشتری ثبت نشده است.'
                                      : 'هنوز تأمین‌کننده ثبت نشده است.',
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            0,
                            AppSpacing.md,
                            100,
                          ),
                          itemCount: people.length,
                          itemBuilder: (context, index) {
                            if (tab == 0) {
                              final person = customers[index];
                              return _PersonCard(
                                name: person.name,
                                phone: person.phone,
                                notes: person.notes,
                                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => PersonProfilePage(
                                    personId: person.id,
                                    name: person.name,
                                    type: PersonType.customer,
                                    phone: person.phone,
                                    notes: person.notes,
                                  ),
                                )),
                                onEdit: () => editCustomer(person),
                                onDeactivate: showInactive
                                    ? () => activateCustomer(person)
                                    : () => deactivateCustomer(person),
                                actionLabel: showInactive ? 'فعال کردن' : 'غیرفعال کردن',
                              );
                            }

                            final person = suppliers[index];
                            return _PersonCard(
                              name: person.name,
                              phone: person.phone,
                              notes: person.notes,
                              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                builder: (_) => PersonProfilePage(
                                  personId: person.id,
                                  name: person.name,
                                  type: PersonType.supplier,
                                  phone: person.phone,
                                  notes: person.notes,
                                ),
                              )),
                              onEdit: () => editSupplier(person),
                              onDeactivate: showInactive
                                  ? () => activateSupplier(person)
                                  : () => deactivateSupplier(person),
                              actionLabel: showInactive ? 'فعال کردن' : 'غیرفعال کردن',
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.name,
    required this.phone,
    required this.notes,
    required this.onTap,
    required this.onEdit,
    required this.onDeactivate,
    required this.actionLabel,
  });

  final String name;
  final String? phone;
  final String? notes;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ZohalCard(
        child: ListTile(
          onTap: onTap,
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.person_outline),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            [
              if (phone != null && phone!.isNotEmpty) phone!,
              if (notes != null && notes!.isNotEmpty) notes!,
            ].join(' • '),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') onEdit();
              if (value == 'deactivate') onDeactivate();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('ویرایش')),
              PopupMenuItem(value: 'deactivate', child: Text(actionLabel)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerDialog extends StatefulWidget {
  const _CustomerDialog({this.existing});

  final Customer? existing;

  @override
  State<_CustomerDialog> createState() => _CustomerDialogState();
}

class _CustomerDialogState extends State<_CustomerDialog> {
  final key = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.name ?? '');
    phone = TextEditingController(text: widget.existing?.phone ?? '');
    notes = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  void save() {
    if (!key.currentState!.validate()) return;
    Navigator.pop(
      context,
      Customer(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        isActive: widget.existing?.isActive ?? true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'افزودن مشتری' : 'ویرایش مشتری'),
      content: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'نام مشتری'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'نام مشتری را وارد کنید'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'تلفن'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'یادداشت'),
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
        FilledButton(onPressed: save, child: const Text('ذخیره')),
      ],
    );
  }
}

class _SupplierDialog extends StatefulWidget {
  const _SupplierDialog({this.existing});

  final Supplier? existing;

  @override
  State<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends State<_SupplierDialog> {
  final key = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.existing?.name ?? '');
    phone = TextEditingController(text: widget.existing?.phone ?? '');
    notes = TextEditingController(text: widget.existing?.notes ?? '');
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  void save() {
    if (!key.currentState!.validate()) return;
    Navigator.pop(
      context,
      Supplier(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'افزودن تأمین‌کننده'
            : 'ویرایش تأمین‌کننده',
      ),
      content: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: 'نام تأمین‌کننده'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'نام تأمین‌کننده را وارد کنید'
                    : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'تلفن'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: notes,
                decoration: const InputDecoration(labelText: 'یادداشت'),
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
        FilledButton(onPressed: save, child: const Text('ذخیره')),
      ],
    );
  }
}
