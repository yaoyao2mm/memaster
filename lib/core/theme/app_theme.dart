import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static const _cjkFallbacks = [
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans CJK SC',
    '.AppleSystemUIFont',
  ];

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.electricBlue,
        brightness: Brightness.light,
        surface: AppColors.panel,
      ),
    );

    final bodyTextTheme = base.textTheme.apply(
      fontFamily: 'PlusJakartaSans',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    final textTheme = bodyTextTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 48,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -1.2,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Georgia',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 34,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
        letterSpacing: -0.8,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
        height: 1.55,
      ),
      bodyMedium: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedInk,
        height: 1.5,
      ),
      labelLarge: const TextStyle(
        fontFamily: 'PlusJakartaSans',
        fontFamilyFallback: _cjkFallbacks,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      cardTheme: const CardThemeData(
        color: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
