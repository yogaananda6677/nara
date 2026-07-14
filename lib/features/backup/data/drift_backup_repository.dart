import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/backup/application/backup_codec.dart';

class DriftBackupRepository {
  DriftBackupRepository(this._database);

  static const snapshotFormat = 'nara.logical.snapshot';
  static const snapshotVersion = 1;
  static const _securitySettingKeys = {
    'app_lock_enabled',
    'biometric_enabled',
    'lock_timeout_seconds',
  };

  final AppDatabase _database;

  Future<Map<String, Object?>> createSnapshot() async {
    if (!await _database.integrityCheck()) {
      throw const BackupException(
        'Database lokal gagal pemeriksaan integritas.',
      );
    }
    final settings = await _database.select(_database.appSettings).get();
    return <String, Object?>{
      'format': snapshotFormat,
      'version': snapshotVersion,
      'schemaVersion': _database.schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'tables': <String, Object?>{
        'profiles': await _jsonRows(_database.select(_database.profiles).get()),
        'accounts': await _jsonRows(_database.select(_database.accounts).get()),
        'categories': await _jsonRows(
          _database.select(_database.categories).get(),
        ),
        'transactionEntries': await _jsonRows(
          _database.select(_database.transactionEntries).get(),
        ),
        'savingGoals': await _jsonRows(
          _database.select(_database.savingGoals).get(),
        ),
        'tasks': await _jsonRows(_database.select(_database.tasks).get()),
        'schedules': await _jsonRows(
          _database.select(_database.schedules).get(),
        ),
        'activityLogs': await _jsonRows(
          _database.select(_database.activityLogs).get(),
        ),
        'reminders': await _jsonRows(
          _database.select(_database.reminders).get(),
        ),
        'toolAudits': await _jsonRows(
          _database.select(_database.toolAudits).get(),
        ),
        'assistantConversations': await _jsonRows(
          _database.select(_database.assistantConversations).get(),
        ),
        'assistantMessages': await _jsonRows(
          _database.select(_database.assistantMessages).get(),
        ),
        'smartScans': await _jsonRows(
          _database.select(_database.smartScans).get(),
        ),
        'appSettings': settings
            .where((row) => !_securitySettingKeys.contains(row.key))
            .map((row) => row.toJson())
            .toList(),
      },
    };
  }

  Future<void> restoreSnapshot(Map<String, Object?> snapshot) async {
    if (snapshot['format'] != snapshotFormat ||
        snapshot['version'] != snapshotVersion) {
      throw const BackupException('Versi isi backup tidak didukung.');
    }
    if ((snapshot['schemaVersion'] as int? ?? 0) > _database.schemaVersion) {
      throw const BackupException(
        'Backup dibuat oleh versi Nara yang lebih baru.',
      );
    }
    final rawTables = snapshot['tables'];
    if (rawTables is! Map) {
      throw const BackupException('Daftar data backup tidak valid.');
    }
    final tables = Map<String, dynamic>.from(rawTables);

    // Parse every row before the transaction. Invalid JSON cannot touch live data.
    final profiles = _parse(tables, 'profiles', Profile.fromJson);
    final accounts = _parse(tables, 'accounts', Account.fromJson);
    final categories = _parse(tables, 'categories', Category.fromJson);
    final transactions = _parse(
      tables,
      'transactionEntries',
      TransactionEntry.fromJson,
    );
    final goals = _parse(tables, 'savingGoals', SavingGoal.fromJson);
    final tasks = _parse(tables, 'tasks', Task.fromJson);
    final schedules = _parse(tables, 'schedules', Schedule.fromJson);
    final logs = _parse(tables, 'activityLogs', ActivityLog.fromJson);
    final reminders = _parse(tables, 'reminders', Reminder.fromJson);
    final audits = _parse(tables, 'toolAudits', ToolAudit.fromJson);
    final conversations = _parse(
      tables,
      'assistantConversations',
      AssistantConversation.fromJson,
    );
    final messages = _parse(
      tables,
      'assistantMessages',
      AssistantMessage.fromJson,
    );
    final scans = _parse(tables, 'smartScans', SmartScan.fromJson);
    final settings = _parse(
      tables,
      'appSettings',
      AppSetting.fromJson,
    ).where((row) => !_securitySettingKeys.contains(row.key)).toList();
    final now = DateTime.now().toUtc();
    settings.addAll([
      AppSetting(key: 'app_lock_enabled', value: 'false', updatedAt: now),
      AppSetting(key: 'biometric_enabled', value: 'false', updatedAt: now),
      AppSetting(key: 'lock_timeout_seconds', value: '30', updatedAt: now),
    ]);

    await _database.transaction(() async {
      await _database.customStatement('PRAGMA defer_foreign_keys = ON');
      await _database.batch((batch) {
        batch.deleteAll(_database.assistantMessages);
        batch.deleteAll(_database.assistantConversations);
        batch.deleteAll(_database.reminders);
        batch.deleteAll(_database.toolAudits);
        batch.deleteAll(_database.activityLogs);
        batch.deleteAll(_database.tasks);
        batch.deleteAll(_database.schedules);
        batch.deleteAll(_database.transactionEntries);
        batch.deleteAll(_database.savingGoals);
        batch.deleteAll(_database.smartScans);
        batch.deleteAll(_database.accounts);
        batch.deleteAll(_database.categories);
        batch.deleteAll(_database.profiles);
        batch.deleteAll(_database.appSettings);
        batch.deleteAll(_database.securityCredentials);

        batch.insertAll(_database.profiles, profiles);
        batch.insertAll(_database.accounts, accounts);
        batch.insertAll(_database.categories, categories);
        batch.insertAll(_database.savingGoals, goals);
        batch.insertAll(_database.transactionEntries, transactions);
        batch.insertAll(_database.tasks, tasks);
        batch.insertAll(_database.schedules, schedules);
        batch.insertAll(_database.activityLogs, logs);
        batch.insertAll(_database.reminders, reminders);
        batch.insertAll(_database.toolAudits, audits);
        batch.insertAll(_database.assistantConversations, conversations);
        batch.insertAll(_database.assistantMessages, messages);
        batch.insertAll(_database.smartScans, scans);
        batch.insertAll(_database.appSettings, settings);
      });
      if (!await _database.integrityCheck()) {
        throw const BackupException(
          'Restore dibatalkan karena pemeriksaan integritas gagal.',
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> _jsonRows<T extends DataClass>(
    Future<List<T>> rows,
  ) async => (await rows).map((row) => row.toJson()).toList();

  List<T> _parse<T>(
    Map<String, dynamic> tables,
    String key,
    T Function(Map<String, Object?>) decode,
  ) {
    final rows = tables[key];
    if (rows is! List) throw BackupException('Tabel $key tidak valid.');
    try {
      return rows
          .map((row) => decode(Map<String, Object?>.from(row as Map)))
          .toList();
    } catch (_) {
      throw BackupException('Data pada tabel $key rusak atau tidak lengkap.');
    }
  }
}
