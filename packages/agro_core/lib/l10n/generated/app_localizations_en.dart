import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AgroLocalizationsEn extends AgroLocalizations {
  AgroLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'PlanejaCampo';

  @override
  String get continueLabel => 'CONTINUE';

  @override
  String get acceptAndContinueLabel => 'ACCEPT AND CONTINUE';

  @override
  String get acceptAllButton => 'ACCEPT ALL AND CONTINUE';

  @override
  String get confirmSelectionButton => 'CONFIRM AND CONTINUE';

  @override
  String get declineLabel => 'DECLINE';

  @override
  String get declineAndExitLabel => 'DECLINE (EXIT)';

  @override
  String get privacySettingsHint => 'You can review the full documents in Settings → Privacy.';

  @override
  String get termsTitle => 'Terms of Use and Privacy';

  @override
  String get termsBodyIntro => 'By tapping \"Accept and Continue\", you agree to the Terms of Use and Privacy Policy of PlanejaCampo apps.';

  @override
  String get termsSummaryTitle => 'Summary of what happens:';

  @override
  String get termsSummaryItem1 => 'This app is a decision support and calculation tool. It provides simulations and estimates based on algorithms that do NOT replace professional evaluation by a technician or agronomist, and the developer is not responsible for any results obtained in the field.';

  @override
  String get termsSummaryItem2 => 'By default, your operational data stays on the device (Local Mode). If you choose to enable Backup, Business Network, or Intelligence — even as a guest — your data will be sent to our servers as described in each option.';

  @override
  String get termsSummaryItem3 => 'The app may display ads in the free version.';

  @override
  String get termsFooter => 'You can view the full documents in Settings → Privacy.';

  @override
  String get termsSection1Title => '1. Acceptance of Terms';

  @override
  String get termsSection1Body => 'By using the PlanejaCampo family of apps (including PlanejaChuva, PlanejaBorracha, PlanejaDiesel, and others), you agree to these Terms of Use. If you do not agree with any part of these terms, you must not use our services.';

  @override
  String get termsSection2Title => '2. Service Description';

  @override
  String get termsSection2Body => 'PlanejaCampo apps are agricultural management tools that allow:\n\n• Recording and tracking agricultural data (rainfall, production, etc.)\n• Managing rural properties\n• Viewing statistics and metrics\n• Cloud backup and data synchronization (optional)\n• Sharing aggregated data for research (optional)\n• Access to Market Intelligence and Business Ecosystem features (optional)';

  @override
  String get termsSection3Title => '3. User Account';

  @override
  String get termsSection3Body => 'You can use our apps in two ways:\n\n• Guest Mode (Hybrid): No Google login. By default, operational data (rain/livestock) stays on the device. Technical metadata and IDs are sent to servers for security and ads. **If you choose to enable Business Network or Intelligence**, your data will be sent to our servers even without login.\n• Connected Mode (Google): Unlocks the Full Ecosystem, allowing secure cloud storage, synchronization, data recovery, and easier access to Network and Intelligence features.\n\nIn both modes, you control which data you share through consent options. You are responsible for maintaining the confidentiality of your account and for all activities that occur under your account.';

  @override
  String get termsSection4Title => '4. Property and Storage (Hybrid Model)';

  @override
  String get termsSection4Body => 'The entered data belongs to you.\nWe use a **Hybrid** architecture:\n\n• **Local Base:** Your data stays on the device to ensure offline operation.\n• **Cloud Sync:** When using connected features (Google Login, Backup, Network), your data is **automatically replicated** on our secure servers (Google Cloud/Firebase).\n\nThis provides security against device loss and multi-device access. By logging in, you agree to this remote storage of your collections and profile data.';

  @override
  String get termsSection5Title => '5. Acceptable Use';

  @override
  String get termsSection5Body => 'By using our services, you agree NOT to:\n\n• Violate applicable laws or regulations\n• Attempt to access or interfere with other users\' systems\n• Use the service for fraudulent or deceptive activities\n• Overload or damage the service infrastructure\n• Reverse engineer or attempt to extract source code';

  @override
  String get termsSection6Title => '6. Limitation of Liability (Total Shield)';

  @override
  String get termsSection6Body => 'TOTAL AND COMPREHENSIVE LIABILITY WAIVER:\nThe apps are MATHEMATICAL SIMULATION and CONNECTION tools. They DO NOT replace professional judgment and DO NOT guarantee the integrity of third parties.\n\nWe are NOT liable, under any circumstances, for:\n• Crop loss, animal death, or financial losses resulting from management decisions\n• Calculation, dosage, diagnosis, or weather forecast errors (simulations)\n• FINANCIAL TRANSACTIONS: Default, fraud, non-payment, chargebacks, or financial crimes (PIX, Wire Transfer) between users\n• DIGITAL SECURITY: Phishing, password theft, or scams applied by other users via chat or external links\n• PHYSICAL WORLD EVENTS: Accidents, assaults, or material damage occurring before, during, or after in-person meetings\n\nThe use of information and the decision to close any deal is the sole and exclusive risk of the user.';

  @override
  String get termsSection7Title => '7. Service Modifications';

  @override
  String get termsSection7Body => 'We reserve the right to:\n\n• Modify or discontinue features at any time\n• Update these Terms of Use\n• Suspend or terminate accounts that violate terms\n\nWe will notify you of significant changes through the app.';

  @override
  String get termsSection8Title => '8. Intellectual Property';

  @override
  String get termsSection8Body => 'All content, design, code, and functionality of PlanejaCampo apps are protected by copyright and other intellectual property laws. You may not copy, modify, or distribute our software without authorization.';

  @override
  String get termsSection9Title => '9. Applicable Law';

  @override
  String get termsSection9Body => 'These terms are governed by the laws of Brazil. Any disputes will be resolved in the competent courts of Brazil.';

  @override
  String get termsSection10Title => '10. Location Collection';

  @override
  String get termsSection10Body => 'The app may collect your approximate or precise location (GPS) for specific features, such as weather forecast and regional statistics. By using these features, you authorize the collection and use of this data. You can revoke location access in your device settings at any time.';

  @override
  String get termsSection11Title => '11. Contact';

  @override
  String get termsSection11Body => 'For questions about these Terms of Use, contact us via the Settings > About menu in the app.';

  @override
  String get consentTitle => 'Privacy Configuration';

  @override
  String get consentIntro => 'Choose how PlanejaCampo should work for you:';

  @override
  String get consentOption1Title => 'Cloud Backup & Sync';

  @override
  String get consentOption1Desc => 'Save data to the cloud for security and team access.';

  @override
  String get consentOption1Legal => 'By activating this (available only with Google login), your data (such as production records, inventory, tasks, and other operational data) will be sent to our secure servers and linked to your account. This allows you to recover everything if you lose your phone and enables authorized collaborators to access the same data. This data is NOT made public.';

  @override
  String get consentOption2Title => 'Business Network & Opportunities';

  @override
  String get consentOption2Desc => 'Enables viewing vacancies and offers (Digital Showcase).';

  @override
  String get consentOption2Legal => 'This option activates social features (Market, Jobs, Classifieds, etc.) and is available for both guests and logged-in users. By creating an ad, you agree to make your contact details (Name/WhatsApp) and offer location public within the platform. Your data will be sent to our servers. The app is merely a connection facilitator.';

  @override
  String get consentOptionSocialLearnMore => 'Enables the DIGITAL BUSINESS ECOSYSTEM. The app is a CONNECTION PLATFORM and does not guarantee transactions.\n\nTOTAL LIABILITY WAIVER:\n1. PHYSICAL SECURITY: We are not responsible for assaults, accidents, or crimes occurring in face-to-face meetings;\n2. FINANCIAL AND DIGITAL SECURITY: We are not responsible for bank transactions, PIX, non-payment, fraud, digital scams, or phishing occurring inside or outside the platform;\n3. LABOR RELATIONS: We do not check links or backgrounds.\nThe responsibility for any financial transaction or hiring is 100% YOURS.';

  @override
  String get safetyWarningMessage => 'SAFETY TIP: When scheduling in-person visits, check the person\'s references and let a family member know. PlanejaCampo does not check users\' criminal backgrounds.';

  @override
  String get consentOption3Title => 'Agronomic & Market Intelligence';

  @override
  String get consentOption3Desc => 'Enables maps, price averages, and advanced technical suggestion tools (fertilization, management, weather).';

  @override
  String get consentOption3Legal => 'This option unlocks collective intelligence features (such as seeing where it rained in the region, average prices, and other regional metrics) and is available for both guests and logged-in users. In exchange, your data (anonymized or aggregated) will be sent to our servers and makes up our market intelligence base. Without this permission, you will not have access to regional maps and averages.';

  @override
  String get consentOptionIntelligenceLearnMore => 'This unlocks collective intelligence features and decision support tools. In exchange, your anonymized data composes our base.\n\nTOTAL TECHNICAL AND AGRONOMIC LIABILITY WAIVER:\nAll management suggestions, fertilization/liming calculations, pesticide indications, crop forecasts, or diagnoses generated by the system are SIMULATIONS based on mathematical and statistical algorithms.\n\nThe app does NOT replace face-to-face consulting or the issuance of an Agronomic Prescription by a qualified Agronomist, as required by law. The app is NOT liable for:\n1. Dosing errors, phytotoxicity, or product inefficiency;\n2. Environmental damage, soil/water contamination, or crop death;\n3. Chemical incompatibility of mixtures;\n4. Losses due to pests, diseases, or unforeseen weather.\n\nThe decision to apply any input or technique is the sole and exclusive responsibility of the user, who assumes all technical, environmental, and financial risks.';

  @override
  String get consentSmallNoteUnderDecline => 'Without accepting, you can use the app normally in private mode (basic offline features).';

  @override
  String get identityTitle => 'Welcome to PlanejaCampo';

  @override
  String get identitySlogan => 'Manage your farm intelligently';

  @override
  String get identityGoogleButton => 'Sign in with Google';

  @override
  String get identityAnonymousButton => 'Continue as Guest';

  @override
  String get identityFooterLegal => 'Your data is private by default. We do not sell personally identifiable data. The use of data for market statistics and partnerships occurs only with your authorization in Intelligence modules.';

  @override
  String get identityTermsLink => 'Terms of Use';

  @override
  String get identityPrivacyLink => 'Privacy Policy';

  @override
  String get identityNoInternetTitle => 'No Internet';

  @override
  String get identityNoInternetMessage => 'For the first access, we need internet to set up your secure account. Please connect and try again.';

  @override
  String get identityTryAgain => 'Try Again';

  @override
  String get identityErrorTitle => 'Sign In Error';

  @override
  String get identityErrorGoogleCanceled => 'You canceled Google sign in.';

  @override
  String get identityErrorGoogleFailed => 'Failed to sign in with Google. Try again or use Guest.';

  @override
  String get identityErrorAnonymousFailed => 'Failed to create guest account. Check your connection.';

  @override
  String get drawerHome => 'Home';

  @override
  String get drawerProperties => 'Properties';

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
  String get settingsPropertiesAndTalhoes => 'Properties & Field Plots';

  @override
  String get settingsPropertiesAndTalhoesDesc => 'Manage your production sites';

  @override
  String get settingsManagement => 'Management';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutDescription => 'This app is part of the PlanejaCampo Suite, designed to help rural producers manage their activities in the field.';

  @override
  String get aboutOfflineFirst => 'Offline-First by default: your data stays on the device. Optional features may sync with the cloud.';

  @override
  String get aboutSuite => 'PlanejaCampo Suite';

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
  String get consentShareAggregated => 'Data and Location';

  @override
  String get consentShareAggregatedDesc => '';

  @override
  String get consentReceiveRegionalMetrics => 'Offers and Promotions';

  @override
  String get consentReceiveRegionalMetricsDesc => '';

  @override
  String get consentPersonalizedAds => 'Personalized Ads';

  @override
  String get consentPersonalizedAdsDesc => '';

  @override
  String get privacySaved => 'Preferences saved';

  @override
  String get propertyDefaultName => 'My Property';

  @override
  String get propertyTitle => 'Properties';

  @override
  String get propertyAdd => 'Add Property';

  @override
  String get propertyEdit => 'Edit Property';

  @override
  String get propertyName => 'Name';

  @override
  String get propertyNameHint => 'E.g.: Primavera Farm';

  @override
  String get propertyTotalArea => 'Total Area (ha)';

  @override
  String get propertyTotalAreaHint => 'E.g.: 150.5';

  @override
  String get propertyLocation => 'Location';

  @override
  String get propertyLocationDesc => 'Used for regional statistics and weather forecast (optional)';

  @override
  String get propertyUseCurrentLocation => 'Use my location';

  @override
  String get propertySetAsDefault => 'Set as default';

  @override
  String get propertyIsDefault => 'Default property';

  @override
  String get propertyDefaultBadge => 'Default';

  @override
  String get propertyDelete => 'Delete Property';

  @override
  String get propertyDeleteConfirm => 'Are you sure you want to delete this property?';

  @override
  String get propertyDeleteWithRecords => 'This property has linked records. When deleted, all records will be moved to the default property.';

  @override
  String get propertyDeleted => 'Property deleted';

  @override
  String get propertyCannotDeleteDefault => 'Cannot delete the default property. Set another property as default first.';

  @override
  String get propertyCannotDeleteLast => 'Cannot delete the only property. Create another property first.';

  @override
  String get propertyNoProperties => 'No properties registered';

  @override
  String get propertyNoPropertiesDesc => 'Tap + to add your first property';

  @override
  String get propertyChangeProperty => 'Change';

  @override
  String get propertySelectProperty => 'Select Property';

  @override
  String get propertyAllProperties => 'All';

  @override
  String get propertyFilterBy => 'Filter by property';

  @override
  String get propertyFirstTimeTip => '💡 Tip: You can manage properties in Settings';

  @override
  String get propertySaved => 'Property saved!';

  @override
  String get propertyUpdated => 'Property updated!';

  @override
  String get propertyNameRequired => 'Enter property name';

  @override
  String get propertyNameTooShort => 'Name too short (minimum 2 characters)';

  @override
  String get propertyNameExists => 'A property with this name already exists';

  @override
  String get propertyAreaInvalid => 'Area must be greater than zero';

  @override
  String get propertyLocationPermissionDenied => 'Location permission denied';

  @override
  String get propertyLocationUnavailable => 'Could not get your location';

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

  @override
  String get chuvaStatsTabOverview => 'Overview';

  @override
  String get chuvaStatsTabBars => 'Bars';

  @override
  String get chuvaStatsTabCompare => 'Compare';

  @override
  String get chuvaChartComparativeTitle => 'Year Comparison';

  @override
  String chuvaShareMessage(String propertyName) {
    return 'Rainfall recorded at $propertyName! 🌧️ #PlanejaCampo';
  }

  @override
  String get chuvaShareError => 'Error sharing';

  @override
  String get chuvaWidgetNoData => 'No recent data';

  @override
  String chuvaWidgetUpdatedAt(String time) {
    return 'Updated at $time';
  }

  @override
  String get talhaoTitle => 'Field Plots';

  @override
  String get talhaoAdd => 'Add Field Plot';

  @override
  String get talhaoEdit => 'Edit Field Plot';

  @override
  String get talhaoDelete => 'Delete Field Plot';

  @override
  String get talhaoName => 'Plot Name';

  @override
  String get talhaoNameHint => 'E.g.: Plot A - Soybean';

  @override
  String get talhaoArea => 'Area (ha)';

  @override
  String get talhaoAreaHint => 'E.g.: 50.5';

  @override
  String get talhaoCultura => 'Crop (optional)';

  @override
  String get talhaoCulturaHint => 'E.g.: Soybean, Corn, Coffee';

  @override
  String get talhaoListEmpty => 'No field plots registered';

  @override
  String get talhaoListEmptyDesc => 'Tap + to divide this property into plots';

  @override
  String get talhaoDeleteConfirm => 'Delete field plot?';

  @override
  String get talhaoDeleteConfirmMsg => 'Are you sure you want to delete this field plot?';

  @override
  String talhaoDeleteWithRecords(int count) {
    return 'This field plot has $count linked record(s). They will be moved to \"Whole Property\".';
  }

  @override
  String get talhaoDeleted => 'Field plot deleted';

  @override
  String get talhaoSaved => 'Field plot saved!';

  @override
  String get talhaoUpdated => 'Field plot updated!';

  @override
  String get talhaoNameRequired => 'Enter plot name';

  @override
  String get talhaoNameTooShort => 'Name too short (minimum 2 characters)';

  @override
  String get talhaoNameTooLong => 'Name too long (maximum 50 characters)';

  @override
  String get talhaoNameExists => 'A field plot with this name already exists in this property';

  @override
  String get talhaoAreaInvalid => 'Area must be greater than zero';

  @override
  String talhaoAreaExceedsProperty(String totalTalhoes, String propertyArea) {
    return 'The sum of plot areas ($totalTalhoes ha) exceeds the property\'s total area ($propertyArea ha)';
  }

  @override
  String get talhaoSelectOptional => 'Field Plot (optional)';

  @override
  String get talhaoWholeProperty => 'Whole Property';

  @override
  String get talhaoCreateNew => '+ Create new plot';

  @override
  String get talhaoManage => 'Manage Field Plots';

  @override
  String talhaoSummaryDivided(String dividedArea, String totalArea, String percentage) {
    return '$dividedArea ha divided / $totalArea ha total ($percentage% divided)';
  }

  @override
  String talhaoWithRecords(int count) {
    return '$count record(s)';
  }

  @override
  String get talhaoFilterAll => 'All field plots';

  @override
  String get talhaoFilterBy => 'Filter by field plot';

  @override
  String get talhaoNoSelection => 'No field plot selected';

  @override
  String get deleteDataButton => 'Delete my data';

  @override
  String get deleteDataTitle => 'Delete all data?';

  @override
  String get deleteDataWarning => 'This action is IRREVERSIBLE. All your rainfall records, properties, and settings will be permanently deleted from your device and our servers.';

  @override
  String get deleteDataConfirmCheckbox => 'I understand I will lose all my records';

  @override
  String get deleteDataCancel => 'Cancel';

  @override
  String get deleteDataConfirm => 'Delete Permanently';

  @override
  String get deleteDataSuccess => 'Your data has been deleted successfully.';

  @override
  String get deleteDataError => 'Error deleting data. Please try again.';

  @override
  String get deleteDataReauthRequired => 'For security, please sign in again before deleting.';

  @override
  String get exportDataButton => 'Export my data';

  @override
  String get exportDataTitle => 'Export data';

  @override
  String get exportDataDescription => 'Download a copy of your data in a standard format to use in other services.';

  @override
  String get exportDataJson => 'JSON (complete)';

  @override
  String get exportDataCsv => 'CSV (Excel/Spreadsheets)';

  @override
  String get exportDataSuccess => 'Data exported successfully!';

  @override
  String get exportDataError => 'Error exporting data.';

  @override
  String get revokeAllButton => 'Revoke All and Sign Out';

  @override
  String get revokeAllTitle => 'Revoke all consents?';

  @override
  String get revokeAllMessage => 'This will remove all your consents and end your session. Your local data will be kept.';

  @override
  String get alertFrostTitle => 'Frost Risk';

  @override
  String get alertFrostMessage => 'Temperatures below 3°C. Protect sensitive crops.';

  @override
  String get alertHeatWaveTitle => 'Heat Wave';

  @override
  String get alertHeatWaveMessage => 'Temperatures above 35°C. Monitor hydration and heat stress.';

  @override
  String get alertStormTitle => 'Storm Alert';

  @override
  String get alertStormMessage => 'Heavy rain or strong winds forecast.';

  @override
  String get alertDroughtTitle => 'Drought Alert';

  @override
  String get alertDroughtMessage => 'No significant rain forecast for the next 7 days.';

  @override
  String get alertHighWindTitle => 'High Winds';

  @override
  String get alertHighWindMessage => 'Wind gusts above 45km/h expected.';

  @override
  String get alertHailTitle => 'Hail Alert';

  @override
  String get alertHailMessage => 'Thunderstorm with hail forecast. Protect vehicles and structures.';

  @override
  String get alertsSectionTitle => 'Weather Alerts';

  @override
  String get migrationTitle => 'Account already exists';

  @override
  String get migrationMessage => 'This Google account already has data. Do you want to transfer your current records to it?';

  @override
  String get migrationTransfer => 'Transfer Data';

  @override
  String get migrationCancel => 'Cancel';

  @override
  String get migrationProgress => 'Migrating data...';

  @override
  String get migrationProgressProperties => 'Transferring properties...';

  @override
  String get migrationProgressTalhoes => 'Transferring field plots...';

  @override
  String get migrationProgressRecords => 'Transferring records...';

  @override
  String get migrationSuccess => 'Migration completed successfully!';

  @override
  String get migrationError => 'Error during migration. Your original data has been preserved.';

  @override
  String get weatherClearSky => 'Clear sky';

  @override
  String get weatherPartlyCloudy => 'Partly cloudy';

  @override
  String get weatherFog => 'Fog';

  @override
  String get weatherLightRain => 'Light rain';

  @override
  String get weatherShowers => 'Rain showers';

  @override
  String get weatherThunderstorm => 'Thunderstorm';

  @override
  String get weatherCloudy => 'Cloudy';

  @override
  String weatherForecastFor(String propertyName) {
    return 'Forecast for: $propertyName';
  }

  @override
  String get weatherNow => 'Weather Now';

  @override
  String get weatherSeeDetails => 'See Details';

  @override
  String get weatherLocationRequired => 'Location Required';

  @override
  String get weatherLocationRequiredDesc => 'Tap here if you\'re at the property to enable the forecast.';

  @override
  String get weatherConsentRequired => 'Consent Required';

  @override
  String get weatherConsentRequiredDesc => 'Tap to authorize location usage and see the forecast.';

  @override
  String get weatherActivateForecast => 'Activate Weather Forecast';

  @override
  String get weatherActivateForecastMessage => 'To show the correct forecast, we need this property\'s location.\n\nAre you at the property now?';

  @override
  String get weatherNotHere => 'No, I\'m far away';

  @override
  String get weatherYesHere => 'Yes, I\'m here';

  @override
  String get weatherSetLocation => 'Set Location';

  @override
  String get weatherSetLocationMessage => 'No problem. Would you prefer to set the coordinates manually now or later?';

  @override
  String get weatherLater => 'Later';

  @override
  String get weatherSetManually => 'Set Manually';

  @override
  String get weatherErrorServiceDisabled => 'Location service disabled.';

  @override
  String get weatherErrorPermissionDenied => 'Location permission denied.';

  @override
  String get weatherErrorPermissionDeniedForever => 'Permission permanently denied. Enable in settings.';

  @override
  String get weatherLocationUpdated => 'Location updated! Loading forecast...';

  @override
  String weatherErrorGettingLocation(String error) {
    return 'Error getting location: $error';
  }

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeFollowsSystem => 'Follows system';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDailyReminder => 'Daily Reminder';

  @override
  String settingsReminderDailyAt(String time) {
    return 'Daily at $time';
  }

  @override
  String get settingsReminderDisabled => 'Disabled';

  @override
  String get settingsReminderTime => 'Time';

  @override
  String get backupCloudSection => 'Cloud Backup';

  @override
  String get backupCloudDescription => 'Securely sync your data with your Google account';

  @override
  String get backupCloudNow => 'Backup Now';

  @override
  String backupCloudLastBackup(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backupCloudNeverDone => 'No backup yet';

  @override
  String get backupCloudRestore => 'Restore from Cloud';

  @override
  String get backupCloudRestoreDesc => 'Replaces local data with backup';

  @override
  String get backupCloudSuccess => 'Backup completed successfully!';

  @override
  String get backupCloudRestoreSuccess => 'Data restored successfully!';

  @override
  String backupCloudError(String error) {
    return 'Backup error: $error';
  }

  @override
  String backupCloudRestoreError(String error) {
    return 'Restore error: $error';
  }

  @override
  String get backupCloudSignInRequired => 'Sign in with Google to use cloud backup';

  @override
  String get backupCloudSignInButton => 'Sign in with Google';

  @override
  String get backupCloudAnonymousWarning => 'Create a Google account to save your data to the cloud';

  @override
  String get loginBenefitSync => 'Sync & Backup (If enabled)';

  @override
  String get loginBenefitSocial => 'Business Network (If enabled)';

  @override
  String get loginBenefitSecurity => 'Total privacy by default (you control what you share)';

  @override
  String get backupLocalSection => 'Local Backup';

  @override
  String get backupLocalExport => 'Export to File';

  @override
  String get backupLocalExportDesc => 'Save data to your device';

  @override
  String get backupLocalImport => 'Import from File';

  @override
  String get backupLocalImportDesc => 'Restore from a local file';

  @override
  String get settingsPrivacyData => 'Privacy & Data';

  @override
  String get settingsManageConsents => 'Manage Consents';

  @override
  String get settingsSyncPrefs => 'Sync Preferences';

  @override
  String get settingsSyncPrefsDesc => 'Theme and basic settings';

  @override
  String get settingsExportMyData => 'Export My Data';

  @override
  String get settingsExportMyDataDesc => 'LGPD/GDPR - Data portability';

  @override
  String get settingsDeleteCloudData => 'Delete Cloud Data';

  @override
  String get settingsDeleteCloudDataDesc => 'Keeps local data';

  @override
  String get rainNoRainNextHour => 'No rain in the next hour';

  @override
  String get rainRainingNow => 'Raining now';

  @override
  String get rainStartingIn15 => 'Rain starting in ~15 min';

  @override
  String get rainStartingIn30 => 'Rain starting in ~30 min';

  @override
  String get rainStartingIn45 => 'Rain starting in ~45 min';

  @override
  String get rainNextHour => 'Rain in the next hour';

  @override
  String get settingsRainAlerts => 'Rain Alerts';

  @override
  String get settingsRainAlertsDesc => 'Get notified before it rains';

  @override
  String get notificationRainTitle => 'Rain starting soon!';

  @override
  String notificationRainBody(Object minutes) {
    return 'Rain expected to start in $minutes min.';
  }

  @override
  String notificationRainBodyWithProperty(int minutes, String propertyName) {
    return 'Rain expected in $minutes min at $propertyName.';
  }

  @override
  String get notificationChannelName => 'Rain Alerts';

  @override
  String get notificationChannelDesc => 'Notifies when heavy rain is approaching';

  @override
  String get notificationPermissionRequired => 'Notification permission required';

  @override
  String get heatmapTitle => 'Rain Heatmap';

  @override
  String get heatmapLegendLight => 'Light';

  @override
  String get heatmapLegendModerate => 'Moderate';

  @override
  String get heatmapLegendHeavy => 'Heavy';

  @override
  String get heatmapNoData => 'Insufficient data for this region';

  @override
  String get heatmapFilter1h => '1h';

  @override
  String get heatmapFilter24h => '24h';

  @override
  String get heatmapFilter7d => '7d';

  @override
  String get drawerHeatmap => 'Weather Map';

  @override
  String get mapLayerRadar => 'Radar (Real-time)';

  @override
  String get mapLayerCommunity => 'Community (Heat)';

  @override
  String get radarAttribution => 'Radar Data by RainViewer';

  @override
  String radarPast(String time) {
    return 'Past ($time)';
  }

  @override
  String get radarPresent => 'Now';

  @override
  String radarFuture(String time) {
    return 'Future ($time)';
  }

  @override
  String get radarSpeed => 'Speed';

  @override
  String get radarLoading => 'Loading Radar...';

  @override
  String get radarError => 'Error loading radar';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get deleteButton => 'Delete';

  @override
  String get deleteCloudDataTitle => 'Delete cloud data?';

  @override
  String get deleteCloudDataMessage => 'This will remove your synced data from the cloud. Local data on your device will be kept. You can sync again in the future if you wish.';

  @override
  String get deleteCloudDataSuccess => 'Cloud data deleted successfully';

  @override
  String get settingsResetProfile => 'Switch Profile';

  @override
  String get settingsResetProfileDesc => 'Return to Producer/Tapper/Buyer selection';

  @override
  String get radarRainMode => 'Rain Mode';

  @override
  String get radarSnowMode => 'Snow Mode';

  @override
  String get radarRainIntensity => 'Rain Intensity';

  @override
  String get radarSnowIntensity => 'Snow Intensity';

  @override
  String get mapTypeSatellite => 'Satellite';

  @override
  String get mapTypeNormal => 'Road Map';
}
