import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';

abstract interface class FinanceRepository {
  Future<FinanceSnapshot> loadSnapshot({
    required DateTime month,
    String search = '',
    TransactionFilter filter = TransactionFilter.all,
  });

  Future<void> saveAccount(FinanceAccount account);

  Future<void> deleteAccount(String id);

  Future<void> saveCategory(FinanceCategory category);

  Future<void> deleteCategory(String id);

  Future<void> saveTransaction(FinanceTransaction transaction);

  Future<void> deleteTransaction(String id);

  Future<void> transfer({
    required String outgoingId,
    required String incomingId,
    required String pairId,
    required String fromAccountId,
    required String toAccountId,
    required int amount,
    required DateTime date,
    String? description,
  });

  Future<void> saveSavingGoal(SavingGoal goal);

  Future<void> deleteSavingGoal(String id);
}
