import 'dart:ui';
import 'package:flutter/material.dart';

class ChartTheme extends ThemeExtension<ChartTheme> {
  final Color barColorType1;
  final Color barColorType2;
  final Color barColorType3;
  final double barWidth;
  final TextStyle tooltipTextStyle;
  final TextStyle axisTextStyle;
  final Color pieChartBackgroundColor;

  const ChartTheme({
    required this.barColorType1,
    required this.barColorType2,
    required this.barColorType3,
    required this.barWidth,
    required this.tooltipTextStyle,
    required this.axisTextStyle,
    required this.pieChartBackgroundColor,
  });

  @override
  ChartTheme copyWith({
    Color? barColortype1,
    Color? barColorType2,
    Color? barColorType3,
    double? barWidth,
    TextStyle? tooltipTextStyle,
    TextStyle? axisTextStyle,
    Color? pieChartBackgroundColor,
  }) {
    return ChartTheme(
      barColorType1: barColortype1 ?? this.barColorType1,
      barColorType2: barColorType2 ?? this.barColorType2,
      barColorType3: barColorType3 ?? this.barColorType3,
      barWidth: barWidth ?? this.barWidth,
      tooltipTextStyle: tooltipTextStyle ?? this.tooltipTextStyle,
      axisTextStyle: axisTextStyle ?? this.axisTextStyle,
      pieChartBackgroundColor: pieChartBackgroundColor ?? this.pieChartBackgroundColor,
    );
  }

  @override
  ThemeExtension<ChartTheme> lerp(ThemeExtension<ChartTheme>? other, double t) {
    if (other is! ChartTheme) return this;
    return ChartTheme(
      barColorType1: Color.lerp(barColorType1, other.barColorType1, t)!,
      barColorType2: Color.lerp(barColorType2, other.barColorType2, t)!,
      barColorType3: Color.lerp(barColorType3, other.barColorType3, t)!,
      barWidth: lerpDouble(barWidth, other.barWidth, t)!,
      tooltipTextStyle: TextStyle.lerp(tooltipTextStyle, other.tooltipTextStyle, t)!,
      axisTextStyle: TextStyle.lerp(axisTextStyle, other.axisTextStyle, t)!,
      pieChartBackgroundColor: Color.lerp(pieChartBackgroundColor, other.pieChartBackgroundColor, t)!,
    );
  }
}
