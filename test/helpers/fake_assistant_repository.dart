import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/assistant/domain/repositories/assistant_repository.dart';

class FakeAssistantRepository implements AssistantRepository {
  final messages = <AssistantMessage>[];
  final audits = <({String tool, String action, String status})>[];

  @override
  Future<List<AssistantMessage>> loadMessages() async => [...messages];

  @override
  Future<void> saveMessage(AssistantMessage message) async {
    messages.add(message);
  }

  @override
  Future<void> clearMessages() async {
    messages.clear();
  }

  @override
  Future<void> saveAudit({
    required String toolName,
    required String action,
    required String status,
    String? targetId,
  }) async {
    audits.add((tool: toolName, action: action, status: status));
  }
}
