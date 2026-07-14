import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';

abstract interface class AssistantRepository {
  Future<List<AssistantMessage>> loadMessages();
  Future<void> saveMessage(AssistantMessage message);
  Future<void> clearMessages();
  Future<void> saveAudit({
    required String toolName,
    required String action,
    required String status,
    String? targetId,
  });
}
