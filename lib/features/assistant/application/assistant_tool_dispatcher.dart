import 'package:intl/intl.dart';
import 'package:nara/core/errors/app_failure.dart';
import 'package:nara/core/formatters/currency_formatter.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/finance/application/finance_service.dart';
import 'package:nara/features/finance/domain/entities/finance_category.dart';
import 'package:nara/features/finance/domain/entities/finance_transaction.dart';
import 'package:nara/features/finance/domain/repositories/finance_repository.dart';
import 'package:nara/features/productivity/application/productivity_service.dart';
import 'package:nara/features/productivity/domain/entities/productivity_entities.dart';
import 'package:nara/features/productivity/domain/repositories/productivity_repository.dart';

class AssistantToolDispatcher {
  AssistantToolDispatcher(
    this._financeRepository,
    this._financeService,
    this._productivityRepository,
    this._productivityService,
  );

  static const allowedTools = AssistantTool.values;
  final FinanceRepository _financeRepository;
  final FinanceService _financeService;
  final ProductivityRepository _productivityRepository;
  final ProductivityService _productivityService;

  Future<Result<String>> execute(AssistantDraft draft) async {
    if (!allowedTools.contains(draft.tool)) {
      return _failure('assistant.tool_denied', 'Tool tidak diizinkan.');
    }
    try {
      return switch (draft.tool) {
        AssistantTool.createTransaction => await _createTransaction(draft),
        AssistantTool.createTask => await _createTask(draft),
        AssistantTool.createSchedule => await _createSchedule(draft),
        AssistantTool.getFinanceSummary => await _financeSummary(),
        AssistantTool.getTasks => await _tasks(),
        AssistantTool.getSchedule => await _schedule(),
      };
    } catch (error) {
      return Failure(
        ToolFailure(
          code: 'assistant.tool_failed',
          message: 'Perintah belum dapat dijalankan.',
          cause: error,
        ),
      );
    }
  }

  Future<Result<String>> _createTransaction(AssistantDraft draft) async {
    final amount = draft.arguments['amount'];
    final typeName = draft.arguments['type'];
    if (amount is! int || amount <= 0 || typeName is! String) {
      return _failure(
        'assistant.arguments_invalid',
        'Data transaksi tidak valid.',
      );
    }
    final type = FinanceTransactionType.values.firstWhere(
      (item) => item.name == typeName,
      orElse: () => FinanceTransactionType.expense,
    );
    final snapshot = await _financeRepository.loadSnapshot(
      month: DateTime.now(),
    );
    if (snapshot.accounts.isEmpty) {
      return _failure(
        'assistant.account_missing',
        'Buat akun Keuangan terlebih dahulu sebelum mencatat transaksi.',
      );
    }
    final categoryType = type == FinanceTransactionType.income
        ? FinanceCategoryType.income
        : FinanceCategoryType.expense;
    final requestedCategory = '${draft.arguments['category'] ?? ''}'
        .toLowerCase();
    final categories = snapshot.categories
        .where((item) => item.type == categoryType)
        .toList();
    if (categories.isEmpty) {
      return _failure(
        'assistant.category_missing',
        'Kategori transaksi belum tersedia.',
      );
    }
    final category = categories.firstWhere(
      (item) => item.name.toLowerCase() == requestedCategory,
      orElse: () => categories.first,
    );
    final result = await _financeService.saveTransaction(
      TransactionInput(
        accountId: snapshot.accounts.first.account.id,
        categoryId: category.id,
        type: type,
        amount: amount,
        date: _date(draft.arguments['date']) ?? DateTime.now(),
        description: draft.arguments['description'] as String?,
      ),
    );
    if (result case Failure(:final failure)) return Failure(failure);
    return Success(
      '${type == FinanceTransactionType.income ? 'Pemasukan' : 'Pengeluaran'} ${CurrencyFormatter.rupiah(amount)} berhasil dicatat pada ${snapshot.accounts.first.account.name}.',
    );
  }

  Future<Result<String>> _createTask(AssistantDraft draft) async {
    final title = draft.arguments['title'];
    if (title is! String || title.trim().isEmpty) {
      return _failure('assistant.arguments_invalid', 'Judul task tidak valid.');
    }
    final priority = TaskPriority.fromStorage(
      '${draft.arguments['priority'] ?? 'medium'}',
    );
    final result = await _productivityService.saveTask(
      TaskInput(
        title: title,
        priority: priority,
        status: TaskStatus.pending,
        dueDate: _date(draft.arguments['dueDate']),
        repeatRule: RepeatRule.none,
      ),
    );
    if (result case Failure(:final failure)) return Failure(failure);
    return Success('Task “$title” berhasil dibuat.');
  }

  Future<Result<String>> _createSchedule(AssistantDraft draft) async {
    final title = draft.arguments['title'];
    final start = _date(draft.arguments['startAt']);
    final end = _date(draft.arguments['endAt']);
    if (title is! String || start == null || end == null) {
      return _failure(
        'assistant.arguments_invalid',
        'Data jadwal tidak valid.',
      );
    }
    final result = await _productivityService.saveSchedule(
      ScheduleInput(
        title: title,
        startAt: start,
        endAt: end,
        repeatRule: RepeatRule.none,
      ),
    );
    if (result case Failure(:final failure)) return Failure(failure);
    return Success(
      'Jadwal “$title” berhasil dibuat untuk ${DateFormat('d MMM, HH:mm', 'id_ID').format(start)}.',
    );
  }

  Future<Result<String>> _financeSummary() async {
    final snapshot = await _financeRepository.loadSnapshot(
      month: DateTime.now(),
    );
    return Success(
      'Ringkasan bulan ini: saldo ${CurrencyFormatter.rupiah(snapshot.summary.totalBalance)}, pemasukan ${CurrencyFormatter.rupiah(snapshot.summary.monthlyIncome)}, dan pengeluaran ${CurrencyFormatter.rupiah(snapshot.summary.monthlyExpense)}.',
    );
  }

  Future<Result<String>> _tasks() async {
    final snapshot = await _productivityRepository.loadSnapshot(
      day: DateTime.now(),
    );
    final active = snapshot.tasks
        .where((item) => !item.isCompleted)
        .take(5)
        .toList();
    if (active.isEmpty) return const Success('Tidak ada task aktif saat ini.');
    return Success(
      'Task aktif (${snapshot.summary.activeTasks}): ${active.map((item) => item.title).join(', ')}.',
    );
  }

  Future<Result<String>> _schedule() async {
    final now = DateTime.now();
    final snapshot = await _productivityRepository.loadSnapshot(day: now);
    final today = snapshot.schedules
        .where((item) {
          final date = item.startAt.toLocal();
          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .take(5)
        .toList();
    if (today.isEmpty) return const Success('Tidak ada jadwal hari ini.');
    return Success(
      'Jadwal hari ini: ${today.map((item) => '${DateFormat('HH:mm').format(item.startAt.toLocal())} ${item.title}').join(', ')}.',
    );
  }

  DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;

  Failure<String> _failure(String code, String message) =>
      Failure(ToolFailure(code: code, message: message));
}
