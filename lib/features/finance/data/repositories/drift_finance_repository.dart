import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart' as db;
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart'
    as domain;
import 'package:nara/features/finance/domain/repositories/finance_repository.dart';

class DriftFinanceRepository implements FinanceRepository {
  DriftFinanceRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<FinanceSnapshot> loadSnapshot({
    required DateTime month,
    String search = '',
    TransactionFilter filter = TransactionFilter.all,
  }) async {
    final accountRows = await (_database.select(
      _database.accounts,
    )..where((row) => row.isArchived.equals(false))).get();
    final categoryRows = await _database.select(_database.categories).get();
    final allTransactions = await _database
        .select(_database.transactionEntries)
        .get();
    final savingRows = await (_database.select(
      _database.savingGoals,
    )..orderBy([(row) => OrderingTerm.asc(row.isCompleted)])).get();

    final accountBalances = accountRows.map((row) {
      var balance = row.openingBalance;
      for (final transaction in allTransactions) {
        if (transaction.accountId != row.id) continue;
        final type = FinanceTransactionType.fromStorage(transaction.type);
        if (type == FinanceTransactionType.income ||
            type == FinanceTransactionType.transferIn) {
          balance += transaction.amount;
        } else {
          balance -= transaction.amount;
        }
      }
      return AccountBalance(account: _account(row), balance: balance);
    }).toList();

    final monthStart = DateTime(month.year, month.month).toUtc();
    final monthEnd = DateTime(month.year, month.month + 1).toUtc();
    final monthlyRows = allTransactions.where(
      (row) => !row.date.isBefore(monthStart) && row.date.isBefore(monthEnd),
    );

    var monthlyIncome = 0;
    var monthlyExpense = 0;
    for (final row in monthlyRows) {
      final type = FinanceTransactionType.fromStorage(row.type);
      if (type == FinanceTransactionType.income) monthlyIncome += row.amount;
      if (type == FinanceTransactionType.expense) monthlyExpense += row.amount;
    }

    final categoryNames = {for (final row in categoryRows) row.id: row.name};
    final normalizedSearch = search.trim().toLowerCase();
    final filteredTransactions = monthlyRows.where((row) {
      final type = FinanceTransactionType.fromStorage(row.type);
      // A transfer is stored as a debit and a credit for correct account
      // balances, but it should only appear once in the activity list.
      if (type == FinanceTransactionType.transferIn) return false;
      final matchesFilter = switch (filter) {
        TransactionFilter.all => true,
        TransactionFilter.income => type == FinanceTransactionType.income,
        TransactionFilter.expense => type == FinanceTransactionType.expense,
      };
      if (!matchesFilter) return false;
      if (normalizedSearch.isEmpty) return true;

      final haystack = [
        row.description,
        row.merchant,
        categoryNames[row.categoryId],
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(normalizedSearch);
    }).toList()..sort((a, b) => b.date.compareTo(a.date));

    return FinanceSnapshot(
      accounts: accountBalances,
      categories: categoryRows.map(_category).toList(),
      transactions: filteredTransactions.map(_transaction).toList(),
      savingGoals: savingRows.map(_savingGoal).toList(),
      summary: FinanceSummary(
        totalBalance: accountBalances.fold(
          0,
          (total, item) => total + item.balance,
        ),
        monthlyIncome: monthlyIncome,
        monthlyExpense: monthlyExpense,
      ),
    );
  }

  @override
  Future<void> saveAccount(FinanceAccount account) async {
    await _database
        .into(_database.accounts)
        .insertOnConflictUpdate(
          db.AccountsCompanion.insert(
            id: account.id,
            name: account.name,
            type: Value(account.type.name),
            openingBalance: Value(account.openingBalance),
            currency: Value(account.currency),
            isArchived: Value(account.isArchived),
            createdAt: Value(account.createdAt.toUtc()),
            updatedAt: Value(account.updatedAt.toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteAccount(String id) async {
    final transactionCountExpression = _database.transactionEntries.id.count();
    final transactionCount =
        await (_database.selectOnly(_database.transactionEntries)
              ..addColumns([transactionCountExpression])
              ..where(_database.transactionEntries.accountId.equals(id)))
            .map((row) => row.read(transactionCountExpression) ?? 0)
            .getSingle();
    final goalCountExpression = _database.savingGoals.id.count();
    final goalCount =
        await (_database.selectOnly(_database.savingGoals)
              ..addColumns([goalCountExpression])
              ..where(_database.savingGoals.accountId.equals(id)))
            .map((row) => row.read(goalCountExpression) ?? 0)
            .getSingle();

    if (transactionCount > 0 || goalCount > 0) {
      await (_database.update(
        _database.accounts,
      )..where((row) => row.id.equals(id))).write(
        db.AccountsCompanion(
          isArchived: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
        ),
      );
      return;
    }
    await (_database.delete(
      _database.accounts,
    )..where((row) => row.id.equals(id))).go();
  }

  @override
  Future<void> saveCategory(FinanceCategory category) async {
    await _database
        .into(_database.categories)
        .insertOnConflictUpdate(
          db.CategoriesCompanion.insert(
            id: category.id,
            name: category.name,
            type: category.type.name,
            icon: Value(category.icon),
            colorValue: Value(category.colorValue),
            isSystem: Value(category.isSystem),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteCategory(String id) async {
    final row = await (_database.select(
      _database.categories,
    )..where((item) => item.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    if (row.isSystem) {
      throw StateError('Kategori bawaan tidak dapat dihapus.');
    }

    final transactionCountExpression = _database.transactionEntries.id.count();
    final used =
        await (_database.selectOnly(_database.transactionEntries)
              ..addColumns([transactionCountExpression])
              ..where(_database.transactionEntries.categoryId.equals(id)))
            .map((result) => result.read(transactionCountExpression) ?? 0)
            .getSingle();
    if (used > 0) {
      throw StateError('Kategori masih digunakan oleh transaksi.');
    }
    await (_database.delete(
      _database.categories,
    )..where((item) => item.id.equals(id))).go();
  }

  @override
  Future<void> saveTransaction(FinanceTransaction transaction) async {
    if (transaction.type.isTransfer) {
      throw ArgumentError('Gunakan operasi transfer untuk transaksi transfer.');
    }
    if (transaction.categoryId == null) {
      throw ArgumentError('Kategori transaksi wajib dipilih.');
    }
    final category =
        await (_database.select(_database.categories)
              ..where((row) => row.id.equals(transaction.categoryId!)))
            .getSingleOrNull();
    if (category == null || category.type != transaction.type.name) {
      throw ArgumentError('Kategori tidak sesuai dengan jenis transaksi.');
    }

    await _database
        .into(_database.transactionEntries)
        .insertOnConflictUpdate(
          db.TransactionEntriesCompanion.insert(
            id: transaction.id,
            accountId: transaction.accountId,
            categoryId: Value(transaction.categoryId),
            transferPairId: Value(transaction.transferPairId),
            type: transaction.type.name,
            amount: transaction.amount,
            date: transaction.date.toUtc(),
            merchant: Value(transaction.merchant),
            description: Value(transaction.description),
            source: Value(transaction.source),
            scanId: Value(transaction.scanId),
            createdAt: Value(transaction.createdAt.toUtc()),
            updatedAt: Value(transaction.updatedAt.toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _database.transaction(() async {
      final row = await (_database.select(
        _database.transactionEntries,
      )..where((item) => item.id.equals(id))).getSingleOrNull();
      if (row == null) return;

      if (row.transferPairId case final pairId?) {
        await (_database.delete(
          _database.transactionEntries,
        )..where((item) => item.transferPairId.equals(pairId))).go();
      } else {
        await (_database.delete(
          _database.transactionEntries,
        )..where((item) => item.id.equals(id))).go();
      }
    });
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
  }) async {
    if (fromAccountId == toAccountId) {
      throw ArgumentError('Akun asal dan tujuan harus berbeda.');
    }

    await _database.transaction(() async {
      final accountIds = await (_database.select(
        _database.accounts,
      )..where((row) => row.id.isIn([fromAccountId, toAccountId]))).get();
      if (accountIds.length != 2) {
        throw StateError('Akun transfer tidak ditemukan.');
      }
      final now = DateTime.now().toUtc();
      await _database.batch((batch) {
        batch.insertAll(_database.transactionEntries, [
          db.TransactionEntriesCompanion.insert(
            id: outgoingId,
            accountId: fromAccountId,
            transferPairId: Value(pairId),
            type: FinanceTransactionType.transferOut.name,
            amount: amount,
            date: date.toUtc(),
            description: Value(description),
            source: const Value('transfer'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
          db.TransactionEntriesCompanion.insert(
            id: incomingId,
            accountId: toAccountId,
            transferPairId: Value(pairId),
            type: FinanceTransactionType.transferIn.name,
            amount: amount,
            date: date.toUtc(),
            description: Value(description),
            source: const Value('transfer'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        ]);
      });
    });
  }

  @override
  Future<void> saveSavingGoal(domain.SavingGoal goal) async {
    await _database
        .into(_database.savingGoals)
        .insertOnConflictUpdate(
          db.SavingGoalsCompanion.insert(
            id: goal.id,
            accountId: Value(goal.accountId),
            name: goal.name,
            targetAmount: goal.targetAmount,
            initialAmount: Value(goal.savedAmount),
            savedAmount: Value(goal.savedAmount),
            targetDate: Value(goal.targetDate?.toUtc()),
            isCompleted: Value(goal.isCompleted),
            createdAt: Value(goal.createdAt.toUtc()),
            updatedAt: Value(goal.updatedAt.toUtc()),
          ),
        );
  }

  @override
  Future<void> deleteSavingGoal(String id) async {
    await (_database.delete(
      _database.savingGoals,
    )..where((row) => row.id.equals(id))).go();
  }

  static FinanceAccount _account(db.Account row) {
    return FinanceAccount(
      id: row.id,
      name: row.name,
      type: FinanceAccountType.fromStorage(row.type),
      openingBalance: row.openingBalance,
      currency: row.currency,
      isArchived: row.isArchived,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static FinanceCategory _category(db.Category row) {
    return FinanceCategory(
      id: row.id,
      name: row.name,
      type: FinanceCategoryType.fromStorage(row.type),
      icon: row.icon,
      colorValue: row.colorValue,
      isSystem: row.isSystem,
    );
  }

  static FinanceTransaction _transaction(db.TransactionEntry row) {
    return FinanceTransaction(
      id: row.id,
      accountId: row.accountId,
      categoryId: row.categoryId,
      transferPairId: row.transferPairId,
      type: FinanceTransactionType.fromStorage(row.type),
      amount: row.amount,
      date: row.date,
      merchant: row.merchant,
      description: row.description,
      source: row.source,
      scanId: row.scanId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  static domain.SavingGoal _savingGoal(db.SavingGoal row) {
    return domain.SavingGoal(
      id: row.id,
      accountId: row.accountId,
      name: row.name,
      targetAmount: row.targetAmount,
      savedAmount: row.savedAmount,
      targetDate: row.targetDate,
      isCompleted: row.isCompleted,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
