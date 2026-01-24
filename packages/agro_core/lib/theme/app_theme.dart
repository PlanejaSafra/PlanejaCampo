import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'extensions/chart_theme.dart';
import 'extensions/theme_extensions.dart';

/// Tema principal do Agro Core.
/// Fornece ThemeData para modo claro e escuro com paleta verde/agro.
class AppTheme {
  // Cores da paleta
  static const Color _lightPrimaryGreen =
      Color(0xFF2E7D32); // Dark green for high contrast
  static final Color _lightGreenItem = Colors.green[100]!;
  static const Color _lightFloatingActionButtonColor =
      Colors.white; // Changed to white for contrast
  static const Color _darkFloatingActionButtonColor = Colors.white;
  static final Color _lightDrawerHeaderColor =
      Colors.white; // Body color (lighter than header)
  static const Color _darkDrawerHeaderColor =
      Color(0xFF3E584D); // Body color (Lighter than Header 0xFF334B40)
  static const Color _darkBackgroundColor = Color(0xFF1e2a26);
  static const Color _darkCardColor = Color(0xFF2a3d33);
  static final Color _lightBackgroundColor = Colors.white;
  static final Color _lightEditIconColor = Colors.black.withValues(alpha: 0.7);
  static const Color _darkEditIconColor = Colors.white70;

  AppTheme._();

  /// Retorna o tema claro.
  static ThemeData light() => _lightTheme;

  /// Retorna o tema escuro.
  static ThemeData dark() => _darkTheme;

  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.robotoTextTheme(
      TextTheme(
        displayLarge: TextStyle(
            color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(
            color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(
            color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(
            color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: textColor, fontSize: 20),
        bodyMedium: TextStyle(color: textColor, fontSize: 18),
        bodySmall: TextStyle(color: textColor, fontSize: 14),
        labelLarge: TextStyle(
            color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(
            color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
        labelSmall: TextStyle(
            color: textColor, fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  static final ThemeData _lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: _lightBackgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightPrimaryGreen,
      brightness: Brightness.light,
      surface: _lightGreenItem,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightPrimaryGreen,
      foregroundColor: Colors.white, // White for high contrast
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: _lightBackgroundColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryGreen,
        foregroundColor: Colors.white, // White for high contrast
        minimumSize: const Size(
            double.infinity, 56), // Increased to 56dp for larger touch target
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textTheme: _buildTextTheme(
        Colors.black.withValues(alpha: 0.87)), // Increased contrast to 0.87
    iconTheme: IconThemeData(color: _lightEditIconColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightPrimaryGreen,
      foregroundColor: _lightFloatingActionButtonColor,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _lightDrawerHeaderColor,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _lightPrimaryGreen, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6)),
      ),
      labelStyle: TextStyle(
          color: Colors.black.withValues(alpha: 0.87),
          fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.black.withValues(alpha: 0.6)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightPrimaryGreen,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xFFB9F6CA), // Light green for unselected
    ),
    extensions: <ThemeExtension<dynamic>>[
      ChartTheme(
        barColorType1: Colors.blue,
        barColorType2: Colors.red,
        barColorType3: Colors.yellow,
        barWidth: 20,
        tooltipTextStyle:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        axisTextStyle: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: 14,
            fontWeight: FontWeight.bold),
        pieChartBackgroundColor: Colors.white,
      ),
      ExtensionThemes.tutorialTheme.copyWith(
        backgroundColor: Colors.green.withValues(alpha: 0.9),
        textColor: _lightBackgroundColor,
      ),
    ],
  );

  static final ThemeData _darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _darkBackgroundColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.green,
      brightness: Brightness.dark,
      surface: _darkBackgroundColor.withValues(alpha: 0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackgroundColor,
      foregroundColor: Colors.white70,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: _darkCardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white70,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    ),
    textTheme: _buildTextTheme(Colors.white),
    iconTheme: const IconThemeData(color: _darkEditIconColor),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.green,
      foregroundColor: _darkFloatingActionButtonColor,
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: _darkDrawerHeaderColor,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      labelStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.white70),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkCardColor,
      selectedItemColor: Colors.white70,
      unselectedItemColor: Colors.green,
    ),
    extensions: <ThemeExtension<dynamic>>[
      ChartTheme(
        barColorType1: Colors.lightBlueAccent,
        barColorType2: Colors.orange,
        barColorType3: Colors.green,
        barWidth: 20,
        tooltipTextStyle:
            const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        axisTextStyle: const TextStyle(
            color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        pieChartBackgroundColor: _darkBackgroundColor,
      ),
      ExtensionThemes.tutorialTheme.copyWith(
        backgroundColor: Colors.green[700]!.withValues(alpha: 0.9),
        textColor: Colors.white,
      ),
    ],
  );
}
