import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/foundation/data/repositories/drift_foundation_repository.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('schema database Fase 6 berada pada versi 6', () {
    expect(database.schemaVersion, 6);
  });

  test('dapat menyimpan account lokal', () async {
    final account = AccountsCompanion.insert(id: 'cash', name: 'Tunai');

    await database.into(database.accounts).insert(account);

    final stored = await database.select(database.accounts).getSingle();
    expect(stored.name, 'Tunai');
    expect(stored.currency, 'IDR');
    expect(stored.openingBalance, 0);
  });

  test('foundation seed idempotent dan menyediakan default V1', () async {
    final repository = DriftFoundationRepository(database);

    await repository.initialize();
    await repository.initialize();

    final categories = await database.select(database.categories).get();
    final settings = await database.select(database.appSettings).get();
    expect(categories, hasLength(12));
    expect(categories.where((item) => item.type == 'expense'), hasLength(8));
    expect(categories.where((item) => item.type == 'income'), hasLength(4));
    expect(settings, hasLength(7));

    final preferences = await repository.getPreferences();
    expect(preferences.language, 'id');
    expect(preferences.currency, 'IDR');
    expect(preferences.timezone, 'Asia/Jakarta');
    expect(preferences.theme, ThemePreference.system);
    expect(preferences.appLockEnabled, isFalse);
    expect(preferences.biometricEnabled, isFalse);
    expect(preferences.lockTimeoutSeconds, 30);
  });

  test('pemeriksaan integritas database berhasil', () async {
    expect(await database.integrityCheck(), isTrue);
  });

  test(
    'profile dan settings tetap dapat dibaca dari repository baru',
    () async {
      final repository = DriftFoundationRepository(database);
      await repository.initialize();
      final now = DateTime.utc(2026, 7, 14);
      final profile = UserProfile(
        id: 'profile-1',
        name: 'Yoga',
        preferredLanguage: 'id',
        timezone: 'Asia/Jakarta',
        assistantName: 'Nara',
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveProfile(profile);
      await repository.savePreferences(
        const AppPreferences(theme: ThemePreference.dark),
      );

      final reopenedRepository = DriftFoundationRepository(database);
      expect((await reopenedRepository.getProfile())?.name, 'Yoga');
      expect(
        (await reopenedRepository.getPreferences()).theme,
        ThemePreference.dark,
      );
    },
  );
}
