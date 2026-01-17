import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

class ExtensionThemes {
  static final tutorialTheme = TutorialTheme();
  // Você pode adicionar outras extensões de tema aqui no futuro
  // static final anotherTheme = _AnotherTheme();
}

class TutorialTheme extends ThemeExtension<TutorialTheme> {
  final Color backgroundColor;
  final Color textColor;
  final TextStyle textStyle;
  final double paddingFocus;
  final double opacityShadow;

  TutorialTheme({
    this.backgroundColor = Colors.green,
    this.textColor = Colors.white,
    this.textStyle = const TextStyle(color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold),
    this.paddingFocus = 10,
    this.opacityShadow = 0.8,
  });

  @override
  TutorialTheme copyWith({
    Color? backgroundColor,
    Color? textColor,
    TextStyle? textStyle,
    double? paddingFocus,
    double? opacityShadow,
  }) {
    return TutorialTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      textStyle: textStyle ?? this.textStyle,
      paddingFocus: paddingFocus ?? this.paddingFocus,
      opacityShadow: opacityShadow ?? this.opacityShadow,
    );
  }

  @override
  TutorialTheme lerp(TutorialTheme? other, double t) {
    if (other is! TutorialTheme) {
      return this;
    }
    return TutorialTheme(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      textColor: Color.lerp(textColor, other.textColor, t)!,
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t)!,
      paddingFocus: lerpDouble(paddingFocus, other.paddingFocus, t)!,
      opacityShadow: lerpDouble(opacityShadow, other.opacityShadow, t)!,
    );
  }
}

// Você pode adicionar outras classes de extensão de tema aqui no futuro