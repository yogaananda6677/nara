import 'package:nara/core/errors/app_failure.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/finance/domain/entities/finance_account.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/entities/saving_goal.dart';
import 'package:nara/features/finance/domain/repositories/finance_repository.dart';
import 'package:uuid/uuid.dart';

class AccountInput {
  const AccountInput({
    required this.name,
    required this.type,
    required this.openingBalance,
  });

  final String name;
  final FinanceAccountType type;
  final int openingBalance;
}

class CategoryInput {
  const CategoryInput({required this.name, required this.type});

  final String name;
  final FinanceCategoryType type;
}

class TransactionInput {
  const TransactionInput({
    required this.accountId,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    this.description,
    this.merchant,
    this.source = 'manual',
    this.scanId,
  });

  final String accountId;
  final String categoryId;
  final FinanceTransactionType type;
  final int amount;
  final DateTime date;
  final String? description;
  final String? merchant;
  final String source;
  final String? scanId;
}

class TransferInput {
  const TransferInput({
    required this.fromAccountId,
    required this.toAccountId,
    required this.amount,
    required this.date,
    this.description,
  });

  final String fromAccountId;
  final String toAccountId;
  final int amount;
  final DateTime date;
  final String? description;
}

class SavingGoalInput {
  const SavingGoalInput({
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.accountId,
    this.targetDate,
  });

  final String name;
  final int targetAmount;
  final int savedAmount;
  final String? accountId;
  final DateTime? targetDate;
}

class FinanceService {
  FinanceService(this._repository, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  final FinanceRepository _repository;
  final Uuid _uuid;

  Future<Result<void>> saveAccount(
    AccountInput input, {
    FinanceAccount? existing,
  }) async {
    final name = input.name.trim();
    if (name.isEmpty || name.length > 100 || input.openingBalance < 0) {
      return _validation(
        'account.invalid',
        'Periksa nama dan saldo awal akun.',
      );
    }
    final now = DateTime.now().toUtc();
    return _guard(
      () => _repository.saveAccount(
        FinanceAccount(
          id: existing?.id ?? _uuid.v4(),
          name: name,
          type: input.type,
          openingBalance: input.openingBalance,
          currency: existing?.currency ?? 'IDR',
          isArchived: false,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
      'account.save_failed',
      'Akun belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteAccount(String id) {
    return _guard(
      () => _repository.deleteAccount(id),
      'account.delete_failed',
      'Akun belum dapat dihapus atau diarsipkan.',
    );
  }

  Future<Result<void>> saveCategory(
    CategoryInput input, {
    FinanceCategory? existing,
  }) async {
    final name = input.name.trim();
    if (name.isEmpty || name.length > 100) {
      return _validation('category.invalid', 'Nama kategori wajib diisi.');
    }
    return _guard(
      () => _repository.saveCategory(
        FinanceCategory(
          id: existing?.id ?? _uuid.v4(),
          name: name,
          type: input.type,
          icon: existing?.icon ?? 'label',
          colorValue: existing?.colorValue,
          isSystem: existing?.isSystem ?? false,
        ),
      ),
      'category.save_failed',
      'Kategori belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteCategory(String id) {
    return _guard(
      () => _repository.deleteCategory(id),
      'category.delete_failed',
      'Kategori belum dapat dihapus.',
    );
  }

  Future<Result<void>> saveTransaction(
    TransactionInput input, {
    FinanceTransaction? existing,
  }) async {
    if (input.amount <= 0 ||
        input.accountId.isEmpty ||
        input.categoryId.isEmpty) {
      return _validation(
        'transaction.invalid',
        'Nominal, akun, dan kategori wajib diisi.',
      );
    }
    if (input.type.isTransfer) {
      return _validation(
        'transaction.type_invalid',
        'Gunakan menu transfer untuk memindahkan saldo.',
      );
    }
    final now = DateTime.now().toUtc();
    return _guard(
      () => _repository.saveTransaction(
        FinanceTransaction(
          id: existing?.id ?? _uuid.v4(),
          accountId: input.accountId,
          categoryId: input.categoryId,
          transferPairId: null,
          type: input.type,
          amount: input.amount,
          date: input.date.toUtc(),
          merchant: _nullable(input.merchant),
          description: _nullable(input.description),
          source: existing?.source ?? input.source,
          scanId: existing?.scanId ?? input.scanId,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
      'transaction.save_failed',
      'Transaksi belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteTransaction(String id) {
    return _guard(
      () => _repository.deleteTransaction(id),
      'transaction.delete_failed',
      'Transaksi belum dapat dihapus.',
    );
  }

  Future<Result<void>> transfer(TransferInput input) async {
    if (input.amount <= 0 ||
        input.fromAccountId.isEmpty ||
        input.toAccountId.isEmpty ||
        input.fromAccountId == input.toAccountId) {
      return _validation(
        'transfer.invalid',
        'Pilih dua akun berbeda dan isi nominal transfer.',
      );
    }
    return _guard(
      () => _repository.transfer(
        outgoingId: _uuid.v4(),
        incomingId: _uuid.v4(),
        pairId: _uuid.v4(),
        fromAccountId: input.fromAccountId,
        toAccountId: input.toAccountId,
        amount: input.amount,
        date: input.date,
        description: _nullable(input.description),
      ),
      'transfer.failed',
      'Transfer internal belum dapat disimpan.',
    );
  }

  Future<Result<void>> saveSavingGoal(
    SavingGoalInput input, {
    SavingGoal? existing,
  }) async {
    final name = input.name.trim();
    if (name.isEmpty ||
        input.targetAmount <= 0 ||
        input.savedAmount < 0 ||
        input.savedAmount > input.targetAmount) {
      return _validation(
        'saving.invalid',
        'Periksa nama, target, dan dana terkumpul.',
      );
    }
    final now = DateTime.now().toUtc();
    return _guard(
      () => _repository.saveSavingGoal(
        SavingGoal(
          id: existing?.id ?? _uuid.v4(),
          accountId: input.accountId,
          name: name,
          targetAmount: input.targetAmount,
          savedAmount: input.savedAmount,
          targetDate: input.targetDate?.toUtc(),
          isCompleted: input.savedAmount >= input.targetAmount,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
        ),
      ),
      'saving.save_failed',
      'Target tabungan belum dapat disimpan.',
    );
  }

  Future<Result<void>> deleteSavingGoal(String id) {
    return _guard(
      () => _repository.deleteSavingGoal(id),
      'saving.delete_failed',
      'Target tabungan belum dapat dihapus.',
    );
  }

  Future<Result<void>> _guard(
    Future<void> Function() action,
    String code,
    String message,
  ) async {
    try {
      await action();
      return const Success<void>(null);
    } catch (error) {
      return Failure(
        DatabaseFailure(code: code, message: message, cause: error),
      );
    }
  }

  static Result<void> _validation(String code, String message) {
    return Failure(ValidationFailure(code: code, message: message));
  }

  static String? _nullable(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
