import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand / semantic — same across themes, safe as const
  static const Color primary = Color(0xFFA3E615);
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
}

class AppColorsSet {
  const AppColorsSet._({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.textMain,
    required this.textSecondary,
    required this.glassBorder,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color textMain;
  final Color textSecondary;
  final Color glassBorder;

  static const dark = AppColorsSet._(
    background: Color(0xFF09090B),
    surface: Color(0xFF18181B),
    surfaceElevated: Color(0xFF27272A),
    textMain: Color(0xFFFAFAFA),
    textSecondary: Color(0xFFA1A1AA),
    glassBorder: Color(0x1AFFFFFF), // white 10%
  );

  static const light = AppColorsSet._(
    background: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF4F4F5),
    textMain: Color(0xFF09090B),
    textSecondary: Color(0xFF71717A),
    glassBorder: Color(0x14000000), // black 8%
  );
}

extension AppColorsX on BuildContext {
  AppColorsSet get appColors =>
      Theme.of(this).brightness == Brightness.dark
          ? AppColorsSet.dark
          : AppColorsSet.light;
}
