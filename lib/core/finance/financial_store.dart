import '../storage/local_store.dart';
import 'financial_account.dart';
import 'financial_entry.dart';

class FinancialStore {
  FinancialStore._();

  static final FinancialStore instance = FinancialStore._();
  static const _accountKey = 'financial_accounts';
  static const _transactionKey = 'financial_transactions';

  Future<List<FinancialAccount>> getAccounts() async {
    final rows = await LocalStore.instance.readList(_accountKey);
    return rows.map(FinancialAccount.fromMap).toList();
  }

  Future<FinancialAccount?> getAccount(String id) async {
    final accounts = await getAccounts();
    for (final account in accounts) {
      if (account.id == id) return account;
    }
    return null;
  }

  Future<void> ensureAccount(FinancialAccount account) async {
    final existing = await getAccount(account.id);
    if (existing != null) {
      if (existing.type != account.type || existing.name != account.name) {
        throw StateError('حساب مالی ناسازگار است: ' + account.id);
      }
      return;
    }
    final accounts = await getAccounts();
    accounts.add(account);
    await LocalStore.instance.writeList(_accountKey, accounts.map((a) => a.toMap()).toList());
  }

  Future<List<FinancialTransaction>> getTransactions() async {
    final rows = await LocalStore.instance.readList(_transactionKey);
    return rows.map(FinancialTransaction.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<FinancialTransaction?> getTransaction(String id) async {
    final rows = await getTransactions();
    for (final transaction in rows) {
      if (transaction.id == id) return transaction;
    }
    return null;
  }

  Future<void> addTransaction(FinancialTransaction transaction) async {
    if (!transaction.isBalanced) throw StateError('سند مالی باید تراز باشد.');
    if (transaction.entries.isEmpty || transaction.entries.any((e) => e.amount <= 0)) {
      throw StateError('سند مالی معتبر نیست.');
    }
    if (await getTransaction(transaction.id) != null) {
      throw StateError('سند مالی تکراری است.');
    }
    final transactions = await getTransactions();
    transactions.add(transaction);
    await LocalStore.instance.writeList(_transactionKey, transactions.map((t) => t.toMap()).toList());
  }

  Future<int> getBalance(String accountId) async {
    final transactions = await getTransactions();
    return transactions.fold<int>(0, (balance, transaction) {
      for (final entry in transaction.entries) {
        if (entry.accountId == accountId) {
          balance += entry.isDebit ? entry.amount : -entry.amount;
        }
      }
      return balance;
    });
  }

  Future<void> clear() async {
    await LocalStore.instance.remove(_accountKey);
    await LocalStore.instance.remove(_transactionKey);
  }
}
