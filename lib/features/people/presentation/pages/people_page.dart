import 'package:flutter/material.dart';

import '../../../../core/design/app_spacing.dart';
import '../../../../core/sales/customer.dart';
import '../../../../core/sales/customer_store.dart';
import '../../../../core/sales/supplier.dart';
import '../../../../core/sales/supplier_store.dart';
import '../../../../core/people/person.dart';
import '../../../../core/people/person_store.dart';
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

  List<Person> people = [];
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
    final personRows = await PersonStore.instance.getAll();
    final customerRows = await _customerStore.getAll();
    final supplierRows = await _supplierStore.getAll();
    if (!mounted) return;
    setState(() {
      people = personRows.where((item) => showInactive ? !item.isActive : item.isActive).toList();
      customers = customerRows.where((item) => showInactive ? !item.isActive : item.isActive).toList();
      suppliers = supplierRows.where((item) => showInactive ? !item.isActive : item.isActive).toList();
      loading = false;
    });
  }

  Future<void> addPerson() async {
    final draft = await showDialog<_PersonDraft>(
      context: context,
      builder: (_) => const _PersonDialog(),
    );
    if (draft == null) return;
    await _savePerson(draft);
    await load();
  }

  Future<void> _savePerson(_PersonDraft draft) async {
    final id = draft.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    final current = await PersonStore.instance.getById(id);
    final roles = <PersonRole>{
      if (draft.customer) PersonRole.customer,
      if (draft.supplier) PersonRole.supplier,
    };
    if (roles.isEmpty) return;

    await PersonStore.instance.upsert(Person(
      id: id,
      name: draft.name,
      roles: roles,
      phone: draft.phone,
      notes: draft.notes,
      isActive: draft.isActive,
    ));

    if (draft.customer) {
      await _customerStore.upsert(Customer(
        id: id,
        name: draft.name,
        phone: draft.phone,
        notes: draft.notes,
        isActive: draft.isActive,
      ));
    } else if (current?.isCustomer == true) {
      await _customerStore.setActive(id, false);
    }

    if (draft.supplier) {
      await _supplierStore.upsert(Supplier(
        id: id,
        name: draft.name,
        phone: draft.phone,
        notes: draft.notes,
        isActive: draft.isActive,
      ));
    } else if (current?.isSupplier == true) {
      await _supplierStore.setActive(id, false);
    }
  }

  Future<void> editCustomer(Customer value) async {
    await _editPerson(value.id);
  }

  Future<void> editSupplier(Supplier value) async {
    await _editPerson(value.id);
  }

  Future<void> _editPerson(String id) async {
    final person = await PersonStore.instance.getById(id);
    if (person == null) return;
    final draft = await showDialog<_PersonDraft>(
      context: context,
      builder: (_) => _PersonDialog(
        existingId: person.id,
        name: person.name,
        phone: person.phone,
        notes: person.notes,
        customer: person.isCustomer,
        supplier: person.isSupplier,
        isActive: person.isActive,
      ),
    );
    if (draft == null) return;
    await _savePerson(draft);
    await load();
  }

  Future<void> deactivatePerson(String id) async {
    final person = await PersonStore.instance.getById(id);
    if (person == null) return;
    await PersonStore.instance.upsert(person.copyWith(isActive: false));
    if (person.isCustomer) await _customerStore.setActive(id, false);
    if (person.isSupplier) await _supplierStore.setActive(id, false);
    await load();
  }

  Future<void> activatePerson(String id) async {
    final person = await PersonStore.instance.getById(id);
    if (person == null) return;
    await PersonStore.instance.upsert(person.copyWith(isActive: true));
    if (person.isCustomer) await _customerStore.setActive(id, true);
    if (person.isSupplier) await _supplierStore.setActive(id, true);
    await load();
  }

  PersonType _personType(String id) {
    final matches = people.where((item) => item.id == id);
    if (matches.isNotEmpty && matches.first.isCustomer && matches.first.isSupplier) {
      return PersonType.both;
    }
    return tab == 0 ? PersonType.customer : PersonType.supplier;
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
                                    type: _personType(person.id),
                                    phone: person.phone,
                                    notes: person.notes,
                                  ),
                                )),
                                onEdit: () => editCustomer(person),
                                onDeactivate: showInactive
                                    ? () => activatePerson(person.id)
                                    : () => deactivatePerson(person.id),
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
                                  type: _personType(person.id),
                                  phone: person.phone,
                                  notes: person.notes,
                                ),
                              )),
                              onEdit: () => editSupplier(person),
                              onDeactivate: showInactive
                                  ? () => activatePerson(person.id)
                                  : () => deactivatePerson(person.id),
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


class _PersonDialog extends StatefulWidget {
  const _PersonDialog({
    this.existingId,
    this.name = '',
    this.phone,
    this.notes,
    this.customer = true,
    this.supplier = false,
    this.isActive = true,
  });

  final String? existingId;
  final String name;
  final String? phone;
  final String? notes;
  final bool customer;
  final bool supplier;
  final bool isActive;

  @override
  State<_PersonDialog> createState() => _PersonDialogState();
}

class _PersonDialogState extends State<_PersonDialog> {
  final key = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController notes;
  late bool customer;
  late bool supplier;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.name);
    phone = TextEditingController(text: widget.phone ?? '');
    notes = TextEditingController(text: widget.notes ?? '');
    customer = widget.customer;
    supplier = widget.supplier;
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    notes.dispose();
    super.dispose();
  }

  void save() {
    if (!key.currentState!.validate() || (!customer && !supplier)) return;
    Navigator.pop(
      context,
      _PersonDraft(
        id: widget.existingId,
        name: name.text.trim(),
        phone: phone.text.trim().isEmpty ? null : phone.text.trim(),
        notes: notes.text.trim().isEmpty ? null : notes.text.trim(),
        customer: customer,
        supplier: supplier,
        isActive: widget.isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingId == null ? 'افزودن شخص' : 'ویرایش شخص'),
      content: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'نام'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'نام را وارد کنید'
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
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: customer,
                title: const Text('مشتری'),
                onChanged: (value) => setState(() => customer = value ?? false),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: supplier,
                title: const Text('تأمین‌کننده'),
                onChanged: (value) => setState(() => supplier = value ?? false),
              ),
              if (!customer && !supplier)
                const Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'حداقل یک نقش را انتخاب کنید.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
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
}

class _PersonDraft {
  const _PersonDraft({
    this.id,
    required this.name,
    this.phone,
    this.notes,
    required this.customer,
    required this.supplier,
    required this.isActive,
  });

  final String? id;
  final String name;
  final String? phone;
  final String? notes;
  final bool customer;
  final bool supplier;
  final bool isActive;
}
