enum AssistantRole { user, assistant }

enum AssistantIntent { command, question, conversation, unknown }

enum AssistantTool {
  createTransaction,
  createTask,
  createSchedule,
  getFinanceSummary,
  getTasks,
  getSchedule;

  String get storageName => switch (this) {
    createTransaction => 'create_transaction',
    createTask => 'create_task',
    createSchedule => 'create_schedule',
    getFinanceSummary => 'get_finance_summary',
    getTasks => 'get_tasks',
    getSchedule => 'get_schedule',
  };

  bool get requiresConfirmation => switch (this) {
    createTransaction || createTask || createSchedule => true,
    _ => false,
  };
}

class AssistantMessage {
  const AssistantMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.intent,
    this.toolName,
  });

  final String id;
  final AssistantRole role;
  final String content;
  final AssistantIntent? intent;
  final String? toolName;
  final DateTime createdAt;
}

class AssistantDraft {
  const AssistantDraft({
    required this.tool,
    required this.arguments,
    required this.originalText,
  });

  final AssistantTool tool;
  final Map<String, Object?> arguments;
  final String originalText;

  AssistantDraft copyWith({Map<String, Object?>? arguments}) => AssistantDraft(
    tool: tool,
    arguments: arguments ?? this.arguments,
    originalText: originalText,
  );
}

class ParseOutcome {
  const ParseOutcome._({
    this.draft,
    this.response,
    this.isSafetyRejection = false,
  });

  const ParseOutcome.draft(AssistantDraft value) : this._(draft: value);

  const ParseOutcome.response(String value, {bool safety = false})
    : this._(response: value, isSafetyRejection: safety);

  final AssistantDraft? draft;
  final String? response;
  final bool isSafetyRejection;
}
