import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final appDarkTextTheme = GoogleFonts.interTextTheme(
  ThemeData(brightness: Brightness.dark).textTheme,
);

final appLightTextTheme = GoogleFonts.interTextTheme(
  ThemeData(brightness: Brightness.light).textTheme,
);
