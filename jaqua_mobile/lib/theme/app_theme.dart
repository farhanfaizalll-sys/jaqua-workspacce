import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;

/// Sistem desain terpusat JAQUA. Palet teal/aqua terinspirasi air kolam,
/// sudut membulat lebar, dan bayangan lembut.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF0E7C7B);
  static const Color primaryLight = Color(0xFF4FB3B0);
  static const Color primaryDark = Color(0xFF0A5C5B);
  static const Color accent = Color(0xFFC46A2E);
  static const Color background = Color(0xFFF4F8F7);
  static const Color card = Colors.white;
  static const Color textDark = Color(0xFF16211F);
  static const Color textMuted = Color(0xFF5B6B68);
  static const Color surfaceMuted = Color(0xFFE6F1F0);
  static const Color success = Color(0xFF2E9E5B);
  static const Color danger = Color(0xFFD64545);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const double radiusLg = 24;
  static const double radiusMd = 20;
  static const double radiusSm = 16;
  static const double radiusPill = 100;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: primaryDark.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static ThemeData get lightTheme {
    final base = ThemeData(useMaterial3: true);
    final textTheme = base.textTheme
        .apply(bodyColor: textDark, displayColor: textDark)
        .copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: textDark,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: textDark,
          ),
          titleLarge: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: textDark,
          ),
          bodyLarge: const TextStyle(fontSize: 15, color: textDark),
          bodyMedium: const TextStyle(fontSize: 14, color: textMuted),
        );

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: primaryLight,
        error: danger,
      ),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: textDark,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.6),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMd)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
    );
  }
}
