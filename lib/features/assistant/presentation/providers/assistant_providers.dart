import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/assistant/application/assistant_tool_dispatcher.dart';
import 'package:nara/features/assistant/application/local_command_parser.dart';
import 'package:nara/features/assistant/data/repositories/drift_assistant_repository.dart';
import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:nara/features/finance/presentation/providers/finance_providers.dart';
import 'package:nara/features/productivity/presentation/providers/productivity_providers.dart';
import 'package:uuid/uuid.dart';

class AssistantState {
  const AssistantState({
    required this.messages,
    this.pendingDraft,
    this.isProcessing = false,
  });

  final List<AssistantMessage> messages;
  final AssistantDraft? pendingDraft;
  final bool isProcessing;

  AssistantState copyWith({
    List<AssistantMessage>? messages,
    AssistantDraft? pendingDraft,
    bool clearPending = false,
    bool? isProcessing,
  }) => AssistantState(
    messages: messages ?? this.messages,
    pendingDraft: clearPending ? null : pendingDraft ?? this.pendingDraft,
    isProcessing: isProcessing ?? this.isProcessing,
  );
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) {
  return DriftAssistantRepository(ref.watch(appDatabaseProvider));
});

final localCommandParserProvider = Provider<LocalCommandParser>((ref) {
  return const LocalCommandParser();
});

final assistantToolDispatcherProvider = Provider<AssistantToolDispatcher>((
  ref,
) {
  return AssistantToolDispatcher(
    ref.watch(financeRepositoryProvider),
    ref.watch(financeServiceProvider),
    ref.watch(productivityRepositoryProvider),
    ref.watch(productivityServiceProvider),
  );
});

final assistantControllerProvider =
    AsyncNotifierProvider<AssistantController, AssistantState>(
      AssistantController.new,
    );

class AssistantController extends AsyncNotifier<AssistantState> {
  static const _uuid = Uuid();

  @override
  Future<AssistantState> build() async {
    final repository = ref.watch(assistantRepositoryProvider);
    var messages = await repository.loadMessages();
    if (messages.isEmpty) {
      final welcome = _message(
        AssistantRole.assistant,
        'Halo! Saya Nara, asisten offline Anda. Saya dapat mencatat transaksi, membuat task atau jadwal, dan membaca ringkasan lokal.',
        intent: AssistantIntent.conversation,
      );
      await repository.saveMessage(welcome);
      messages = [welcome];
    }
    return AssistantState(messages: messages);
  }

  Future<void> submit(String text) async {
    final current = state.value;
    if (current == null || current.isProcessing) return;
    final normalized = text.trim();
    if (normalized.isEmpty) return;
    final userMessage = _message(
      AssistantRole.user,
      normalized,
      intent: AssistantIntent.command,
    );
    await _append(userMessage);
    final afterUser = state.value!;
    if (afterUser.pendingDraft != null) {
      await _append(
        _message(
          AssistantRole.assistant,
          'Masih ada tindakan yang menunggu konfirmasi. Pilih Konfirmasi, Ubah, atau Batal terlebih dahulu.',
          intent: AssistantIntent.conversation,
        ),
      );
      return;
    }

    final outcome = ref.read(localCommandParserProvider).parse(normalized);
    if (outcome.response != null) {
      if (outcome.isSafetyRejection) {
        await ref
            .read(assistantRepositoryProvider)
            .saveAudit(
              toolName: 'local_parser',
              action: 'reject_bypass',
              status: 'rejected',
            );
      }
      await _append(
        _message(
          AssistantRole.assistant,
          outcome.response!,
          intent: outcome.isSafetyRejection
              ? AssistantIntent.unknown
              : AssistantIntent.conversation,
        ),
      );
      return;
    }

    final draft = outcome.draft!;
    if (draft.tool.requiresConfirmation) {
      await ref
          .read(assistantRepositoryProvider)
          .saveAudit(
            toolName: draft.tool.storageName,
            action: 'preview',
            status: 'pending',
          );
      state = AsyncData(state.value!.copyWith(pendingDraft: draft));
      await _append(
        _message(
          AssistantRole.assistant,
          'Periksa preview berikut. Data belum disimpan sampai Anda menekan Konfirmasi.',
          intent: AssistantIntent.command,
          toolName: draft.tool.storageName,
        ),
      );
      return;
    }
    await _execute(draft);
  }

  void updatePending(Map<String, Object?> arguments) {
    final current = state.value;
    final draft = current?.pendingDraft;
    if (current == null || draft == null || current.isProcessing) return;
    state = AsyncData(
      current.copyWith(pendingDraft: draft.copyWith(arguments: arguments)),
    );
  }

  Future<void> confirm() async {
    final draft = state.value?.pendingDraft;
    if (draft == null) return;
    await _execute(draft);
  }

  Future<void> cancel() async {
    final current = state.value;
    final draft = current?.pendingDraft;
    if (current == null || draft == null || current.isProcessing) return;
    await ref
        .read(assistantRepositoryProvider)
        .saveAudit(
          toolName: draft.tool.storageName,
          action: 'cancel',
          status: 'cancelled',
        );
    state = AsyncData(current.copyWith(clearPending: true));
    await _append(
      _message(
        AssistantRole.assistant,
        'Tindakan dibatalkan. Tidak ada data yang disimpan.',
        intent: AssistantIntent.command,
        toolName: draft.tool.storageName,
      ),
    );
  }

  Future<void> clearHistory() async {
    await ref.read(assistantRepositoryProvider).clearMessages();
    state = const AsyncData(AssistantState(messages: []));
    ref.invalidateSelf();
  }

  Future<void> _execute(AssistantDraft draft) async {
    final current = state.value;
    if (current == null || current.isProcessing) return;
    state = AsyncData(current.copyWith(isProcessing: true));
    final result = await ref
        .read(assistantToolDispatcherProvider)
        .execute(draft);
    if (result case Failure(:final failure)) {
      await ref
          .read(assistantRepositoryProvider)
          .saveAudit(
            toolName: draft.tool.storageName,
            action: draft.tool.requiresConfirmation ? 'confirm' : 'read',
            status: 'failed',
          );
      state = AsyncData(
        state.value!.copyWith(isProcessing: false, clearPending: true),
      );
      await _append(
        _message(
          AssistantRole.assistant,
          failure.message,
          intent: AssistantIntent.command,
          toolName: draft.tool.storageName,
        ),
      );
      return;
    }
    final response = (result as Success<String>).value;
    await ref
        .read(assistantRepositoryProvider)
        .saveAudit(
          toolName: draft.tool.storageName,
          action: draft.tool.requiresConfirmation ? 'confirm' : 'read',
          status: 'success',
        );
    state = AsyncData(
      state.value!.copyWith(isProcessing: false, clearPending: true),
    );
    if (draft.tool.requiresConfirmation) {
      ref.invalidate(financeControllerProvider);
      ref.invalidate(productivityControllerProvider);
    }
    await _append(
      _message(
        AssistantRole.assistant,
        response,
        intent: draft.tool.requiresConfirmation
            ? AssistantIntent.command
            : AssistantIntent.question,
        toolName: draft.tool.storageName,
      ),
    );
  }

  Future<void> _append(AssistantMessage message) async {
    await ref.read(assistantRepositoryProvider).saveMessage(message);
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(messages: [...current.messages, message]),
    );
  }

  static AssistantMessage _message(
    AssistantRole role,
    String content, {
    AssistantIntent? intent,
    String? toolName,
  }) => AssistantMessage(
    id: _uuid.v4(),
    role: role,
    content: content,
    intent: intent,
    toolName: toolName,
    createdAt: DateTime.now().toUtc(),
  );
}
