import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';

class FinanceSummary {
  const FinanceSummary({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
}

class FinanceSnapshot {
  const FinanceSnapshot({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.savingGoals,
    required this.summary,
  });

  const FinanceSnapshot.empty()
    : accounts = const [],
      categories = const [],
      transactions = const [],
      savingGoals = const [],
      summary = const FinanceSummary(
        totalBalance: 0,
        monthlyIncome: 0,
        monthlyExpense: 0,
      );

  final List<AccountBalance> accounts;
  final List<FinanceCategory> categories;
  final List<FinanceTransaction> transactions;
  final List<SavingGoal> savingGoals;
  final FinanceSummary summary;
}
