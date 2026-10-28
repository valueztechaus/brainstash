import 'package:flutter/material.dart';

import 'models/idea.dart';

abstract final class AppColors {
  static const ground = Color(0xFF0F1115);
  static const surface = Color(0xFF171A20);
  static const surfaceHigh = Color(0xFF1A1D24);
  static const border = Color(0xFF23262E);
  static const borderStrong = Color(0xFF2A2E37);
  static const text = Color(0xFFECEEF2);
  static const textMuted = Color(0xFFA8AEBB);
  static const textFaint = Color(0xFF8C93A1);
  static const amber = Color(0xFFF5B83D);
  static const amberInk = Color(0xFF1A1406);
  static const amberTint = Color(0xFF2B2312);
  static const danger = Color(0xFFF08A7A);

  static (Color bg, Color fg) kind(IdeaKind k) => switch (k) {
        IdeaKind.product => (amberTint, amber),
        IdeaKind.service => (const Color(0xFF132433), const Color(0xFF6FB4F0)),
        IdeaKind.problem => (const Color(0xFF2E1A1A), danger),
        IdeaKind.other => (const Color(0xFF22252D), const Color(0xFFC9CDD5)),
      };
}

const monoFamily = 'FiraCode';

TextStyle sectionLabel(BuildContext context) => const TextStyle(
      fontFamily: monoFamily,
      fontSize: 12,
      letterSpacing: 1,
      color: AppColors.textFaint,
    );

ThemeData buildTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.amber,
    onPrimary: AppColors.amberInk,
    secondary: AppColors.amber,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
  );
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.borderStrong),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    fontFamily: 'FiraSans',
    scaffoldBackgroundColor: AppColors.ground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.ground,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.ground,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
      ),
      hintStyle: const TextStyle(color: AppColors.textFaint),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.amber,
      foregroundColor: AppColors.amberInk,
      shape: CircleBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      showDragHandle: true,
    ),
    dividerColor: AppColors.border,
  );
}
