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
  /// **'PlanejaCampo'**
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

  /// No description provided for @acceptAllButton.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT ALL AND CONTINUE'**
  String get acceptAllButton;

  /// No description provided for @confirmSelectionButton.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM AND CONTINUE'**
  String get confirmSelectionButton;

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
  /// **'By tapping \"Accept and Continue\", you agree to the Terms of Use and Privacy Policy of PlanejaCampo apps.'**
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
  /// **'Authorize the use of data and optional features:'**
  String get consentIntro;

  /// No description provided for @consentOption1Title.
  ///
  /// In en, this message translates to:
  /// **'Data and Location'**
  String get consentOption1Title;

  /// No description provided for @consentOption1Desc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentOption1Desc;

  /// No description provided for @consentOption2Title.
  ///
  /// In en, this message translates to:
  /// **'Offers and Promotions'**
  String get consentOption2Title;

  /// No description provided for @consentOption2Desc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentOption2Desc;

  /// No description provided for @consentOption3Title.
  ///
  /// In en, this message translates to:
  /// **'Personalized Ads'**
  String get consentOption3Title;

  /// No description provided for @consentOption3Desc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentOption3Desc;

  /// No description provided for @consentSmallNoteUnderDecline.
  ///
  /// In en, this message translates to:
  /// **'Without accepting, you can use the app normally in private mode (basic offline features).'**
  String get consentSmallNoteUnderDecline;

  /// No description provided for @identityTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to PlanejaCampo'**
  String get identityTitle;

  /// No description provided for @identitySlogan.
  ///
  /// In en, this message translates to:
  /// **'Manage your farm intelligently'**
  String get identitySlogan;

  /// No description provided for @identityGoogleButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get identityGoogleButton;

  /// No description provided for @identityAnonymousButton.
  ///
  /// In en, this message translates to:
  /// **'Continue as Guest'**
  String get identityAnonymousButton;

  /// No description provided for @identityFooterLegal.
  ///
  /// In en, this message translates to:
  /// **'By signing in, you agree to our Terms of Use and Privacy Policy.'**
  String get identityFooterLegal;

  /// No description provided for @identityTermsLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get identityTermsLink;

  /// No description provided for @identityPrivacyLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get identityPrivacyLink;

  /// No description provided for @identityNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No Internet'**
  String get identityNoInternetTitle;

  /// No description provided for @identityNoInternetMessage.
  ///
  /// In en, this message translates to:
  /// **'For the first access, we need internet to set up your secure account. Please connect and try again.'**
  String get identityNoInternetMessage;

  /// No description provided for @identityTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get identityTryAgain;

  /// No description provided for @identityErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign In Error'**
  String get identityErrorTitle;

  /// No description provided for @identityErrorGoogleCanceled.
  ///
  /// In en, this message translates to:
  /// **'You canceled Google sign in.'**
  String get identityErrorGoogleCanceled;

  /// No description provided for @identityErrorGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to sign in with Google. Try again or use Guest.'**
  String get identityErrorGoogleFailed;

  /// No description provided for @identityErrorAnonymousFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create guest account. Check your connection.'**
  String get identityErrorAnonymousFailed;

  /// No description provided for @drawerHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get drawerHome;

  /// No description provided for @drawerProperties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get drawerProperties;

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

  /// No description provided for @settingsPropertiesAndTalhoes.
  ///
  /// In en, this message translates to:
  /// **'Properties & Field Plots'**
  String get settingsPropertiesAndTalhoes;

  /// No description provided for @settingsPropertiesAndTalhoesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your production sites'**
  String get settingsPropertiesAndTalhoesDesc;

  /// No description provided for @settingsManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get settingsManagement;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'This app is part of the PlanejaCampo Suite, designed to help rural producers manage their activities in the field.'**
  String get aboutDescription;

  /// No description provided for @aboutOfflineFirst.
  ///
  /// In en, this message translates to:
  /// **'100% Offline-First: all your data stays on your device.'**
  String get aboutOfflineFirst;

  /// No description provided for @aboutSuite.
  ///
  /// In en, this message translates to:
  /// **'PlanejaCampo Suite'**
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
  /// **'Data and Location'**
  String get consentShareAggregated;

  /// No description provided for @consentShareAggregatedDesc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentShareAggregatedDesc;

  /// No description provided for @consentReceiveRegionalMetrics.
  ///
  /// In en, this message translates to:
  /// **'Offers and Promotions'**
  String get consentReceiveRegionalMetrics;

  /// No description provided for @consentReceiveRegionalMetricsDesc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentReceiveRegionalMetricsDesc;

  /// No description provided for @consentPersonalizedAds.
  ///
  /// In en, this message translates to:
  /// **'Personalized Ads'**
  String get consentPersonalizedAds;

  /// No description provided for @consentPersonalizedAdsDesc.
  ///
  /// In en, this message translates to:
  /// **''**
  String get consentPersonalizedAdsDesc;

  /// No description provided for @privacySaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get privacySaved;

  /// No description provided for @propertyDefaultName.
  ///
  /// In en, this message translates to:
  /// **'My Property'**
  String get propertyDefaultName;

  /// No description provided for @propertyTitle.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get propertyTitle;

  /// No description provided for @propertyAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get propertyAdd;

  /// No description provided for @propertyEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get propertyEdit;

  /// No description provided for @propertyName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get propertyName;

  /// No description provided for @propertyNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Primavera Farm'**
  String get propertyNameHint;

  /// No description provided for @propertyTotalArea.
  ///
  /// In en, this message translates to:
  /// **'Total Area (ha)'**
  String get propertyTotalArea;

  /// No description provided for @propertyTotalAreaHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: 150.5'**
  String get propertyTotalAreaHint;

  /// No description provided for @propertyLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get propertyLocation;

  /// No description provided for @propertyLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'Used for regional statistics and weather forecast (optional)'**
  String get propertyLocationDesc;

  /// No description provided for @propertyUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get propertyUseCurrentLocation;

  /// No description provided for @propertySetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get propertySetAsDefault;

  /// No description provided for @propertyIsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default property'**
  String get propertyIsDefault;

  /// No description provided for @propertyDefaultBadge.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get propertyDefaultBadge;

  /// No description provided for @propertyDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Property'**
  String get propertyDelete;

  /// No description provided for @propertyDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this property?'**
  String get propertyDeleteConfirm;

  /// No description provided for @propertyDeleteWithRecords.
  ///
  /// In en, this message translates to:
  /// **'This property has linked records. When deleted, all records will be moved to the default property.'**
  String get propertyDeleteWithRecords;

  /// No description provided for @propertyDeleted.
  ///
  /// In en, this message translates to:
  /// **'Property deleted'**
  String get propertyDeleted;

  /// No description provided for @propertyCannotDeleteDefault.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the default property. Set another property as default first.'**
  String get propertyCannotDeleteDefault;

  /// No description provided for @propertyCannotDeleteLast.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the only property. Create another property first.'**
  String get propertyCannotDeleteLast;

  /// No description provided for @propertyNoProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties registered'**
  String get propertyNoProperties;

  /// No description provided for @propertyNoPropertiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first property'**
  String get propertyNoPropertiesDesc;

  /// No description provided for @propertyChangeProperty.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get propertyChangeProperty;

  /// No description provided for @propertySelectProperty.
  ///
  /// In en, this message translates to:
  /// **'Select Property'**
  String get propertySelectProperty;

  /// No description provided for @propertyAllProperties.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get propertyAllProperties;

  /// No description provided for @propertyFilterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by property'**
  String get propertyFilterBy;

  /// No description provided for @propertyFirstTimeTip.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: You can manage properties in Settings'**
  String get propertyFirstTimeTip;

  /// No description provided for @propertySaved.
  ///
  /// In en, this message translates to:
  /// **'Property saved!'**
  String get propertySaved;

  /// No description provided for @propertyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Property updated!'**
  String get propertyUpdated;

  /// No description provided for @propertyNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter property name'**
  String get propertyNameRequired;

  /// No description provided for @propertyNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short (minimum 2 characters)'**
  String get propertyNameTooShort;

  /// No description provided for @propertyNameExists.
  ///
  /// In en, this message translates to:
  /// **'A property with this name already exists'**
  String get propertyNameExists;

  /// No description provided for @propertyAreaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Area must be greater than zero'**
  String get propertyAreaInvalid;

  /// No description provided for @propertyLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get propertyLocationPermissionDenied;

  /// No description provided for @propertyLocationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get propertyLocationUnavailable;

  /// No description provided for @chuvaAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Planeja Chuva'**
  String get chuvaAppTitle;

  /// No description provided for @chuvaListaVaziaTitle.
  ///
  /// In en, this message translates to:
  /// **'No rainfall recorded'**
  String get chuvaListaVaziaTitle;

  /// No description provided for @chuvaListaVaziaSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record your first rainfall'**
  String get chuvaListaVaziaSubtitle;

  /// No description provided for @chuvaAdicionarTitle.
  ///
  /// In en, this message translates to:
  /// **'Record Rainfall'**
  String get chuvaAdicionarTitle;

  /// No description provided for @chuvaEditarTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Record'**
  String get chuvaEditarTitle;

  /// No description provided for @chuvaCampoMilimetros.
  ///
  /// In en, this message translates to:
  /// **'Millimeters (mm)'**
  String get chuvaCampoMilimetros;

  /// No description provided for @chuvaCampoMilimetrosHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: 25.5'**
  String get chuvaCampoMilimetrosHint;

  /// No description provided for @chuvaCampoData.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get chuvaCampoData;

  /// No description provided for @chuvaCampoObservacao.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get chuvaCampoObservacao;

  /// No description provided for @chuvaCampoObservacaoHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Heavy rain in the afternoon'**
  String get chuvaCampoObservacaoHint;

  /// No description provided for @chuvaBotaoSalvar.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get chuvaBotaoSalvar;

  /// No description provided for @chuvaBotaoCancelar.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get chuvaBotaoCancelar;

  /// No description provided for @chuvaBotaoExcluir.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get chuvaBotaoExcluir;

  /// No description provided for @chuvaConfirmarExclusaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete record?'**
  String get chuvaConfirmarExclusaoTitle;

  /// No description provided for @chuvaConfirmarExclusaoMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this rainfall record?'**
  String get chuvaConfirmarExclusaoMsg;

  /// No description provided for @chuvaRegistrada.
  ///
  /// In en, this message translates to:
  /// **'Rainfall of {mm}mm recorded!'**
  String chuvaRegistrada(String mm);

  /// No description provided for @chuvaAtualizada.
  ///
  /// In en, this message translates to:
  /// **'Record updated!'**
  String get chuvaAtualizada;

  /// No description provided for @chuvaExcluida.
  ///
  /// In en, this message translates to:
  /// **'Record deleted'**
  String get chuvaExcluida;

  /// No description provided for @chuvaDesfazer.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get chuvaDesfazer;

  /// No description provided for @chuvaTotalDoMes.
  ///
  /// In en, this message translates to:
  /// **'Month total'**
  String get chuvaTotalDoMes;

  /// No description provided for @chuvaMesAnterior.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get chuvaMesAnterior;

  /// No description provided for @chuvaEstatisticas.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get chuvaEstatisticas;

  /// No description provided for @chuvaEstatisticasTitle.
  ///
  /// In en, this message translates to:
  /// **'Rainfall Statistics'**
  String get chuvaEstatisticasTitle;

  /// No description provided for @chuvaTotalAno.
  ///
  /// In en, this message translates to:
  /// **'Year total'**
  String get chuvaTotalAno;

  /// No description provided for @chuvaMediaPorChuva.
  ///
  /// In en, this message translates to:
  /// **'Average per rain'**
  String get chuvaMediaPorChuva;

  /// No description provided for @chuvaMaiorRegistro.
  ///
  /// In en, this message translates to:
  /// **'Highest record'**
  String get chuvaMaiorRegistro;

  /// No description provided for @chuvaTotalRegistros.
  ///
  /// In en, this message translates to:
  /// **'Total records'**
  String get chuvaTotalRegistros;

  /// No description provided for @chuvaBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get chuvaBackup;

  /// No description provided for @chuvaBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Backup'**
  String get chuvaBackupTitle;

  /// No description provided for @chuvaExportarDados.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get chuvaExportarDados;

  /// No description provided for @chuvaExportarDescricao.
  ///
  /// In en, this message translates to:
  /// **'Generate a file with all your records to save or share.'**
  String get chuvaExportarDescricao;

  /// No description provided for @chuvaImportarDados.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get chuvaImportarDados;

  /// No description provided for @chuvaImportarDescricao.
  ///
  /// In en, this message translates to:
  /// **'Restore records from a backup file.'**
  String get chuvaImportarDescricao;

  /// No description provided for @chuvaExportarSucesso.
  ///
  /// In en, this message translates to:
  /// **'Backup exported successfully!'**
  String get chuvaExportarSucesso;

  /// No description provided for @chuvaImportarSucesso.
  ///
  /// In en, this message translates to:
  /// **'{count} records imported!'**
  String chuvaImportarSucesso(int count);

  /// No description provided for @chuvaImportarDuplicados.
  ///
  /// In en, this message translates to:
  /// **'{count} records imported ({duplicados} duplicates skipped)'**
  String chuvaImportarDuplicados(int count, int duplicados);

  /// No description provided for @chuvaErroValorInvalido.
  ///
  /// In en, this message translates to:
  /// **'Enter a value between 0.1 and 500 mm'**
  String get chuvaErroValorInvalido;

  /// No description provided for @chuvaErroDataObrigatoria.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get chuvaErroDataObrigatoria;

  /// No description provided for @chuvaErroArquivoInvalido.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get chuvaErroArquivoInvalido;

  /// No description provided for @chuvaIntensidadeLeve.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get chuvaIntensidadeLeve;

  /// No description provided for @chuvaIntensidadeModerada.
  ///
  /// In en, this message translates to:
  /// **'Moderate rain'**
  String get chuvaIntensidadeModerada;

  /// No description provided for @chuvaIntensidadeForte.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain'**
  String get chuvaIntensidadeForte;

  /// No description provided for @chuvaSemRegistrosMes.
  ///
  /// In en, this message translates to:
  /// **'No records this month'**
  String get chuvaSemRegistrosMes;

  /// No description provided for @chuvaHoje.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get chuvaHoje;

  /// No description provided for @chuvaOntem.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get chuvaOntem;

  /// No description provided for @chuvaMm.
  ///
  /// In en, this message translates to:
  /// **'mm'**
  String get chuvaMm;

  /// No description provided for @chuvaRegistrosEncontrados.
  ///
  /// In en, this message translates to:
  /// **'{count} records found'**
  String chuvaRegistrosEncontrados(int count);

  /// No description provided for @chuvaConfirmarImportacao.
  ///
  /// In en, this message translates to:
  /// **'Import {count} records?'**
  String chuvaConfirmarImportacao(int count);

  /// No description provided for @chuvaNenhumRegistroBackup.
  ///
  /// In en, this message translates to:
  /// **'No records to export'**
  String get chuvaNenhumRegistroBackup;

  /// No description provided for @chuvaComparacaoMesAcima.
  ///
  /// In en, this message translates to:
  /// **'Above previous month'**
  String get chuvaComparacaoMesAcima;

  /// No description provided for @chuvaComparacaoMesAbaixo.
  ///
  /// In en, this message translates to:
  /// **'Below previous month'**
  String get chuvaComparacaoMesAbaixo;

  /// No description provided for @chuvaStatsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get chuvaStatsTabOverview;

  /// No description provided for @chuvaStatsTabBars.
  ///
  /// In en, this message translates to:
  /// **'Bars'**
  String get chuvaStatsTabBars;

  /// No description provided for @chuvaStatsTabCompare.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get chuvaStatsTabCompare;

  /// No description provided for @chuvaChartComparativeTitle.
  ///
  /// In en, this message translates to:
  /// **'Year Comparison'**
  String get chuvaChartComparativeTitle;

  /// No description provided for @chuvaShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Rainfall recorded at {propertyName}! 🌧️ #PlanejaCampo'**
  String chuvaShareMessage(String propertyName);

  /// No description provided for @chuvaShareError.
  ///
  /// In en, this message translates to:
  /// **'Error sharing'**
  String get chuvaShareError;

  /// No description provided for @chuvaWidgetNoData.
  ///
  /// In en, this message translates to:
  /// **'No recent data'**
  String get chuvaWidgetNoData;

  /// No description provided for @chuvaWidgetUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at {time}'**
  String chuvaWidgetUpdatedAt(String time);

  /// No description provided for @talhaoTitle.
  ///
  /// In en, this message translates to:
  /// **'Field Plots'**
  String get talhaoTitle;

  /// No description provided for @talhaoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Field Plot'**
  String get talhaoAdd;

  /// No description provided for @talhaoEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit Field Plot'**
  String get talhaoEdit;

  /// No description provided for @talhaoDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete Field Plot'**
  String get talhaoDelete;

  /// No description provided for @talhaoName.
  ///
  /// In en, this message translates to:
  /// **'Plot Name'**
  String get talhaoName;

  /// No description provided for @talhaoNameHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Plot A - Soybean'**
  String get talhaoNameHint;

  /// No description provided for @talhaoArea.
  ///
  /// In en, this message translates to:
  /// **'Area (ha)'**
  String get talhaoArea;

  /// No description provided for @talhaoAreaHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: 50.5'**
  String get talhaoAreaHint;

  /// No description provided for @talhaoCultura.
  ///
  /// In en, this message translates to:
  /// **'Crop (optional)'**
  String get talhaoCultura;

  /// No description provided for @talhaoCulturaHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Soybean, Corn, Coffee'**
  String get talhaoCulturaHint;

  /// No description provided for @talhaoListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No field plots registered'**
  String get talhaoListEmpty;

  /// No description provided for @talhaoListEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap + to divide this property into plots'**
  String get talhaoListEmptyDesc;

  /// No description provided for @talhaoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete field plot?'**
  String get talhaoDeleteConfirm;

  /// No description provided for @talhaoDeleteConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this field plot?'**
  String get talhaoDeleteConfirmMsg;

  /// No description provided for @talhaoDeleteWithRecords.
  ///
  /// In en, this message translates to:
  /// **'This field plot has {count} linked record(s). They will be moved to \"Whole Property\".'**
  String talhaoDeleteWithRecords(int count);

  /// No description provided for @talhaoDeleted.
  ///
  /// In en, this message translates to:
  /// **'Field plot deleted'**
  String get talhaoDeleted;

  /// No description provided for @talhaoSaved.
  ///
  /// In en, this message translates to:
  /// **'Field plot saved!'**
  String get talhaoSaved;

  /// No description provided for @talhaoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Field plot updated!'**
  String get talhaoUpdated;

  /// No description provided for @talhaoNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter plot name'**
  String get talhaoNameRequired;

  /// No description provided for @talhaoNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name too short (minimum 2 characters)'**
  String get talhaoNameTooShort;

  /// No description provided for @talhaoNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name too long (maximum 50 characters)'**
  String get talhaoNameTooLong;

  /// No description provided for @talhaoNameExists.
  ///
  /// In en, this message translates to:
  /// **'A field plot with this name already exists in this property'**
  String get talhaoNameExists;

  /// No description provided for @talhaoAreaInvalid.
  ///
  /// In en, this message translates to:
  /// **'Area must be greater than zero'**
  String get talhaoAreaInvalid;

  /// No description provided for @talhaoAreaExceedsProperty.
  ///
  /// In en, this message translates to:
  /// **'The sum of plot areas ({totalTalhoes} ha) exceeds the property\'s total area ({propertyArea} ha)'**
  String talhaoAreaExceedsProperty(String totalTalhoes, String propertyArea);

  /// No description provided for @talhaoSelectOptional.
  ///
  /// In en, this message translates to:
  /// **'Field Plot (optional)'**
  String get talhaoSelectOptional;

  /// No description provided for @talhaoWholeProperty.
  ///
  /// In en, this message translates to:
  /// **'Whole Property'**
  String get talhaoWholeProperty;

  /// No description provided for @talhaoCreateNew.
  ///
  /// In en, this message translates to:
  /// **'+ Create new plot'**
  String get talhaoCreateNew;

  /// No description provided for @talhaoManage.
  ///
  /// In en, this message translates to:
  /// **'Manage Field Plots'**
  String get talhaoManage;

  /// No description provided for @talhaoSummaryDivided.
  ///
  /// In en, this message translates to:
  /// **'{dividedArea} ha divided / {totalArea} ha total ({percentage}% divided)'**
  String talhaoSummaryDivided(String dividedArea, String totalArea, String percentage);

  /// No description provided for @talhaoWithRecords.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s)'**
  String talhaoWithRecords(int count);

  /// No description provided for @talhaoFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All field plots'**
  String get talhaoFilterAll;

  /// No description provided for @talhaoFilterBy.
  ///
  /// In en, this message translates to:
  /// **'Filter by field plot'**
  String get talhaoFilterBy;

  /// No description provided for @talhaoNoSelection.
  ///
  /// In en, this message translates to:
  /// **'No field plot selected'**
  String get talhaoNoSelection;

  /// No description provided for @deleteDataButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my data'**
  String get deleteDataButton;

  /// No description provided for @deleteDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all data?'**
  String get deleteDataTitle;

  /// No description provided for @deleteDataWarning.
  ///
  /// In en, this message translates to:
  /// **'This action is IRREVERSIBLE. All your rainfall records, properties, and settings will be permanently deleted from your device and our servers.'**
  String get deleteDataWarning;

  /// No description provided for @deleteDataConfirmCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I understand I will lose all my records'**
  String get deleteDataConfirmCheckbox;

  /// No description provided for @deleteDataCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get deleteDataCancel;

  /// No description provided for @deleteDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deleteDataConfirm;

  /// No description provided for @deleteDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your data has been deleted successfully.'**
  String get deleteDataSuccess;

  /// No description provided for @deleteDataError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting data. Please try again.'**
  String get deleteDataError;

  /// No description provided for @deleteDataReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'For security, please sign in again before deleting.'**
  String get deleteDataReauthRequired;

  /// No description provided for @exportDataButton.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportDataButton;

  /// No description provided for @exportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get exportDataTitle;

  /// No description provided for @exportDataDescription.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your data in a standard format to use in other services.'**
  String get exportDataDescription;

  /// No description provided for @exportDataJson.
  ///
  /// In en, this message translates to:
  /// **'JSON (complete)'**
  String get exportDataJson;

  /// No description provided for @exportDataCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV (Excel/Spreadsheets)'**
  String get exportDataCsv;

  /// No description provided for @exportDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data exported successfully!'**
  String get exportDataSuccess;

  /// No description provided for @exportDataError.
  ///
  /// In en, this message translates to:
  /// **'Error exporting data.'**
  String get exportDataError;

  /// No description provided for @revokeAllButton.
  ///
  /// In en, this message translates to:
  /// **'Revoke All and Sign Out'**
  String get revokeAllButton;

  /// No description provided for @revokeAllTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke all consents?'**
  String get revokeAllTitle;

  /// No description provided for @revokeAllMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove all your consents and end your session. Your local data will be kept.'**
  String get revokeAllMessage;

  /// No description provided for @alertFrostTitle.
  ///
  /// In en, this message translates to:
  /// **'Frost Risk'**
  String get alertFrostTitle;

  /// No description provided for @alertFrostMessage.
  ///
  /// In en, this message translates to:
  /// **'Temperatures below 3°C. Protect sensitive crops.'**
  String get alertFrostMessage;

  /// No description provided for @alertHeatWaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Heat Wave'**
  String get alertHeatWaveTitle;

  /// No description provided for @alertHeatWaveMessage.
  ///
  /// In en, this message translates to:
  /// **'Temperatures above 35°C. Monitor hydration and heat stress.'**
  String get alertHeatWaveMessage;

  /// No description provided for @alertStormTitle.
  ///
  /// In en, this message translates to:
  /// **'Storm Alert'**
  String get alertStormTitle;

  /// No description provided for @alertStormMessage.
  ///
  /// In en, this message translates to:
  /// **'Heavy rain or strong winds forecast.'**
  String get alertStormMessage;

  /// No description provided for @alertDroughtTitle.
  ///
  /// In en, this message translates to:
  /// **'Drought Alert'**
  String get alertDroughtTitle;

  /// No description provided for @alertDroughtMessage.
  ///
  /// In en, this message translates to:
  /// **'No significant rain forecast for the next 7 days.'**
  String get alertDroughtMessage;

  /// No description provided for @alertHighWindTitle.
  ///
  /// In en, this message translates to:
  /// **'High Winds'**
  String get alertHighWindTitle;

  /// No description provided for @alertHighWindMessage.
  ///
  /// In en, this message translates to:
  /// **'Wind gusts above 45km/h expected.'**
  String get alertHighWindMessage;

  /// No description provided for @alertHailTitle.
  ///
  /// In en, this message translates to:
  /// **'Hail Alert'**
  String get alertHailTitle;

  /// No description provided for @alertHailMessage.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm with hail forecast. Protect vehicles and structures.'**
  String get alertHailMessage;

  /// No description provided for @alertsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather Alerts'**
  String get alertsSectionTitle;

  /// No description provided for @migrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Account already exists'**
  String get migrationTitle;

  /// No description provided for @migrationMessage.
  ///
  /// In en, this message translates to:
  /// **'This Google account already has data. Do you want to transfer your current records to it?'**
  String get migrationMessage;

  /// No description provided for @migrationTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer Data'**
  String get migrationTransfer;

  /// No description provided for @migrationCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get migrationCancel;

  /// No description provided for @migrationProgress.
  ///
  /// In en, this message translates to:
  /// **'Migrating data...'**
  String get migrationProgress;

  /// No description provided for @migrationProgressProperties.
  ///
  /// In en, this message translates to:
  /// **'Transferring properties...'**
  String get migrationProgressProperties;

  /// No description provided for @migrationProgressTalhoes.
  ///
  /// In en, this message translates to:
  /// **'Transferring field plots...'**
  String get migrationProgressTalhoes;

  /// No description provided for @migrationProgressRecords.
  ///
  /// In en, this message translates to:
  /// **'Transferring records...'**
  String get migrationProgressRecords;

  /// No description provided for @migrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Migration completed successfully!'**
  String get migrationSuccess;

  /// No description provided for @migrationError.
  ///
  /// In en, this message translates to:
  /// **'Error during migration. Your original data has been preserved.'**
  String get migrationError;

  /// No description provided for @weatherClearSky.
  ///
  /// In en, this message translates to:
  /// **'Clear sky'**
  String get weatherClearSky;

  /// No description provided for @weatherPartlyCloudy.
  ///
  /// In en, this message translates to:
  /// **'Partly cloudy'**
  String get weatherPartlyCloudy;

  /// No description provided for @weatherFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get weatherFog;

  /// No description provided for @weatherLightRain.
  ///
  /// In en, this message translates to:
  /// **'Light rain'**
  String get weatherLightRain;

  /// No description provided for @weatherShowers.
  ///
  /// In en, this message translates to:
  /// **'Rain showers'**
  String get weatherShowers;

  /// No description provided for @weatherThunderstorm.
  ///
  /// In en, this message translates to:
  /// **'Thunderstorm'**
  String get weatherThunderstorm;

  /// No description provided for @weatherCloudy.
  ///
  /// In en, this message translates to:
  /// **'Cloudy'**
  String get weatherCloudy;

  /// No description provided for @weatherForecastFor.
  ///
  /// In en, this message translates to:
  /// **'Forecast for: {propertyName}'**
  String weatherForecastFor(String propertyName);

  /// No description provided for @weatherNow.
  ///
  /// In en, this message translates to:
  /// **'Weather Now'**
  String get weatherNow;

  /// No description provided for @weatherSeeDetails.
  ///
  /// In en, this message translates to:
  /// **'See Details'**
  String get weatherSeeDetails;

  /// No description provided for @weatherLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Required'**
  String get weatherLocationRequired;

  /// No description provided for @weatherLocationRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap here if you\'re at the property to enable the forecast.'**
  String get weatherLocationRequiredDesc;

  /// No description provided for @weatherConsentRequired.
  ///
  /// In en, this message translates to:
  /// **'Consent Required'**
  String get weatherConsentRequired;

  /// No description provided for @weatherConsentRequiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Tap to authorize location usage and see the forecast.'**
  String get weatherConsentRequiredDesc;

  /// No description provided for @weatherActivateForecast.
  ///
  /// In en, this message translates to:
  /// **'Activate Weather Forecast'**
  String get weatherActivateForecast;

  /// No description provided for @weatherActivateForecastMessage.
  ///
  /// In en, this message translates to:
  /// **'To show the correct forecast, we need this property\'s location.\n\nAre you at the property now?'**
  String get weatherActivateForecastMessage;

  /// No description provided for @weatherNotHere.
  ///
  /// In en, this message translates to:
  /// **'No, I\'m far away'**
  String get weatherNotHere;

  /// No description provided for @weatherYesHere.
  ///
  /// In en, this message translates to:
  /// **'Yes, I\'m here'**
  String get weatherYesHere;

  /// No description provided for @weatherSetLocation.
  ///
  /// In en, this message translates to:
  /// **'Set Location'**
  String get weatherSetLocation;

  /// No description provided for @weatherSetLocationMessage.
  ///
  /// In en, this message translates to:
  /// **'No problem. Would you prefer to set the coordinates manually now or later?'**
  String get weatherSetLocationMessage;

  /// No description provided for @weatherLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get weatherLater;

  /// No description provided for @weatherSetManually.
  ///
  /// In en, this message translates to:
  /// **'Set Manually'**
  String get weatherSetManually;

  /// No description provided for @weatherErrorServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service disabled.'**
  String get weatherErrorServiceDisabled;

  /// No description provided for @weatherErrorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied.'**
  String get weatherErrorPermissionDenied;

  /// No description provided for @weatherErrorPermissionDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Permission permanently denied. Enable in settings.'**
  String get weatherErrorPermissionDeniedForever;

  /// No description provided for @weatherLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated! Loading forecast...'**
  String get weatherLocationUpdated;

  /// No description provided for @weatherErrorGettingLocation.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String weatherErrorGettingLocation(String error);

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeFollowsSystem.
  ///
  /// In en, this message translates to:
  /// **'Follows system'**
  String get settingsThemeFollowsSystem;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsReminderDailyAt.
  ///
  /// In en, this message translates to:
  /// **'Daily at {time}'**
  String settingsReminderDailyAt(String time);

  /// No description provided for @settingsReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settingsReminderDisabled;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get settingsReminderTime;

  /// No description provided for @backupCloudSection.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get backupCloudSection;

  /// No description provided for @backupCloudDescription.
  ///
  /// In en, this message translates to:
  /// **'Securely sync your data with your Google account'**
  String get backupCloudDescription;

  /// No description provided for @backupCloudNow.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupCloudNow;

  /// No description provided for @backupCloudLastBackup.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backupCloudLastBackup(String date);

  /// No description provided for @backupCloudNeverDone.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get backupCloudNeverDone;

  /// No description provided for @backupCloudRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore from Cloud'**
  String get backupCloudRestore;

  /// No description provided for @backupCloudRestoreDesc.
  ///
  /// In en, this message translates to:
  /// **'Replaces local data with backup'**
  String get backupCloudRestoreDesc;

  /// No description provided for @backupCloudSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup completed successfully!'**
  String get backupCloudSuccess;

  /// No description provided for @backupCloudRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully!'**
  String get backupCloudRestoreSuccess;

  /// No description provided for @backupCloudError.
  ///
  /// In en, this message translates to:
  /// **'Backup error: {error}'**
  String backupCloudError(String error);

  /// No description provided for @backupCloudRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Restore error: {error}'**
  String backupCloudRestoreError(String error);

  /// No description provided for @backupCloudSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to use cloud backup'**
  String get backupCloudSignInRequired;

  /// No description provided for @backupCloudSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get backupCloudSignInButton;

  /// No description provided for @backupCloudAnonymousWarning.
  ///
  /// In en, this message translates to:
  /// **'Create a Google account to save your data to the cloud'**
  String get backupCloudAnonymousWarning;

  /// No description provided for @backupLocalSection.
  ///
  /// In en, this message translates to:
  /// **'Local Backup'**
  String get backupLocalSection;

  /// No description provided for @backupLocalExport.
  ///
  /// In en, this message translates to:
  /// **'Export to File'**
  String get backupLocalExport;

  /// No description provided for @backupLocalExportDesc.
  ///
  /// In en, this message translates to:
  /// **'Save data to your device'**
  String get backupLocalExportDesc;

  /// No description provided for @backupLocalImport.
  ///
  /// In en, this message translates to:
  /// **'Import from File'**
  String get backupLocalImport;

  /// No description provided for @backupLocalImportDesc.
  ///
  /// In en, this message translates to:
  /// **'Restore from a local file'**
  String get backupLocalImportDesc;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsManageConsents.
  ///
  /// In en, this message translates to:
  /// **'Manage Consents'**
  String get settingsManageConsents;

  /// No description provided for @settingsSyncPrefs.
  ///
  /// In en, this message translates to:
  /// **'Sync Preferences'**
  String get settingsSyncPrefs;

  /// No description provided for @settingsSyncPrefsDesc.
  ///
  /// In en, this message translates to:
  /// **'Theme and basic settings'**
  String get settingsSyncPrefsDesc;

  /// No description provided for @settingsExportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get settingsExportMyData;

  /// No description provided for @settingsExportMyDataDesc.
  ///
  /// In en, this message translates to:
  /// **'LGPD/GDPR - Data portability'**
  String get settingsExportMyDataDesc;

  /// No description provided for @settingsDeleteCloudData.
  ///
  /// In en, this message translates to:
  /// **'Delete Cloud Data'**
  String get settingsDeleteCloudData;

  /// No description provided for @settingsDeleteCloudDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Keeps local data'**
  String get settingsDeleteCloudDataDesc;

  /// No description provided for @rainNoRainNextHour.
  ///
  /// In en, this message translates to:
  /// **'No rain in the next hour'**
  String get rainNoRainNextHour;

  /// No description provided for @rainRainingNow.
  ///
  /// In en, this message translates to:
  /// **'Raining now'**
  String get rainRainingNow;

  /// No description provided for @rainStartingIn15.
  ///
  /// In en, this message translates to:
  /// **'Rain starting in ~15 min'**
  String get rainStartingIn15;

  /// No description provided for @rainStartingIn30.
  ///
  /// In en, this message translates to:
  /// **'Rain starting in ~30 min'**
  String get rainStartingIn30;

  /// No description provided for @rainStartingIn45.
  ///
  /// In en, this message translates to:
  /// **'Rain starting in ~45 min'**
  String get rainStartingIn45;

  /// No description provided for @rainNextHour.
  ///
  /// In en, this message translates to:
  /// **'Rain in the next hour'**
  String get rainNextHour;

  /// No description provided for @settingsRainAlerts.
  ///
  /// In en, this message translates to:
  /// **'Rain Alerts'**
  String get settingsRainAlerts;

  /// No description provided for @settingsRainAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Get notified before it rains'**
  String get settingsRainAlertsDesc;

  /// No description provided for @notificationRainTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain starting soon!'**
  String get notificationRainTitle;

  /// No description provided for @notificationRainBody.
  ///
  /// In en, this message translates to:
  /// **'Rain expected to start in {minutes} min.'**
  String notificationRainBody(Object minutes);

  /// No description provided for @notificationRainBodyWithProperty.
  ///
  /// In en, this message translates to:
  /// **'Rain expected in {minutes} min at {propertyName}.'**
  String notificationRainBodyWithProperty(int minutes, String propertyName);

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Rain Alerts'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'Notifies when heavy rain is approaching'**
  String get notificationChannelDesc;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Notification permission required'**
  String get notificationPermissionRequired;

  /// No description provided for @heatmapTitle.
  ///
  /// In en, this message translates to:
  /// **'Rain Heatmap'**
  String get heatmapTitle;

  /// No description provided for @heatmapLegendLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get heatmapLegendLight;

  /// No description provided for @heatmapLegendModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get heatmapLegendModerate;

  /// No description provided for @heatmapLegendHeavy.
  ///
  /// In en, this message translates to:
  /// **'Heavy'**
  String get heatmapLegendHeavy;

  /// No description provided for @heatmapNoData.
  ///
  /// In en, this message translates to:
  /// **'Insufficient data for this region'**
  String get heatmapNoData;

  /// No description provided for @heatmapFilter1h.
  ///
  /// In en, this message translates to:
  /// **'1h'**
  String get heatmapFilter1h;

  /// No description provided for @heatmapFilter24h.
  ///
  /// In en, this message translates to:
  /// **'24h'**
  String get heatmapFilter24h;

  /// No description provided for @heatmapFilter7d.
  ///
  /// In en, this message translates to:
  /// **'7d'**
  String get heatmapFilter7d;

  /// No description provided for @drawerHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Rain Map'**
  String get drawerHeatmap;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @deleteCloudDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete cloud data?'**
  String get deleteCloudDataTitle;

  /// No description provided for @deleteCloudDataMessage.
  ///
  /// In en, this message translates to:
  /// **'This will remove your synced data from the cloud. Local data on your device will be kept. You can sync again in the future if you wish.'**
  String get deleteCloudDataMessage;

  /// No description provided for @deleteCloudDataSuccess.
  ///
  /// In en, this message translates to:
  /// **'Cloud data deleted successfully'**
  String get deleteCloudDataSuccess;
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
