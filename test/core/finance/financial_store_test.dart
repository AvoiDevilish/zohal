import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zohal_android_test/core/finance/financial_account.dart';
import 'package:zohal_android_test/core/finance/financial_entry.dart';
import 'package:zohal_android_test/core/finance/financial_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final store = FinancialStore.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await store.clear();
  });

  FinancialAccount account(
    String id,
    FinancialAccountType type,
  ) {
    return FinancialAccount(
      id: id,
      name: id,
      type: type,
    );
  }

  FinancialTransaction transaction({
    String id = 'tx-1',
    String type = 'purchase',
    String referenceId = 'purchase-1',
    List<FinancialEntry>? entries,
  }) {
    return FinancialTransaction(
      id: id,
      createdAt: DateTime(2026, 1, 1),
      type: type,
      referenceId: referenceId,
      entries: entries ??
          const [
            FinancialEntry(
              accountId: 'inventory',
              amount: 1000,
              isDebit: true,
            ),
            FinancialEntry(
              accountId: 'supplier',
              amount: 1000,
              isDebit: false,
            ),
          ],
    );
  }

  test('rejects transaction referencing an unknown account', () async {
    await store.ensureAccount(
      account('inventory', FinancialAccountType.inventoryAsset),
    );

    expect(
      () => store.addTransaction(transaction()),
      throwsA(isA<StateError>()),
    );

    expect(await store.getTransactions(), isEmpty);
  });

  test('rejects duplicate account entries inside one transaction', () async {
    await store.ensureAccount(
      account('cash', FinancialAccountType.cash),
    );

    expect(
      () => store.addTransaction(
        transaction(
          entries: const [
            FinancialEntry(
              accountId: 'cash',
              amount: 1000,
              isDebit: true,
            ),
            FinancialEntry(
              accountId: 'cash',
              amount: 1000,
              isDebit: false,
            ),
          ],
        ),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await store.getTransactions(), isEmpty);
  });

  test('rejects transaction with missing identity fields', () async {
    await store.ensureAccount(
      account('inventory', FinancialAccountType.inventoryAsset),
    );
    await store.ensureAccount(
      account('supplier', FinancialAccountType.supplier),
    );

    expect(
      () => store.addTransaction(
        transaction(
          id: '',
        ),
      ),
      throwsA(isA<StateError>()),
    );

    expect(await store.getTransactions(), isEmpty);
  });

  test('accepts a balanced transaction when all accounts exist', () async {
    await store.ensureAccount(
      account('inventory', FinancialAccountType.inventoryAsset),
    );
    await store.ensureAccount(
      account('supplier', FinancialAccountType.supplier),
    );

    await store.addTransaction(transaction());

    final stored = await store.getTransaction('tx-1');

    expect(stored, isNotNull);
    expect(stored!.isBalanced, isTrue);
    expect(stored.entries, hasLength(2));
  });
}
