
import 'package:flutter/material.dart';

/// Preset: WARM_EARTHY (accent hexes overridden for the cream / sage / brass brief).
class AppColors {
  const AppColors._();

  static const String name = 'WARM_EARTHY';

  static const Color background = Color(0xFFF7F5F0);
  static const Color backgroundAlt = Color(0xFFF2EDE3);
  static const Color surface = Color(0xFFFDFCFA);
  static const Color hairline = Color(0xFFE3DDD1);

  static const Color primary = Color(0xFF557A6E);
  static const Color primaryDeep = Color(0xFF3F5C53);
  static const Color secondary = Color(0xFFA7C4B5);
  static const Color accent = Color(0xFFCBA135);
  static const Color accentDeep = Color(0xFFB3872C);

  static const Color ink = Color(0xFF273043);
  static const Color textSecondary = Color(0xFF6F7789);
  static const Color textMuted = Color(0xFF8A8F9E);

  static const Color loaderDark1 = Color(0xFF273043);
  static const Color loaderDark2 = Color(0xFF1B2433);
  static const Color loaderDark3 = Color(0xFF101821);

  /// Ring / chip colour per compass direction.
  static const Color mind = primary;
  static const Color body = accent;
  static const Color home = secondary;
  static const Color focus = primaryDeep;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.background,
    secondary: AppColors.secondary,
    onSecondary: AppColors.ink,
    tertiary: AppColors.accent,
    onTertiary: AppColors.ink,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    splashColor: AppColors.primary.withValues(alpha: 0.13),
    highlightColor: AppColors.primary.withValues(alpha: 0.07),
    textTheme: const TextTheme(
      // Hero wordmark on Menu.
      displayLarge: TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w300,
        letterSpacing: 3.0,
        height: 0.98,
        color: AppColors.ink,
      ),
      // Result headline.
      headlineMedium: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.w300,
        letterSpacing: 4.0,
        color: AppColors.background,
      ),
      // Button labels — lineHeight locked to the 24px icon box.
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        height: 24 / 16,
      ),
      // Routine step titles.
      bodyLarge: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      // Labels, taglines, hints.
      bodySmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.6,
        color: AppColors.textMuted,
      ),
      // Counters.
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      ),
    ),
  );
}
