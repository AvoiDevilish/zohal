class FinancialEntry {
  const FinancialEntry({
    required this.accountId,
    required this.amount,
    required this.isDebit,
    this.note,
  });

  final String accountId;
  final int amount;
  final bool isDebit;
  final String? note;

  Map<String, dynamic> toMap() => {
    'accountId': accountId,
    'amount': amount,
    'isDebit': isDebit,
    'note': note,
  };

  factory FinancialEntry.fromMap(Map<String, dynamic> map) {
    return FinancialEntry(
      accountId: map['accountId'] as String,
      amount: (map['amount'] as num).toInt(),
      isDebit: map['isDebit'] as bool,
      note: map['note'] as String?,
    );
  }
}

class FinancialTransaction {
  const FinancialTransaction({
    required this.id,
    required this.createdAt,
    required this.type,
    required this.referenceId,
    required this.entries,
    this.note,
  });

  final String id;
  final DateTime createdAt;
  final String type;
  final String referenceId;
  final List<FinancialEntry> entries;
  final String? note;

  int get totalDebits => entries.where((e) => e.isDebit).fold(0, (s, e) => s + e.amount);
  int get totalCredits => entries.where((e) => !e.isDebit).fold(0, (s, e) => s + e.amount);
  bool get isBalanced => totalDebits == totalCredits;

  Map<String, dynamic> toMap() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'type': type,
    'referenceId': referenceId,
    'entries': entries.map((e) => e.toMap()).toList(),
    'note': note,
  };

  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      type: map['type'] as String,
      referenceId: map['referenceId'] as String,
      entries: (map['entries'] as List)
          .whereType<Map>()
          .map((e) => FinancialEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      note: map['note'] as String?,
    );
  }
}
