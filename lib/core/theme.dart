import 'package:flutter/material.dart';

const ink = Color(0xFF3B3454);
const inkSoft = Color(0xFF6E6584);
const muted = Color(0xFF9A93AE);
const mutedWarm = Color(0xFF8B84A0);
const placeholderInk = Color(0xFFB3ABC9);

const violet = Color(0xFF7C6FE0);
const violetDeep = Color(0xFF8B7FE0);
const skyBlue = Color(0xFF6FA3DE);

const surfaceSoft = Color(0xFFECE8F7);
const bgTop = Color(0xFFEEEAFB);
const bgBottom = Color(0xFFE3EEFB);

const tabIdle = Color(0xFFB7AED6);
const disabledFill = Color(0xFFD8D3EC);
const rose = Color(0xFFD98CA0);
const sentInk = Color(0xFFC77E93);
const receivedInk = Color(0xFF4FAE82);
const hairline = Color(0x1F8B7FE0);

const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [violetDeep, skyBlue],
);

const screenGradient = LinearGradient(
  begin: Alignment(-0.4, -1),
  end: Alignment(0.4, 1),
  colors: [bgTop, bgBottom],
);

const avatarPalette = [
  Color(0xFFC9BEED),
  Color(0xFFBBD4F0),
  Color(0xFFF0C9DE),
  Color(0xFFC9EDDD),
  Color(0xFFF0DEC0),
  Color(0xFFD8C9ED),
];

const avatarInk = Color(0xFF4A4368);

const tabular = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: violet,
        brightness: Brightness.light,
      ).copyWith(
        primary: violet,
        onPrimary: Colors.white,
        secondary: skyBlue,
        surface: bgTop,
        onSurface: ink,
        error: rose,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: bgTop,
    splashFactory: NoSplash.splashFactory,
    textTheme: Typography.blackMountainView.apply(
      bodyColor: ink,
      displayColor: ink,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: ink,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
