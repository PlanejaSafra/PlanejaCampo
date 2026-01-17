import 'package:flutter/material.dart';
import 'dart:ui' show lerpDouble;

import 'chart_theme.dart';

class ExtensionThemes {
  static final tutorialTheme = TutorialTheme();
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
    this.textStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 24,
      fontWeight: FontWeight.bold,
    ),
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

/// Extension para acesso fácil às extensões de tema no contexto.
extension ThemeContextExtensions on BuildContext {
  ChartTheme get chartTheme =>
      Theme.of(this).extension<ChartTheme>() ??
      const ChartTheme(
        barColorType1: Colors.blue,
        barColorType2: Colors.red,
        barColorType3: Colors.yellow,
        barWidth: 20,
        tooltipTextStyle:
            TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        axisTextStyle: TextStyle(
            color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
        pieChartBackgroundColor: Colors.white,
      );

  TutorialTheme get tutorialTheme =>
      Theme.of(this).extension<TutorialTheme>() ?? TutorialTheme();
}
