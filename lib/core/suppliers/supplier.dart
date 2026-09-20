class Supplier {
  final String id;
  final String name;
  final String? phone;
  final String? address;
  final String? note;
  final bool active;

  const Supplier({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    this.note,
    this.active = true,
  });

  Supplier copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    String? note,
    bool? active,
    bool clearPhone = false,
    bool clearAddress = false,
    bool clearNote = false,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: clearPhone ? null : phone ?? this.phone,
      address: clearAddress ? null : address ?? this.address,
      note: clearNote ? null : note ?? this.note,
      active: active ?? this.active,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'address': address,
      'note': note,
      'active': active,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      note: map['note'] as String?,
      active: map['active'] as bool? ?? true,
    );
  }
}
