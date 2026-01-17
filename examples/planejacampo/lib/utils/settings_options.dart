// lib/utils/settings_options.dart

import 'package:flutter/material.dart';

class SettingsOptions {
  static const List<Locale> supportedLocales = [
    Locale('pt', 'BR'), // Português-BR
    Locale('en', 'US'), // Inglês
  ];

  static Map<String, String> getLocalizedLanguages(BuildContext context) {
    return {
      'pt-BR': 'Português (Brasil)',
      'en-US': 'English (United States)',
    };
  }

    static Locale getLocaleFromString(String localeString) {
      switch (localeString) {
        case 'pt-BR':
          return Locale('pt', 'BR');
        case 'en-US':
          return Locale('en', 'US');
        default:
          return Locale('pt', 'BR');
      }
    }


  static String getStringFromLocale(Locale locale) {
    //return '${locale.languageCode}_${locale.countryCode}';
    return locale.toLanguageTag();
  }
}
