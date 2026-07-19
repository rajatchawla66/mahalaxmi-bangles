import 'package:flutter/material.dart';

const kCream = Color(0xFFFFF8F0);
const kGold = Color(0xFFFFA000);
const kMaroon = Color(0xFF800020);
const kDark = Color(0xFF212121);
const kMuted = Color(0xFF757575);

final customerTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: kCream,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: kMaroon,
    primary: kMaroon,
    secondary: kGold,
    surface: kCream,
    brightness: Brightness.light,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    backgroundColor: kMaroon,
    foregroundColor: Colors.white,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kMaroon,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0D5C0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE0D5C0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: kGold, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w300,
      color: kDark,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: kDark,
    ),
    bodyMedium: TextStyle(fontSize: 14, color: kDark),
    bodySmall: TextStyle(fontSize: 12, color: kMuted),
  ),
);
