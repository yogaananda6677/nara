import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/data/repositories/drift_finance_repository.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_snapshot.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';
import 'package:nara/features/finance/domain/repositories/finance_repository.dart';

class FinanceState {
  const FinanceState({
    required this.snapshot,
    required this.month,
    this.search = '',
    this.filter = TransactionFilter.all,
    this.isMutating = false,
    this.message,
  });

  final FinanceSnapshot snapshot;
  final DateTime month;
  final String search;
  final TransactionFilter filter;
  final bool isMutating;
  final String? message;

  FinanceState copyWith({
    FinanceSnapshot? snapshot,
    DateTime? month,
    String? search,
    TransactionFilter? filter,
    bool? isMutating,
    String? message,
    bool clearMessage = false,
  }) {
    return FinanceState(
      snapshot: snapshot ?? this.snapshot,
      month: month ?? this.month,
      search: search ?? this.search,
      filter: filter ?? this.filter,
      isMutating: isMutating ?? this.isMutating,
      message: clearMessage ? null : message ?? this.message,
    );
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return DriftFinanceRepository(ref.watch(appDatabaseProvider));
});

final financeServiceProvider = Provider<FinanceService>((ref) {
  return FinanceService(ref.watch(financeRepositoryProvider));
});

final financeControllerProvider =
    AsyncNotifierProvider<FinanceController, FinanceState>(
      FinanceController.new,
    );

class FinanceController extends AsyncNotifier<FinanceState> {
  var _loadRevision = 0;

  @override
  Future<FinanceState> build() async {
    final month = DateTime.now();
    final snapshot = await ref
        .watch(financeRepositoryProvider)
        .loadSnapshot(month: month);
    return FinanceState(snapshot: snapshot, month: month);
  }

  Future<void> refresh() async {
    final current = state.value;
    if (current == null) return;
    final revision = ++_loadRevision;
    final snapshot = await ref
        .read(financeRepositoryProvider)
        .loadSnapshot(
          month: current.month,
          search: current.search,
          filter: current.filter,
        );
    if (revision != _loadRevision) return;
    state = AsyncData(
      current.copyWith(
        snapshot: snapshot,
        isMutating: false,
        clearMessage: true,
      ),
    );
  }

  Future<void> setSearch(String search) => _reload(search: search);

  Future<void> setFilter(TransactionFilter filter) => _reload(filter: filter);

  Future<void> changeMonth(int offset) async {
    final current = state.value;
    if (current == null) return;
    final month = DateTime(current.month.year, current.month.month + offset);
    await _reload(month: month);
  }

  Future<void> _reload({
    DateTime? month,
    String? search,
    TransactionFilter? filter,
  }) async {
    final current = state.value;
    if (current == null) return;
    final next = current.copyWith(
      month: month,
      search: search,
      filter: filter,
      clearMessage: true,
    );
    final revision = ++_loadRevision;
    final snapshot = await ref
        .read(financeRepositoryProvider)
        .loadSnapshot(
          month: next.month,
          search: next.search,
          filter: next.filter,
        );
    if (revision != _loadRevision) return;
    state = AsyncData(next.copyWith(snapshot: snapshot));
  }

  Future<bool> saveAccount(AccountInput input, {FinanceAccount? existing}) {
    return _execute(
      ref.read(financeServiceProvider).saveAccount(input, existing: existing),
    );
  }

  Future<bool> deleteAccount(String id) {
    return _execute(ref.read(financeServiceProvider).deleteAccount(id));
  }

  Future<bool> saveCategory(CategoryInput input, {FinanceCategory? existing}) {
    return _execute(
      ref.read(financeServiceProvider).saveCategory(input, existing: existing),
    );
  }

  Future<bool> deleteCategory(String id) {
    return _execute(ref.read(financeServiceProvider).deleteCategory(id));
  }

  Future<bool> saveTransaction(
    TransactionInput input, {
    FinanceTransaction? existing,
  }) {
    return _execute(
      ref
          .read(financeServiceProvider)
          .saveTransaction(input, existing: existing),
    );
  }

  Future<bool> deleteTransaction(String id) {
    return _execute(ref.read(financeServiceProvider).deleteTransaction(id));
  }

  Future<bool> transfer(TransferInput input) {
    return _execute(ref.read(financeServiceProvider).transfer(input));
  }

  Future<bool> saveSavingGoal(SavingGoalInput input, {SavingGoal? existing}) {
    return _execute(
      ref
          .read(financeServiceProvider)
          .saveSavingGoal(input, existing: existing),
    );
  }

  Future<bool> deleteSavingGoal(String id) {
    return _execute(ref.read(financeServiceProvider).deleteSavingGoal(id));
  }

  Future<bool> _execute(Future<Result<void>> operation) async {
    final current = state.value;
    if (current == null) return false;
    state = AsyncData(current.copyWith(isMutating: true, clearMessage: true));
    final result = await operation;
    if (result case Failure(:final failure)) {
      state = AsyncData(
        current.copyWith(isMutating: false, message: failure.message),
      );
      return false;
    }
    await refresh();
    return true;
  }
}
