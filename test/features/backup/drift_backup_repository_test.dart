import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/backup/application/backup_codec.dart';
import 'package:nara/features/backup/data/drift_backup_repository.dart';
import 'package:nara/features/foundation/data/repositories/drift_foundation_repository.dart';

void main() {
  late AppDatabase database;
  late DriftBackupRepository repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftBackupRepository(database);
    await DriftFoundationRepository(database).initialize();
    final now = DateTime.utc(2026, 7, 14);
    await database
        .into(database.profiles)
        .insert(
          ProfilesCompanion.insert(
            id: 'me',
            name: 'Yoga',
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
    await database
        .into(database.securityCredentials)
        .insert(
          SecurityCredentialsCompanion.insert(
            id: 'primary',
            pinHash: 'hash-rahasia',
            pinSalt: 'salt-rahasia',
            kdfIterations: 210000,
          ),
        );
  });

  tearDown(() => database.close());

  test('restore atomik memulihkan data tanpa membawa kredensial', () async {
    final snapshot = await repository.createSnapshot();
    expect(snapshot.toString(), isNot(contains('hash-rahasia')));
    expect(snapshot.toString(), isNot(contains('salt-rahasia')));

    await (database.update(database.profiles)
          ..where((row) => row.id.equals('me')))
        .write(const ProfilesCompanion(name: Value('Berubah')));
    await repository.restoreSnapshot(snapshot);

    expect((await database.select(database.profiles).getSingle()).name, 'Yoga');
    expect(await database.select(database.securityCredentials).get(), isEmpty);
    final settings = {
      for (final row in await database.select(database.appSettings).get())
        row.key: row.value,
    };
    expect(settings['app_lock_enabled'], 'false');
    expect(settings['biometric_enabled'], 'false');
  });

  test('snapshot rusak ditolak sebelum data aktif berubah', () async {
    final snapshot = await repository.createSnapshot();
    final tables = Map<String, Object?>.from(snapshot['tables']! as Map);
    tables['profiles'] = [
      {'broken': true},
    ];
    final damaged = Map<String, Object?>.from(snapshot)..['tables'] = tables;

    expect(
      () => repository.restoreSnapshot(damaged),
      throwsA(isA<BackupException>()),
    );
    expect((await database.select(database.profiles).getSingle()).name, 'Yoga');
  });
}
