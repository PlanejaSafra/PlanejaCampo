import 'package:flutter/widgets.dart';

extension LocaleExtension on Locale {
  static Locale fromString(String localeString) {
    // Split by '-' or '_'
    List<String> parts = localeString.split(RegExp(r'[-_]'));
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    } else if (parts.length == 1) {
      return Locale(parts[0]);
    } else {
      // Default to 'en'
      return const Locale('en');
    }
  }
}
