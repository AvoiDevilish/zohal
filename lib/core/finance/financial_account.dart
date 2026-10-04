enum FinancialAccountType { customer, supplier, cash, salesRevenue, inventoryAsset }

class FinancialAccount {
  const FinancialAccount({
    required this.id,
    required this.name,
    required this.type,
  });

  final String id;
  final String name;
  final FinancialAccountType type;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
  };

  factory FinancialAccount.fromMap(Map<String, dynamic> map) {
    return FinancialAccount(
      id: map['id'] as String,
      name: map['name'] as String,
      type: FinancialAccountType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => FinancialAccountType.customer,
      ),
    );
  }
}
