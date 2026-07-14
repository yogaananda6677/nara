import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';
import 'package:nara/features/finance/domain/repositories/finance_repository.dart';

class FakeFinanceRepository implements FinanceRepository {
  FakeFinanceRepository({FinanceSnapshot? snapshot})
    : _snapshot = snapshot ?? const FinanceSnapshot.empty();

  FinanceSnapshot _snapshot;

  @override
  Future<FinanceSnapshot> loadSnapshot({
    required DateTime month,
    String search = '',
    TransactionFilter filter = TransactionFilter.all,
  }) async {
    final normalized = search.toLowerCase();
    final transactions = _snapshot.transactions.where((transaction) {
      final matchesType = switch (filter) {
        TransactionFilter.all => true,
        TransactionFilter.income =>
          transaction.type == FinanceTransactionType.income,
        TransactionFilter.expense =>
          transaction.type == FinanceTransactionType.expense,
      };
      return matchesType &&
          (normalized.isEmpty ||
              (transaction.description ?? '').toLowerCase().contains(
                normalized,
              ));
    }).toList();
    return _copy(transactions: transactions);
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    final accounts = [..._snapshot.accounts];
    final index = accounts.indexWhere((item) => item.account.id == account.id);
    final item = AccountBalance(
      account: account,
      balance: account.openingBalance,
    );
    if (index < 0) {
      accounts.add(item);
    } else {
      accounts[index] = AccountBalance(
        account: account,
        balance: accounts[index].balance,
      );
    }
    _snapshot = _copy(accounts: accounts);
  }

  @override
  Future<void> deleteAccount(String id) async {
    _snapshot = _copy(
      accounts: _snapshot.accounts
          .where((item) => item.account.id != id)
          .toList(),
    );
  }

  @override
  Future<void> saveCategory(FinanceCategory category) async {
    final items = [..._snapshot.categories];
    final index = items.indexWhere((item) => item.id == category.id);
    if (index < 0) {
      items.add(category);
    } else {
      items[index] = category;
    }
    _snapshot = _copy(categories: items);
  }

  @override
  Future<void> deleteCategory(String id) async {
    _snapshot = _copy(
      categories: _snapshot.categories.where((item) => item.id != id).toList(),
    );
  }

  @override
  Future<void> saveTransaction(FinanceTransaction transaction) async {
    final items = [..._snapshot.transactions];
    final index = items.indexWhere((item) => item.id == transaction.id);
    if (index < 0) {
      items.add(transaction);
    } else {
      items[index] = transaction;
    }
    _snapshot = _copy(transactions: items);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _snapshot = _copy(
      transactions: _snapshot.transactions
          .where((item) => item.id != id)
          .toList(),
    );
  }

  @override
  Future<void> transfer({
    required String outgoingId,
    required String incomingId,
    required String pairId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    required DateTime date,
    String? description,
  }) async {}

  @override
  Future<void> saveSavingGoal(SavingGoal goal) async {
    final items = [..._snapshot.savingGoals];
    final index = items.indexWhere((item) => item.id == goal.id);
    if (index < 0) {
      items.add(goal);
    } else {
      items[index] = goal;
    }
    _snapshot = _copy(savingGoals: items);
  }

  @override
  Future<void> deleteSavingGoal(String id) async {
    _snapshot = _copy(
      savingGoals: _snapshot.savingGoals
          .where((item) => item.id != id)
          .toList(),
    );
  }

  FinanceSnapshot _copy({
    List<AccountBalance>? accounts,
    List<FinanceCategory>? categories,
    List<FinanceTransaction>? transactions,
    List<SavingGoal>? savingGoals,
  }) {
    final nextAccounts = accounts ?? _snapshot.accounts;
    return FinanceSnapshot(
      accounts: nextAccounts,
      categories: categories ?? _snapshot.categories,
      transactions: transactions ?? _snapshot.transactions,
      savingGoals: savingGoals ?? _snapshot.savingGoals,
      summary: FinanceSummary(
        totalBalance: nextAccounts.fold(0, (sum, item) => sum + item.balance),
        monthlyIncome: _snapshot.summary.monthlyIncome,
        monthlyExpense: _snapshot.summary.monthlyExpense,
      ),
    );
  }
}
