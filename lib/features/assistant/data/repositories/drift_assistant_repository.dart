import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart' as db;
import 'package:nara/features/assistant/domain/entities/assistant_entities.dart';
import 'package:nara/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:uuid/uuid.dart';

class DriftAssistantRepository implements AssistantRepository {
  DriftAssistantRepository(this._database, {Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  static const conversationId = 'local-assistant';
  final db.AppDatabase _database;
  final Uuid _uuid;

  Future<void> _ensureConversation() async {
    await _database
        .into(_database.assistantConversations)
        .insert(
          db.AssistantConversationsCompanion.insert(
            id: conversationId,
            title: 'Asisten Nara',
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  @override
  Future<List<AssistantMessage>> loadMessages() async {
    await _ensureConversation();
    final rows =
        await (_database.select(_database.assistantMessages)
              ..where((row) => row.conversationId.equals(conversationId))
              ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
            .get();
    return rows
        .map(
          (row) => AssistantMessage(
            id: row.id,
            role: row.role == 'user'
                ? AssistantRole.user
                : AssistantRole.assistant,
            content: row.content,
            intent: row.intent == null
                ? null
                : AssistantIntent.values.firstWhere(
                    (item) => item.name == row.intent,
                    orElse: () => AssistantIntent.unknown,
                  ),
            toolName: row.toolName,
            createdAt: row.createdAt,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveMessage(AssistantMessage message) async {
    await _ensureConversation();
    await _database
        .into(_database.assistantMessages)
        .insert(
          db.AssistantMessagesCompanion.insert(
            id: message.id,
            conversationId: conversationId,
            role: message.role.name,
            content: message.content,
            intent: Value(message.intent?.name),
            toolName: Value(message.toolName),
            createdAt: Value(message.createdAt.toUtc()),
          ),
        );
    await (_database.update(
      _database.assistantConversations,
    )..where((row) => row.id.equals(conversationId))).write(
      db.AssistantConversationsCompanion(
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  @override
  Future<void> clearMessages() async {
    await (_database.delete(
      _database.assistantMessages,
    )..where((row) => row.conversationId.equals(conversationId))).go();
  }

  @override
  Future<void> saveAudit({
    required String toolName,
    required String action,
    required String status,
    String? targetId,
  }) async {
    await _database
        .into(_database.toolAudits)
        .insert(
          db.ToolAuditsCompanion.insert(
            id: _uuid.v4(),
            toolName: toolName,
            action: action,
            targetId: Value(targetId),
            status: status,
          ),
        );
  }
}
