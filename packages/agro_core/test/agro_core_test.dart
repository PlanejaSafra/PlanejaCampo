import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agro_core/agro_core.dart';

void main() {
  test('AppTheme light returns ThemeData', () {
    final theme = AppTheme.light();
    expect(theme, isNotNull);
    expect(theme.brightness, Brightness.light);
  });

  test('AppTheme dark returns ThemeData', () {
    final theme = AppTheme.dark();
    expect(theme, isNotNull);
    expect(theme.brightness, Brightness.dark);
  });

  test('formatDateBr formats date correctly', () {
    final date = DateTime(2024, 12, 25);
    expect(formatDateBr(date), '25/12/2024');
  });
}
