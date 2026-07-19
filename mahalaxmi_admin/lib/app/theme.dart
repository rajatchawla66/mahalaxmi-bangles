import 'package:flutter/material.dart';

final adminTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFF1565C0),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
    scrolledUnderElevation: 2,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
  ),
  navigationBarTheme: NavigationBarThemeData(
    elevation: 2,
    labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
    height: 68,
  ),
);
