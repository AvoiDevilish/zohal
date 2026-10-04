class Customer {
  const Customer({
    required this.id,
    required this.name,
    this.phone,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? phone;
  final String? notes;
  final bool isActive;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'notes': notes,
    'isActive': isActive,
  };

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
