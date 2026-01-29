import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';

/// CASH-31: Dynamic theme based on FarmType context.
/// - Agro (farm): green palette (default AppTheme)
/// - Personal: indigo/blue palette
class CashTheme {
  CashTheme._();

  /// Primary colors per context.
  static const Color _agroSeed = Color(0xFF2E7D32);    // Green
  static const Color _personalSeed = Color(0xFF1565C0); // Indigo/Blue

  /// Returns the seed color for the current FarmType.
  static Color seedColor(FarmType? type) {
    return type == FarmType.personal ? _personalSeed : _agroSeed;
  }

  /// Light theme for the given context.
  static ThemeData light({FarmType? farmType}) {
    if (farmType != FarmType.personal) {
      return AppTheme.light();
    }
    return _personalLight;
  }

  /// Dark theme for the given context.
  static ThemeData dark({FarmType? farmType}) {
    if (farmType != FarmType.personal) {
      return AppTheme.dark();
    }
    return _personalDark;
  }

  // ── Personal (blue) light theme ──────────────────────────────────────

  static final ThemeData _personalLight = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _personalSeed,
      brightness: Brightness.light,
      surface: Colors.blue[50]!,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _personalSeed,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _personalSeed,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _personalSeed,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: _personalSeed, width: 2),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.6)),
      ),
      labelStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.87),
        fontWeight: FontWeight.bold,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _personalSeed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Color(0xFFBBDEFB),
    ),
  );

  // ── Personal (blue) dark theme ───────────────────────────────────────

  static const Color _personalDarkBg = Color(0xFF1a2433);
  static const Color _personalDarkCard = Color(0xFF253347);

  static final ThemeData _personalDark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _personalDarkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
      surface: _personalDarkBg.withValues(alpha: 0.5),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: _personalDarkBg,
      foregroundColor: Colors.white70,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: _personalDarkCard,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white70,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white70),
      ),
      labelStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _personalDarkCard,
      selectedItemColor: Colors.white70,
      unselectedItemColor: Colors.blue,
    ),
  );
}
