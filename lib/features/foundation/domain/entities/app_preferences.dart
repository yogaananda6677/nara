enum ThemePreference {
  system,
  light,
  dark;

  static ThemePreference fromStorage(String? value) {
    return ThemePreference.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ThemePreference.system,
    );
  }
}

class AppPreferences {
  const AppPreferences({
    this.language = 'id',
    this.currency = 'IDR',
    this.timezone = 'Asia/Jakarta',
    this.theme = ThemePreference.system,
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.lockTimeoutSeconds = 30,
  });

  final String language;
  final String currency;
  final String timezone;
  final ThemePreference theme;
  final bool appLockEnabled;
  final bool biometricEnabled;
  final int lockTimeoutSeconds;

  AppPreferences copyWith({
    String? language,
    String? currency,
    String? timezone,
    ThemePreference? theme,
    bool? appLockEnabled,
    bool? biometricEnabled,
    int? lockTimeoutSeconds,
  }) {
    return AppPreferences(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      theme: theme ?? this.theme,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lockTimeoutSeconds: lockTimeoutSeconds ?? this.lockTimeoutSeconds,
    );
  }
}
