import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildZohalTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'sans',
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: AppColors.black,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.black,
          secondary: AppColors.yellow,
          surface: AppColors.surface,
        ),
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.black,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      elevation: 1,
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.yellow,
      elevation: 3,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
  );
}
