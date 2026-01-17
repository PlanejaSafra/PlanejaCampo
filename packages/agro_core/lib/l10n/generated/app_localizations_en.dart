import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AgroLocalizationsEn extends AgroLocalizations {
  AgroLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PlanejaSafra';

  @override
  String get continueLabel => 'CONTINUE';

  @override
  String get acceptAndContinueLabel => 'ACCEPT AND CONTINUE';

  @override
  String get declineLabel => 'DECLINE';

  @override
  String get declineAndExitLabel => 'DECLINE (EXIT)';

  @override
  String get privacySettingsHint => 'You can review the full documents in Settings → Privacy.';

  @override
  String get termsTitle => 'Terms of Use and Privacy';

  @override
  String get termsBodyIntro => 'By tapping \"Accept and Continue\", you agree to the Terms of Use and Privacy Policy of PlanejaSafra/PlanejaCampo apps.';

  @override
  String get termsSummaryTitle => 'Summary of what happens:';

  @override
  String get termsSummaryItem1 => 'You record information such as rainfall, prices, weighings, notes, and entries.';

  @override
  String get termsSummaryItem2 => 'This data is stored on your device to make the app work.';

  @override
  String get termsSummaryItem3 => 'The app may display ads in the free version.';

  @override
  String get termsSummaryItem4 => 'We may collect minimal technical information (e.g., crashes and performance) to improve the app.';

  @override
  String get termsFooter => 'You can review the full documents in Settings → Privacy.';

  @override
  String get consentTitle => 'Features and Sharing (optional)';

  @override
  String get consentIntro => 'You can use the app in private mode (offline), or enable extra features based on aggregated community data.\n\nSelect what you authorize:';

  @override
  String get consentOption1Title => 'Aggregated data for regional metrics';

  @override
  String get consentOption1Desc => 'Use your records in aggregated and statistical form to generate indicators such as rainfall by region, regional average prices, trends, and comparisons.';

  @override
  String get consentOption2Title => 'Sharing with partners (aggregated)';

  @override
  String get consentOption2Desc => 'Share only aggregated/statistical data with third parties for reports, regional intelligence, and improvements.';

  @override
  String get consentOption3Title => 'More relevant ads and offers';

  @override
  String get consentOption3Desc => 'Use usage data to improve ads, promotions, and suggestions (when available).';

  @override
  String get consentSmallNoteUnderDecline => 'Without accepting, you can use the app normally in private mode (basic offline features).';
}
