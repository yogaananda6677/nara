import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/app/router/app_router.dart';
import 'package:nara/app/theme/app_theme.dart';
import 'package:nara/core/security/app_lifecycle_lock.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';

class NaraApp extends ConsumerWidget {
  const NaraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themePreference = ref
        .watch(foundationControllerProvider)
        .value
        ?.preferences
        .theme;

    return MaterialApp.router(
      title: 'Nara',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (themePreference) {
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      routerConfig: router,
      builder: (context, child) {
        return AppLifecycleLock(child: child ?? const SizedBox.shrink());
      },
    );
  }
}
