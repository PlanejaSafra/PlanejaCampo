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

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerPrivacy => 'Privacy and Consents';

  @override
  String get drawerAbout => 'About';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageAuto => 'Automatic';

  @override
  String get settingsAboutApp => 'About the App';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription => 'This app is part of the PlanejaSafra Suite, designed to help rural producers manage their activities in the field.';

  @override
  String get aboutOfflineFirst => '100% Offline-First: all your data stays on your device.';

  @override
  String get aboutSuite => 'PlanejaSafra Suite';

  @override
  String get aboutVersion => 'Version';

  @override
  String get privacyTitle => 'Privacy and Consents';

  @override
  String get privacyTermsSection => 'Terms of Use and Privacy Policy';

  @override
  String get privacyTermsSummary => 'By using this app, you agree to our Terms of Use and Privacy Policy. You can review the full documents at any time.';

  @override
  String get privacyConsentsSection => 'Data Sharing Consents';

  @override
  String get privacyConsentsDescription => 'Manage how your data can be used. All options are optional.';

  @override
  String get consentShareAggregated => 'Share aggregated data';

  @override
  String get consentShareAggregatedDesc => 'Allow your records to be used anonymously for regional statistics.';

  @override
  String get consentReceiveRegionalMetrics => 'Receive regional metrics';

  @override
  String get consentReceiveRegionalMetricsDesc => 'Get insights based on aggregated community data.';

  @override
  String get consentPersonalizedAds => 'Personalized ads';

  @override
  String get consentPersonalizedAdsDesc => 'See more relevant ads based on your usage.';

  @override
  String get privacySaved => 'Preferences saved';

  @override
  String get chuvaAppTitle => 'Planeja Chuva';

  @override
  String get chuvaListaVaziaTitle => 'No rainfall recorded';

  @override
  String get chuvaListaVaziaSubtitle => 'Tap + to record your first rainfall';

  @override
  String get chuvaAdicionarTitle => 'Record Rainfall';

  @override
  String get chuvaEditarTitle => 'Edit Record';

  @override
  String get chuvaCampoMilimetros => 'Millimeters (mm)';

  @override
  String get chuvaCampoMilimetrosHint => 'E.g.: 25.5';

  @override
  String get chuvaCampoData => 'Date';

  @override
  String get chuvaCampoObservacao => 'Note (optional)';

  @override
  String get chuvaCampoObservacaoHint => 'E.g.: Heavy rain in the afternoon';

  @override
  String get chuvaBotaoSalvar => 'SAVE';

  @override
  String get chuvaBotaoCancelar => 'CANCEL';

  @override
  String get chuvaBotaoExcluir => 'DELETE';

  @override
  String get chuvaConfirmarExclusaoTitle => 'Delete record?';

  @override
  String get chuvaConfirmarExclusaoMsg => 'Are you sure you want to delete this rainfall record?';

  @override
  String chuvaRegistrada(String mm) {
    return 'Rainfall of ${mm}mm recorded!';
  }

  @override
  String get chuvaAtualizada => 'Record updated!';

  @override
  String get chuvaExcluida => 'Record deleted';

  @override
  String get chuvaDesfazer => 'UNDO';

  @override
  String get chuvaTotalDoMes => 'Month total';

  @override
  String get chuvaMesAnterior => 'Previous month';

  @override
  String get chuvaEstatisticas => 'Statistics';

  @override
  String get chuvaEstatisticasTitle => 'Rainfall Statistics';

  @override
  String get chuvaTotalAno => 'Year total';

  @override
  String get chuvaMediaPorChuva => 'Average per rain';

  @override
  String get chuvaMaiorRegistro => 'Highest record';

  @override
  String get chuvaTotalRegistros => 'Total records';

  @override
  String get chuvaBackup => 'Backup';

  @override
  String get chuvaBackupTitle => 'Data Backup';

  @override
  String get chuvaExportarDados => 'Export data';

  @override
  String get chuvaExportarDescricao => 'Generate a file with all your records to save or share.';

  @override
  String get chuvaImportarDados => 'Import data';

  @override
  String get chuvaImportarDescricao => 'Restore records from a backup file.';

  @override
  String get chuvaExportarSucesso => 'Backup exported successfully!';

  @override
  String chuvaImportarSucesso(int count) {
    return '$count records imported!';
  }

  @override
  String chuvaImportarDuplicados(int count, int duplicados) {
    return '$count records imported ($duplicados duplicates skipped)';
  }

  @override
  String get chuvaErroValorInvalido => 'Enter a value between 0.1 and 500 mm';

  @override
  String get chuvaErroDataObrigatoria => 'Select a date';

  @override
  String get chuvaErroArquivoInvalido => 'Invalid backup file';

  @override
  String get chuvaIntensidadeLeve => 'Light rain';

  @override
  String get chuvaIntensidadeModerada => 'Moderate rain';

  @override
  String get chuvaIntensidadeForte => 'Heavy rain';

  @override
  String get chuvaSemRegistrosMes => 'No records this month';

  @override
  String get chuvaHoje => 'Today';

  @override
  String get chuvaOntem => 'Yesterday';

  @override
  String get chuvaMm => 'mm';

  @override
  String chuvaRegistrosEncontrados(int count) {
    return '$count records found';
  }

  @override
  String chuvaConfirmarImportacao(int count) {
    return 'Import $count records?';
  }

  @override
  String get chuvaNenhumRegistroBackup => 'No records to export';

  @override
  String get chuvaComparacaoMesAcima => 'Above previous month';

  @override
  String get chuvaComparacaoMesAbaixo => 'Below previous month';
}
