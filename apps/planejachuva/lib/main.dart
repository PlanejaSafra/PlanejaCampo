import 'package:agro_core/agro_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'firebase_options.dart';
import 'models/user_preferences.dart';
import 'screens/lista_chuvas_screen.dart';
import 'services/chuva_service.dart';
import 'services/migration_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    // Android and iOS rely on native configuration (google-services.json / GoogleService-Info.plist)
    // which are swapped by Gradle flavors.
    await Firebase.initializeApp();
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(DeviceInfoAdapter());
  Hive.registerAdapter(ConsentDataAdapter());
  Hive.registerAdapter(UserCloudDataAdapter());

  // Initialize privacy store
  await AgroPrivacyStore.init();

  // Initialize cloud service
  await UserCloudService.instance.init();

  // Initialize property service (must be before chuva service for migration)
  await PropertyService().init();

  // Initialize chuva service (registers adapter and opens box)
  await ChuvaService().init();

  // Firebase Anonymous Auth: Sign in or use existing user
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    await auth.signInAnonymously();
  }

  // Migrate existing data to property system (one-time migration)
  await MigrationService.migrateToPropertySystem();

  // Initialize or restore cloud data
  final cloudService = UserCloudService.instance;
  var userData = cloudService.getCurrentUserData();

  if (userData == null && auth.currentUser != null) {
    // First time: create initial cloud data
    final consents = ConsentData(
      termsAccepted: AgroPrivacyStore.hasAcceptedTerms(),
      termsVersion: '1.0',
      acceptedAt: DateTime.now(),
      aggregateMetrics: AgroPrivacyStore.consentAggregateMetrics,
      sharePartners: AgroPrivacyStore.consentSharePartners,
      adsPersonalization: AgroPrivacyStore.consentAdsPersonalization,
      consentVersion: '1.0',
    );

    await cloudService.createInitialUserData(
      uid: auth.currentUser!.uid,
      consents: consents,
    );
  }

  // Update last active timestamp (fire-and-forget sync)
  cloudService.updateLastActive();

  // Load user preferences
  final prefs = await UserPreferences.load();

  // Initialize notification service
  await NotificationService.init();
  await NotificationService.updateFromPreferences(prefs);

  runApp(PlanejaChuvaApp(initialPreferences: prefs));
}

class PlanejaChuvaApp extends StatefulWidget {
  final UserPreferences initialPreferences;

  const PlanejaChuvaApp({super.key, required this.initialPreferences});

  @override
  State<PlanejaChuvaApp> createState() => _PlanejaChuvaAppState();
}

class _PlanejaChuvaAppState extends State<PlanejaChuvaApp> {
  late Locale? _selectedLocale;
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    // Load saved preferences
    _selectedLocale = _localeFromString(widget.initialPreferences.locale);
    _themeMode = _themeModeFromString(widget.initialPreferences.themeMode);
  }

  Locale? _localeFromString(String? localeString) {
    if (localeString == null) return null;
    if (localeString == 'pt_BR') return const Locale('pt', 'BR');
    if (localeString == 'en') return const Locale('en');
    return null;
  }

  ThemeMode _themeModeFromString(String themeModeString) {
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'auto':
      default:
        return ThemeMode.system;
    }
  }

  void _changeLocale(Locale? newLocale) async {
    // Save to Hive
    widget.initialPreferences.locale = _localeToString(newLocale);
    await widget.initialPreferences.saveToBox();

    // Update UI
    setState(() {
      _selectedLocale = newLocale;
    });
  }

  void _changeThemeMode(ThemeMode newThemeMode) async {
    // Save to Hive
    widget.initialPreferences.themeMode = _themeModeToString(newThemeMode);
    await widget.initialPreferences.saveToBox();

    // Update UI
    setState(() {
      _themeMode = newThemeMode;
    });
  }

  String? _localeToString(Locale? locale) {
    if (locale == null) return null;
    if (locale.languageCode == 'pt') return 'pt_BR';
    if (locale.languageCode == 'en') return 'en';
    return null;
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'auto';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planeja Chuva',
      debugShowCheckedModeBanner: false,
      locale: _selectedLocale, // null = auto, otherwise force locale
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode, // Use saved theme mode
      localizationsDelegates: const [
        AgroLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      home: AgroOnboardingGate(
        home: ListaChuvasScreen(
          onChangeLocale: _changeLocale,
          onChangeThemeMode: _changeThemeMode,
          currentLocale: _selectedLocale,
          currentThemeMode: _themeMode,
          preferences: widget.initialPreferences,
        ),
      ),
    );
  }
}
