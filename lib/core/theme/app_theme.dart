import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_theme.dart';

final appDarkTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.dark,
    surface: AppColorsSet.dark.surface,
    onSurface: AppColorsSet.dark.textMain,
    primary: AppColors.primary,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColorsSet.dark.background,
  textTheme: appDarkTextTheme,
  cardTheme: const CardThemeData(
    surfaceTintColor: Colors.transparent,
    color: Color(0xFF18181B),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF09090B),
    surfaceTintColor: Colors.transparent,
    foregroundColor: Color(0xFFFAFAFA),
    elevation: 0,
  ),
);

final appLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    surface: AppColorsSet.light.surface,
    onSurface: AppColorsSet.light.textMain,
    primary: AppColors.primary,
    error: AppColors.error,
  ),
  scaffoldBackgroundColor: AppColorsSet.light.background,
  textTheme: appLightTextTheme,
  cardTheme: const CardThemeData(
    surfaceTintColor: Colors.transparent,
    color: Color(0xFFFFFFFF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFFAFAFA),
    surfaceTintColor: Colors.transparent,
    foregroundColor: Color(0xFF09090B),
    elevation: 0,
  ),
);

// Keep alias so existing imports of appTheme don't break during migration.
final appTheme = appDarkTheme;
