import 'package:drift/drift.dart';
import 'package:nara/database/app_database.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/domain/entities/user_profile.dart';
import 'package:nara/features/foundation/domain/repositories/foundation_repository.dart';

class DriftFoundationRepository implements FoundationRepository {
  DriftFoundationRepository(this._database);

  final AppDatabase _database;

  static const _languageKey = 'language';
  static const _currencyKey = 'currency';
  static const _timezoneKey = 'timezone';
  static const _themeKey = 'theme';
  static const _appLockKey = 'app_lock_enabled';

  @override
  Future<void> initialize() async {
    final now = DateTime.now().toUtc();
    final categorySeeds = [
      _category('expense-food', 'Makanan', 'expense', 'restaurant', now),
      _category('expense-transport', 'Transportasi', 'expense', 'commute', now),
      _category('expense-bills', 'Tagihan', 'expense', 'receipt_long', now),
      _category('expense-shopping', 'Belanja', 'expense', 'shopping_bag', now),
      _category(
        'expense-health',
        'Kesehatan',
        'expense',
        'health_and_safety',
        now,
      ),
      _category('expense-education', 'Pendidikan', 'expense', 'school', now),
      _category('expense-entertainment', 'Hiburan', 'expense', 'movie', now),
      _category('expense-other', 'Lainnya', 'expense', 'more_horiz', now),
      _category('income-salary', 'Gaji', 'income', 'payments', now),
      _category('income-business', 'Usaha', 'income', 'storefront', now),
      _category('income-gift', 'Hadiah', 'income', 'redeem', now),
      _category('income-other', 'Pemasukan lain', 'income', 'add_card', now),
    ];

    await _database.transaction(() async {
      await _database.batch((batch) {
        batch.insertAll(
          _database.categories,
          categorySeeds,
          mode: InsertMode.insertOrIgnore,
        );
        batch.insertAll(_database.appSettings, [
          _setting(_languageKey, 'id', now),
          _setting(_currencyKey, 'IDR', now),
          _setting(_timezoneKey, 'Asia/Jakarta', now),
          _setting(_themeKey, ThemePreference.system.name, now),
          _setting(_appLockKey, 'false', now),
        ], mode: InsertMode.insertOrIgnore);
      });
    });
  }

  @override
  Future<UserProfile?> getProfile() async {
    final query = _database.select(_database.profiles)..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return UserProfile(
      id: row.id,
      name: row.name,
      preferredLanguage: row.preferredLanguage,
      timezone: row.timezone,
      assistantName: row.assistantName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    await _database
        .into(_database.profiles)
        .insertOnConflictUpdate(
          ProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            preferredLanguage: Value(profile.preferredLanguage),
            timezone: Value(profile.timezone),
            assistantName: Value(profile.assistantName),
            createdAt: Value(profile.createdAt.toUtc()),
            updatedAt: Value(profile.updatedAt.toUtc()),
          ),
        );
  }

  @override
  Future<AppPreferences> getPreferences() async {
    final rows = await _database.select(_database.appSettings).get();
    final settings = {for (final row in rows) row.key: row.value};

    return AppPreferences(
      language: settings[_languageKey] ?? 'id',
      currency: settings[_currencyKey] ?? 'IDR',
      timezone: settings[_timezoneKey] ?? 'Asia/Jakarta',
      theme: ThemePreference.fromStorage(settings[_themeKey]),
      appLockEnabled: settings[_appLockKey] == 'true',
    );
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    final now = DateTime.now().toUtc();
    await _database.batch((batch) {
      batch.insertAllOnConflictUpdate(_database.appSettings, [
        _setting(_languageKey, preferences.language, now),
        _setting(_currencyKey, preferences.currency, now),
        _setting(_timezoneKey, preferences.timezone, now),
        _setting(_themeKey, preferences.theme.name, now),
        _setting(_appLockKey, preferences.appLockEnabled.toString(), now),
      ]);
    });
  }

  static CategoriesCompanion _category(
    String id,
    String name,
    String type,
    String icon,
    DateTime now,
  ) {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      type: type,
      icon: Value(icon),
      isSystem: const Value(true),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
  }

  static AppSettingsCompanion _setting(String key, String value, DateTime now) {
    return AppSettingsCompanion.insert(
      key: key,
      value: value,
      updatedAt: Value(now),
    );
  }
}
