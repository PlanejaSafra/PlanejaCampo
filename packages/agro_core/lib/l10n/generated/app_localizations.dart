import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AgroLocalizations
/// returned by `AgroLocalizations.of(context)`.
///
/// Applications need to include `AgroLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AgroLocalizations.localizationsDelegates,
///   supportedLocales: AgroLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AgroLocalizations.supportedLocales
/// property.
abstract class AgroLocalizations {
  AgroLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AgroLocalizations? of(BuildContext context) {
    return Localizations.of<AgroLocalizations>(context, AgroLocalizations);
  }

  static const LocalizationsDelegate<AgroLocalizations> delegate = _AgroLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'PlanejaSafra'**
  String get appName;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get continueLabel;

  /// No description provided for @acceptAndContinueLabel.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT AND CONTINUE'**
  String get acceptAndContinueLabel;

  /// No description provided for @declineLabel.
  ///
  /// In en, this message translates to:
  /// **'DECLINE'**
  String get declineLabel;

  /// No description provided for @declineAndExitLabel.
  ///
  /// In en, this message translates to:
  /// **'DECLINE (EXIT)'**
  String get declineAndExitLabel;

  /// No description provided for @privacySettingsHint.
  ///
  /// In en, this message translates to:
  /// **'You can review the full documents in Settings → Privacy.'**
  String get privacySettingsHint;

  /// No description provided for @termsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy'**
  String get termsTitle;

  /// No description provided for @termsBodyIntro.
  ///
  /// In en, this message translates to:
  /// **'By tapping \"Accept and Continue\", you agree to the Terms of Use and Privacy Policy of PlanejaSafra/PlanejaCampo apps.'**
  String get termsBodyIntro;

  /// No description provided for @termsSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary of what happens:'**
  String get termsSummaryTitle;

  /// No description provided for @termsSummaryItem1.
  ///
  /// In en, this message translates to:
  /// **'You record information such as rainfall, prices, weighings, notes, and entries.'**
  String get termsSummaryItem1;

  /// No description provided for @termsSummaryItem2.
  ///
  /// In en, this message translates to:
  /// **'This data is stored on your device to make the app work.'**
  String get termsSummaryItem2;

  /// No description provided for @termsSummaryItem3.
  ///
  /// In en, this message translates to:
  /// **'The app may display ads in the free version.'**
  String get termsSummaryItem3;

  /// No description provided for @termsSummaryItem4.
  ///
  /// In en, this message translates to:
  /// **'We may collect minimal technical information (e.g., crashes and performance) to improve the app.'**
  String get termsSummaryItem4;

  /// No description provided for @termsFooter.
  ///
  /// In en, this message translates to:
  /// **'You can review the full documents in Settings → Privacy.'**
  String get termsFooter;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Features and Sharing (optional)'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'You can use the app in private mode (offline), or enable extra features based on aggregated community data.\n\nSelect what you authorize:'**
  String get consentIntro;

  /// No description provided for @consentOption1Title.
  ///
  /// In en, this message translates to:
  /// **'Aggregated data for regional metrics'**
  String get consentOption1Title;

  /// No description provided for @consentOption1Desc.
  ///
  /// In en, this message translates to:
  /// **'Use your records in aggregated and statistical form to generate indicators such as rainfall by region, regional average prices, trends, and comparisons.'**
  String get consentOption1Desc;

  /// No description provided for @consentOption2Title.
  ///
  /// In en, this message translates to:
  /// **'Sharing with partners (aggregated)'**
  String get consentOption2Title;

  /// No description provided for @consentOption2Desc.
  ///
  /// In en, this message translates to:
  /// **'Share only aggregated/statistical data with third parties for reports, regional intelligence, and improvements.'**
  String get consentOption2Desc;

  /// No description provided for @consentOption3Title.
  ///
  /// In en, this message translates to:
  /// **'More relevant ads and offers'**
  String get consentOption3Title;

  /// No description provided for @consentOption3Desc.
  ///
  /// In en, this message translates to:
  /// **'Use usage data to improve ads, promotions, and suggestions (when available).'**
  String get consentOption3Desc;

  /// No description provided for @consentSmallNoteUnderDecline.
  ///
  /// In en, this message translates to:
  /// **'Without accepting, you can use the app normally in private mode (basic offline features).'**
  String get consentSmallNoteUnderDecline;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Consents'**
  String get drawerPrivacy;

  /// No description provided for @drawerAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get drawerAbout;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get settingsLanguageAuto;

  /// No description provided for @settingsAboutApp.
  ///
  /// In en, this message translates to:
  /// **'About the App'**
  String get settingsAboutApp;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'This app is part of the PlanejaSafra Suite, designed to help rural producers manage their activities in the field.'**
  String get aboutDescription;

  /// No description provided for @aboutOfflineFirst.
  ///
  /// In en, this message translates to:
  /// **'100% Offline-First: all your data stays on your device.'**
  String get aboutOfflineFirst;

  /// No description provided for @aboutSuite.
  ///
  /// In en, this message translates to:
  /// **'PlanejaSafra Suite'**
  String get aboutSuite;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy and Consents'**
  String get privacyTitle;

  /// No description provided for @privacyTermsSection.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use and Privacy Policy'**
  String get privacyTermsSection;

  /// No description provided for @privacyTermsSummary.
  ///
  /// In en, this message translates to:
  /// **'By using this app, you agree to our Terms of Use and Privacy Policy. You can review the full documents at any time.'**
  String get privacyTermsSummary;

  /// No description provided for @privacyConsentsSection.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing Consents'**
  String get privacyConsentsSection;

  /// No description provided for @privacyConsentsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage how your data can be used. All options are optional.'**
  String get privacyConsentsDescription;

  /// No description provided for @consentShareAggregated.
  ///
  /// In en, this message translates to:
  /// **'Share aggregated data'**
  String get consentShareAggregated;

  /// No description provided for @consentShareAggregatedDesc.
  ///
  /// In en, this message translates to:
  /// **'Allow your records to be used anonymously for regional statistics.'**
  String get consentShareAggregatedDesc;

  /// No description provided for @consentReceiveRegionalMetrics.
  ///
  /// In en, this message translates to:
  /// **'Receive regional metrics'**
  String get consentReceiveRegionalMetrics;

  /// No description provided for @consentReceiveRegionalMetricsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get insights based on aggregated community data.'**
  String get consentReceiveRegionalMetricsDesc;

  /// No description provided for @consentPersonalizedAds.
  ///
  /// In en, this message translates to:
  /// **'Personalized ads'**
  String get consentPersonalizedAds;

  /// No description provided for @consentPersonalizedAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'See more relevant ads based on your usage.'**
  String get consentPersonalizedAdsDesc;

  /// No description provided for @privacySaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get privacySaved;
}

class _AgroLocalizationsDelegate extends LocalizationsDelegate<AgroLocalizations> {
  const _AgroLocalizationsDelegate();

  @override
  Future<AgroLocalizations> load(Locale locale) {
    return SynchronousFuture<AgroLocalizations>(lookupAgroLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AgroLocalizationsDelegate old) => false;
}

AgroLocalizations lookupAgroLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AgroLocalizationsEn();
    case 'pt': return AgroLocalizationsPt();
  }

  throw FlutterError(
    'AgroLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
