import 'package:flutter/material.dart';

final labourTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF2E7D32),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
    ),
    elevation: 1,
    margin: const EdgeInsets.only(bottom: 8),
  ),
  navigationBarTheme: NavigationBarThemeData(
    elevation: 2,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    height: 64,
  ),
);
