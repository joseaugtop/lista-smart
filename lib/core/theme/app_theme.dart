import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_text_theme.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.primary, // #A3E615
    brightness: Brightness.dark, // INSIDE fromSeed, NOT at ThemeData level
    surface: AppColors.surface, // #18181B
    onSurface: AppColors.textMain, // #FAFAFA
    primary: AppColors.primary, // #A3E615
    error: AppColors.error, // #EF4444
  ),
  scaffoldBackgroundColor: AppColors.background, // #09090B
  textTheme: appTextTheme,
  cardTheme: const CardThemeData(
    surfaceTintColor: Colors.transparent, // Prevents Material3 elevation tint
    color: AppColors.surface,
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
  ),
);
