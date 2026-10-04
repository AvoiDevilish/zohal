enum PersonRole { customer, supplier }

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.roles,
    this.phone,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final Set<PersonRole> roles;
  final String? phone;
  final String? notes;
  final bool isActive;

  bool get isCustomer => roles.contains(PersonRole.customer);
  bool get isSupplier => roles.contains(PersonRole.supplier);

  Person copyWith({
    String? name,
    Set<PersonRole>? roles,
    String? phone,
    String? notes,
    bool? isActive,
  }) => Person(
    id: id,
    name: name ?? this.name,
    roles: roles ?? this.roles,
    phone: phone ?? this.phone,
    notes: notes ?? this.notes,
    isActive: isActive ?? this.isActive,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'roles': roles.map((role) => role.name).toList(),
    'phone': phone,
    'notes': notes,
    'isActive': isActive,
  };

  factory Person.fromMap(Map<String, dynamic> map) => Person(
    id: map['id'] as String,
    name: map['name'] as String,
    roles: (map['roles'] as List? ?? const [])
        .whereType<String>()
        .map((value) => PersonRole.values.firstWhere(
              (role) => role.name == value,
              orElse: () => PersonRole.customer,
            ))
        .toSet(),
    phone: map['phone'] as String?,
    notes: map['notes'] as String?,
    isActive: map['isActive'] as bool? ?? true,
  );
}
