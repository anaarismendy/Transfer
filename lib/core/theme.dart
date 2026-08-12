import 'package:flutter/material.dart';

const deepAqua = Color(0xFF06312F);
const teal = Color(0xFF0E4F4A);
const turquoise = Color(0xFF0F7A73);
const aqua = Color(0xFF63D9C6);
const aquaSoft = Color(0xFF9FEADD);
const mist = Color(0xFFF0F8F6);
const mistEdge = Color(0xFFC9E2DC);
const danger = Color(0xFFA63A2E);

const _radius = 6.0;

const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

const eyebrow = TextStyle(
  fontSize: 11,
  letterSpacing: 1.6,
  fontWeight: FontWeight.w600,
);

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: turquoise,
    brightness: Brightness.light,
  ).copyWith(
    primary: turquoise,
    onPrimary: Colors.white,
    secondary: aqua,
    onSecondary: deepAqua,
    surface: mist,
    onSurface: deepAqua,
    error: danger,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: mist,
    appBarTheme: const AppBarTheme(
      backgroundColor: deepAqua,
      foregroundColor: mist,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radius),
        side: const BorderSide(color: mistEdge),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: mist,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: mistEdge),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: mistEdge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radius),
        borderSide: const BorderSide(color: turquoise, width: 2),
      ),
      labelStyle: const TextStyle(color: teal),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: turquoise,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: teal,
      contentTextStyle: const TextStyle(color: mist),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius)),
    ),
  );
}
