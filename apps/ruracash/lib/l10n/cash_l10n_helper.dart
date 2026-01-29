import 'dart:ui' as ui;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_pt.dart';
import 'package:flutter_gen/gen_l10n/app_localizations_en.dart';

/// Helper para obter CashLocalizations fora de BuildContext.
/// Usado em serviços background como notificações.
CashLocalizations lookupCashLocalizations([String? localeOverride]) {
  final locale = localeOverride ?? ui.PlatformDispatcher.instance.locale.languageCode;

  switch (locale) {
    case 'pt':
      return CashLocalizationsPt();
    case 'en':
    default:
      return CashLocalizationsEn();
  }
}
