import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/finance/data/repositories/drift_finance_repository.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart'
    as domain;

void main() {
  late AppDatabase database;
  late DriftFinanceRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftFinanceRepository(database);
    await _seedCategories(database);
  });

  tearDown(() => database.close());

  test('menghitung saldo dan summary bulanan dari ledger', () async {
    final now = DateTime.now();
    await repository.saveAccount(_account('cash', 100000));
    await repository.saveTransaction(
      _transaction(
        id: 'income-1',
        accountId: 'cash',
        categoryId: 'income',
        type: FinanceTransactionType.income,
        amount: 50000,
        date: now,
      ),
    );
    await repository.saveTransaction(
      _transaction(
        id: 'expense-1',
        accountId: 'cash',
        categoryId: 'expense',
        type: FinanceTransactionType.expense,
        amount: 20000,
        date: now,
      ),
    );

    final snapshot = await repository.loadSnapshot(month: now);

    expect(snapshot.accounts.single.balance, 130000);
    expect(snapshot.summary.totalBalance, 130000);
    expect(snapshot.summary.monthlyIncome, 50000);
    expect(snapshot.summary.monthlyExpense, 20000);
  });

  test('transfer membuat dua ledger entry secara atomic', () async {
    final now = DateTime.now();
    await repository.saveAccount(_account('cash', 100000));
    await repository.saveAccount(_account('bank', 50000));

    await repository.transfer(
      outgoingId: 'out',
      incomingId: 'in',
      pairId: 'pair',
      fromAccountId: 'cash',
      toAccountId: 'bank',
      amount: 25000,
      date: now,
    );

    var snapshot = await repository.loadSnapshot(month: now);
    expect(
      snapshot.accounts.firstWhere((item) => item.account.id == 'cash').balance,
      75000,
    );
    expect(
      snapshot.accounts.firstWhere((item) => item.account.id == 'bank').balance,
      75000,
    );
    expect(snapshot.summary.monthlyIncome, 0);
    expect(snapshot.summary.monthlyExpense, 0);

    await repository.deleteTransaction('out');
    snapshot = await repository.loadSnapshot(month: now);
    expect(snapshot.accounts.first.balance, 100000);
    expect(snapshot.transactions, isEmpty);
  });

  test('menyimpan progress target tabungan pada schema v2', () async {
    final now = DateTime.now().toUtc();
    await repository.saveSavingGoal(
      domain.SavingGoal(
        id: 'goal',
        accountId: null,
        name: 'Dana darurat',
        targetAmount: 1000000,
        savedAmount: 250000,
        targetDate: null,
        isCompleted: false,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final snapshot = await repository.loadSnapshot(month: DateTime.now());
    expect(snapshot.savingGoals.single.savedAmount, 250000);
    expect(snapshot.savingGoals.single.progress, 0.25);
  });
}

Future<void> _seedCategories(AppDatabase database) async {
  await database.batch((batch) {
    batch.insertAll(database.categories, [
      CategoriesCompanion.insert(id: 'income', name: 'Gaji', type: 'income'),
      CategoriesCompanion.insert(
        id: 'expense',
        name: 'Makanan',
        type: 'expense',
      ),
    ]);
  });
}

FinanceAccount _account(String id, int openingBalance) {
  final now = DateTime.now().toUtc();
  return FinanceAccount(
    id: id,
    name: id,
    type: FinanceAccountType.cash,
    openingBalance: openingBalance,
    currency: 'IDR',
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  );
}

FinanceTransaction _transaction({
  required String id,
  required String accountId,
  required String categoryId,
  required FinanceTransactionType type,
  required int amount,
  required DateTime date,
}) {
  final now = DateTime.now().toUtc();
  return FinanceTransaction(
    id: id,
    accountId: accountId,
    categoryId: categoryId,
    transferPairId: null,
    type: type,
    amount: amount,
    date: date,
    merchant: null,
    description: null,
    source: 'manual',
    createdAt: now,
    updatedAt: now,
  );
}
