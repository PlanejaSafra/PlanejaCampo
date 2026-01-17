import 'package:flutter/material.dart';
import 'package:planejacampo/extension_themes.dart';
import 'package:planejacampo/themes/chart_theme.dart';
import 'dart:math';

class AppThemes {
  static final Color lightGreenHeader = Colors.green[300]!;
  static final Color lightGreenItem = Colors.green[100]!;
  static final Color lightFloatingActionButtonColor = Colors.black.withOpacity(0.7);
  static const Color darkFloatingActionButtonColor = Colors.white;
  static final Color lightDrawerHeaderColor = Colors.green[400]!;
  static final Color lightDrawerBodyColor = Colors.green[200]!;
  static final Color darkDrawerHeaderColor = Colors.green[700]!;
  static final Color darkDrawerBodyColor = Colors.green[900]!;
  static const Color darkBackgroundColor = Color(0xFF1e2a26);
  static final Color lightBackgroundColor = Colors.white;
  static final Color lightEditIconColor = Colors.black.withOpacity(0.7);
  static const Color darkEditIconColor = Colors.white70;
  static final Color tutorialColorShadow = Colors.black.withOpacity(0.8);
  static final TextStyle tutorialTextStyleSkip = TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold);
  static final TextStyle tutorialTextStyle = TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold);

  // Estilos específicos para gráficos
  static const double chartFontSize = 12; // Tamanho da fonte nos gráficos
  static const double chartAxisFontSize = 10; // Tamanho da fonte nos eixos
  static const double chartBarWidth = 20; // Largura das barras no gráfico de barras
  static const Color chartBarColorComprado = Colors.blue; // Cor para o "Comprado"
  static const Color chartBarColorAPagar = Colors.red; // Cor para o "A Pagar"
  static const Color chartBackgroundColor = Colors.white; // Cor de fundo do gráfico
  static const TextStyle chartTitleStyle = TextStyle(
    fontSize: chartFontSize,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  static Color getRandomColor() {
    return Colors.primaries[Random().nextInt(Colors.primaries.length)];
  }

  //static TextStyle get tutorialTextStyle => _tutorialTextStyle;



  static final ThemeData lightTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: lightBackgroundColor,
    dialogBackgroundColor: lightBackgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.green,
      foregroundColor: Colors.black.withOpacity(0.7),
    ),
    iconTheme: IconThemeData(
      color: lightEditIconColor,
    ),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
      secondary: lightDrawerHeaderColor,
      surface: lightGreenItem,
      background: lightGreenItem,
    ),
    cardColor: lightBackgroundColor,
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.green,
      selectedItemColor: lightBackgroundColor,
      unselectedItemColor: darkDrawerBodyColor,
    ),
    textTheme: TextTheme(
      // Estilos de texto para diferentes partes do aplicativo
      displayLarge: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 24, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 18, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 22),
      bodyMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20),
      bodySmall: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14),
      labelLarge: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 22, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: lightBackgroundColor,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20),
    ),
    listTileTheme: ListTileThemeData(
      textColor: Colors.black.withOpacity(0.7),
      iconColor: Colors.black.withOpacity(0.7),
      titleTextStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20, fontWeight: FontWeight.bold),
      subtitleTextStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 20),
      tileColor: lightGreenItem,
      //tileColor: Colors.blue,
      // Outras configurações de tema para ListTile...
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: lightDrawerHeaderColor,
    ),
    cardTheme: CardTheme(
      color: lightBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withOpacity(0.6)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.green),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black.withOpacity(0.6)),
      ),
      labelStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontWeight: FontWeight.bold),
      hintStyle: TextStyle(color: Colors.black.withOpacity(0.7)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.green,
      foregroundColor: lightFloatingActionButtonColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.black.withOpacity(0.7),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.green,
      ),
    ),
    // Adicionando IconButtonThemeData para o lightTheme
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(lightEditIconColor),
        overlayColor: WidgetStateProperty.all(Colors.green.withOpacity(0.1)),
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[
      ChartTheme(
        barColorType1: Colors.blue,
        barColorType2: Colors.red,
        barColorType3: Colors.yellow,
        barWidth: 20,
        tooltipTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        axisTextStyle: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
        pieChartBackgroundColor: Colors.white,
      ),
      ExtensionThemes.tutorialTheme.copyWith(
        backgroundColor: Colors.green.withOpacity(0.9),
        textColor: lightBackgroundColor,
      ),
    ],
  );


  static final ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBackgroundColor,
    dialogBackgroundColor: darkBackgroundColor,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackgroundColor,
      foregroundColor: Colors.white70,
    ),
    iconTheme: const IconThemeData(
      color: darkEditIconColor,
    ),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green).copyWith(
      secondary: darkBackgroundColor.withOpacity(0.9),
      surface: darkBackgroundColor.withOpacity(0.5),
      background: darkBackgroundColor.withOpacity(0.5),
    ),
    cardColor: const Color(0xFF2a3d33),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2a3d33),
      selectedItemColor: Colors.white70,
      unselectedItemColor: Colors.green,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
      displayMedium: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      displaySmall: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
      headlineLarge: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
      titleLarge: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      titleSmall: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
      bodyLarge: TextStyle(color: Colors.white70, fontSize: 20), // Label e Valor padrão de letras de campos.
      bodyMedium: TextStyle(color: Colors.white70, fontSize: 20),
      bodySmall: TextStyle(color: Colors.white70, fontSize: 16),
      labelLarge: TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
      labelMedium: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      labelSmall: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Color(0xFF2a3d33),
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      textStyle: TextStyle(color: Colors.white70, fontSize: 20),

    ),

    listTileTheme: const ListTileThemeData(
      textColor: Colors.white70,
      iconColor: Colors.white70,
      titleTextStyle: TextStyle(color: Colors.white70, fontSize: 20, fontWeight: FontWeight.bold),
      subtitleTextStyle: TextStyle(color: Colors.white70, fontSize: 20),
      tileColor: Color(0xFF2a3d33),
      //tileColor: Colors.blue,
      // Outras configurações de tema para ListTile...
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: darkDrawerHeaderColor,
    ),
    cardTheme: CardTheme(
      //color: const Color(0xFF2a3d33),
      color: darkBackgroundColor,
      //color: Colors.yellow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
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
      labelStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold), // Título dos campos variados.
      hintStyle: TextStyle(color: Colors.white70),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.green,
      foregroundColor: darkFloatingActionButtonColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white70,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Colors.green,
      ),
    ),
    // Adicionando IconButtonThemeData para o darkTheme
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.transparent),
        foregroundColor: WidgetStateProperty.all(darkEditIconColor),
        overlayColor: WidgetStateProperty.all(Colors.green.withOpacity(0.1)),
      ),
    ),

    extensions: <ThemeExtension<dynamic>>[
      ChartTheme(
        barColorType1: Colors.lightBlueAccent,
        barColorType2: Colors.orange,
        barColorType3: Colors.green,
        barWidth: 20,
        tooltipTextStyle: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        axisTextStyle: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
        pieChartBackgroundColor: darkBackgroundColor,
      ),
      ExtensionThemes.tutorialTheme.copyWith(
        backgroundColor: Colors.green[700]!.withOpacity(0.9),
        textColor: Colors.white,
      ),
    ],
  );
}


/*
Title
Headline
Display
Label
Body

Menu Lateral (ListTile - Text):

Título (primary text): titleMedium
Subtítulo (secondary text): bodyMedium
Card:

Título: titleMedium ou titleLarge
Subtítulo: bodyMedium ou bodySmall
Conteúdo: bodyLarge
TextFormField:

Label Text: labelLarge ou labelMedium
Value Text: bodyMedium ou bodyLarge
 */