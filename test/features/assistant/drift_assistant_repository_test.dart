import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/assistant/data/repositories/drift_assistant_repository.dart';
import 'package:nara/features/assistant/domain/entities/assistant_entities.dart'
    as domain;

void main() {
  late AppDatabase database;
  late DriftAssistantRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAssistantRepository(database);
  });

  tearDown(() => database.close());

  test('riwayat chat Fase 4 tetap tersimpan pada schema v5', () async {
    final message = domain.AssistantMessage(
      id: 'message-1',
      role: domain.AssistantRole.user,
      content: 'Buat task laporan',
      intent: domain.AssistantIntent.command,
      createdAt: DateTime.utc(2026, 7, 14),
    );

    await repository.saveMessage(message);
    final stored = await repository.loadMessages();

    expect(database.schemaVersion, 5);
    expect(stored.single.content, message.content);
    expect(stored.single.role, domain.AssistantRole.user);
  });

  test('mencatat audit tool dan status konfirmasi', () async {
    await repository.saveAudit(
      toolName: 'create_task',
      action: 'confirm',
      status: 'success',
    );

    final audits = await database.select(database.toolAudits).get();
    expect(audits.single.toolName, 'create_task');
    expect(audits.single.status, 'success');
  });

  test('hapus riwayat tidak menghapus audit', () async {
    await repository.saveMessage(
      domain.AssistantMessage(
        id: 'message-1',
        role: domain.AssistantRole.assistant,
        content: 'Halo',
        createdAt: DateTime.now(),
      ),
    );
    await repository.saveAudit(
      toolName: 'local_parser',
      action: 'reject_bypass',
      status: 'rejected',
    );

    await repository.clearMessages();

    expect(await repository.loadMessages(), isEmpty);
    expect(await database.select(database.toolAudits).get(), hasLength(1));
  });
}
