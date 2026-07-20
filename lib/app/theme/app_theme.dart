import 'package:flutter/material.dart';

abstract final class AppTheme {
  static const _seedColor = Color(0xFF00DDF2);
  static const _lightBackground = Color(0xFFF6F8FB);
  static const _darkBackground = Color(0xFF07111F);

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    );

    return _theme(colorScheme, _lightBackground);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    );

    return _theme(colorScheme, _darkBackground);
  }

  static ThemeData _theme(ColorScheme colorScheme, Color background) {
    final scheme = colorScheme.copyWith(
      primary: const Color(0xFF001B3D),
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFDAF7FB),
      onPrimaryContainer: const Color(0xFF002B5B),
      secondary: const Color(0xFF007B89),
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFB9F4FF),
      onSecondaryContainer: const Color(0xFF00343C),
      tertiary: const Color(0xFF14785F),
      tertiaryContainer: const Color(0xFFC8F3E3),
      surface: background,
      surfaceContainerLow: colorScheme.brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF0D1A2B),
      surfaceContainer: colorScheme.brightness == Brightness.light
          ? const Color(0xFFF0F4F8)
          : const Color(0xFF122238),
      surfaceContainerHighest: colorScheme.brightness == Brightness.light
          ? const Color(0xFFE5ECF3)
          : const Color(0xFF1A2A40),
      outlineVariant: colorScheme.brightness == Brightness.light
          ? const Color(0xFFD8E0E8)
          : const Color(0xFF31445E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto',
      textTheme: Typography.material2021().black
          .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
          .copyWith(
            headlineMedium: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
            headlineSmall: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            titleMedium: const TextStyle(fontWeight: FontWeight.w700),
          ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        titleTextStyle: TextStyle(
          color: scheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.94),
        shadowColor: const Color(0xFF001B3D).withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.94),
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.secondary
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            fontSize: 11,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.secondary
                : scheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.92),
        indicatorColor: scheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(
          color: scheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        selectedColor: scheme.secondaryContainer,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }
}
