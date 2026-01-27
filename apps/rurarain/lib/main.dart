import 'package:agro_core/agro_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';

import 'firebase_options.dart';
import 'models/registro_chuva.dart';
import 'models/sync_queue_item.dart';
import 'models/user_preferences.dart';

import 'screens/lista_chuvas_screen.dart';
import 'screens/weather_detail_screen.dart';
import 'services/chuva_service.dart';
import 'services/chuva_backup_provider.dart';
import 'services/chuva_deletion_provider.dart';
import 'services/migration_service.dart';
import 'services/notification_service.dart';
import 'services/sync_service.dart';

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

  // App Check: only activate in release builds.
  // Debug builds skip App Check to avoid needing debug tokens during development.
  if (!kDebugMode) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
  }

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(DeviceInfoAdapter());
  Hive.registerAdapter(ConsentDataAdapter());
  Hive.registerAdapter(UserCloudDataAdapter());
  Hive.registerAdapter(PropertyAdapter());
  Hive.registerAdapter(TalhaoAdapter());
  Hive.registerAdapter(RegistroChuvaAdapter());
  Hive.registerAdapter(WeatherForecastAdapter());
  Hive.registerAdapter(SyncQueueItemAdapter());

  // CORE-77: Register farm and dependency adapters
  Hive.registerAdapter(FarmAdapter());
  Hive.registerAdapter(FarmTypeAdapter());
  Hive.registerAdapter(DependencyManifestAdapter());

  // Sync infrastructure adapters (required for OfflineQueueManager)
  Hive.registerAdapter(OfflineOperationAdapter());
  Hive.registerAdapter(OperationTypeAdapter());
  Hive.registerAdapter(OperationPriorityAdapter());

  // Initialize privacy store
  await AgroPrivacyStore.init();

  // Run data migrations (Ensure privacy defaults are set)
  await DataMigrationService.instance.runMigrations();

  // Initialize cloud service
  await UserCloudService.instance.init();
  // Register backup providers (order matters: properties first, then app data)
  CloudBackupService.instance.registerProvider(PropertyBackupProvider());
  CloudBackupService.instance.registerProvider(ChuvaBackupProvider());

  // CORE-77: Register LGPD deletion provider
  DataDeletionService.instance
      .registerDeletionProvider(ChuvaDeletionProvider());

  // CORE-77: Initialize farm and dependency services
  await FarmService.instance.init();
  await DependencyService.instance.init();

  // Initialize property service (must be before chuva service for migration)
  await PropertyService().init();

  // Initialize talhao service (field plots management)
  await TalhaoService().init();

  // Initialize chuva service (registers adapter and opens box)
  await ChuvaService().init();

  // Initialize weather service
  await WeatherService().init();

  // Initialize sync service (for regional statistics)
  await SyncService().init();

  // Load user preferences
  final prefs = await UserPreferences.load();

  // Initialize notification service
  await NotificationService.init();
  await NotificationService.updateFromPreferences(prefs);

  // Initialize background service (Rain Alerts)
  await BackgroundService().initialize();

  // Initialize AdMob SDK
  await AgroAdService.instance.initialize();

  runApp(RuraRainApp(initialPreferences: prefs));
}

class RuraRainApp extends StatefulWidget {
  final UserPreferences initialPreferences;
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  const RuraRainApp({super.key, required this.initialPreferences});

  @override
  State<RuraRainApp> createState() => _RuraRainAppState();
}

class _RuraRainAppState extends State<RuraRainApp> {
  late Locale? _selectedLocale;
  late ThemeMode _themeMode;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    // Load saved preferences
    _selectedLocale = _localeFromString(widget.initialPreferences.locale);
    _themeMode = _themeModeFromString(widget.initialPreferences.themeMode);

    // Listen to notification clicks
    _notificationSubscription =
        AgroNotificationService().onNotificationClick.listen((payload) {
      if (payload != null && payload.startsWith('rain_alert')) {
        _handleRainAlertClick(payload);
      }
    });
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleRainAlertClick(String payload) async {
    // payload format: "rain_alert:propertyId"
    final parts = payload.split(':');
    String? propertyId;
    if (parts.length > 1) {
      propertyId = parts[1];
    }

    if (propertyId != null) {
      final property = PropertyService().getPropertyById(propertyId);
      if (property != null && property.hasLocation) {
        if (RuraRainApp.navigatorKey.currentState != null) {
          RuraRainApp.navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => WeatherDetailScreen(
                propertyId: propertyId!,
                latitude: property.latitude!,
                longitude: property.longitude!,
              ),
            ),
          );
        }
      }
    }
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
    // Save to Hive (UserPreferences)
    widget.initialPreferences.locale = _localeToString(newLocale);
    await widget.initialPreferences.saveToBox();

    // Also save to settings box for background service access
    final settingsBox = await Hive.openBox('settings');
    await settingsBox.put('app_locale', _localeToString(newLocale) ?? 'pt_BR');

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

  void _changeReminder(bool enabled, TimeOfDay? time) async {
    // Save to Hive
    widget.initialPreferences.reminderEnabled = enabled;
    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      widget.initialPreferences.reminderTime = '$hour:$minute';
    }
    await widget.initialPreferences.saveToBox();

    // Update NotificationService
    if (enabled && time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      final locale = widget.initialPreferences.locale ?? 'pt_BR';
      await NotificationService.scheduleDailyReminder(
        time: '$hour:$minute',
        locale: locale,
      );
    } else {
      await NotificationService.cancelDailyReminder();
    }

    // Update UI (force rebuild)
    setState(() {});
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
      title: 'RuraRain',
      navigatorKey: RuraRainApp
          .navigatorKey, // CORE-59: Handle navigation from notifications
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
      home: AuthGate(
        onChangeLocale: _changeLocale,
        onChangeThemeMode: _changeThemeMode,
        currentLocale: _selectedLocale,
        currentThemeMode: _themeMode,
        preferences: widget.initialPreferences,
        onReminderChanged: _changeReminder,
      ),
    );
  }
}

/// Widget that checks authentication status and shows Login or Home screen
class AuthGate extends StatefulWidget {
  final void Function(Locale?) onChangeLocale;
  final void Function(ThemeMode) onChangeThemeMode;
  final Locale? currentLocale;
  final ThemeMode currentThemeMode;
  final UserPreferences preferences;
  final void Function(bool, TimeOfDay?) onReminderChanged;

  const AuthGate({
    super.key,
    required this.onChangeLocale,
    required this.onChangeThemeMode,
    required this.currentLocale,
    required this.currentThemeMode,
    required this.preferences,
    required this.onReminderChanged,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isInitialized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitializeUser();
  }

  Future<void> _checkAndInitializeUser() async {
    final currentUser = AuthService.currentUser;

    if (currentUser != null) {
      // User is already signed in, initialize their data
      await _initializeUserData();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeUserData() async {
    // Run migration (preserves data when upgrading from anonymous to Google)
    await MigrationService.migrateToPropertySystem();

    // Initialize or restore cloud data
    final cloudService = UserCloudService.instance;
    var userData = cloudService.getCurrentUserData();
    final currentUser = AuthService.currentUser;

    if (currentUser != null) {
      // 1. If no local data, try to fetch from cloud (Restore scenario)
      if (userData == null) {
        debugPrint('[AuthGate] No local user data. Fetching from Firestore...');
        userData = await cloudService.fetchFromFirestore(currentUser.uid);

        if (userData != null) {
          debugPrint('[AuthGate] User data restored from cloud.');
          // Sync ALL restored consents to local PrivacyStore
          final consents = userData.consents;

          // Restore terms accepted and onboarding status
          if (consents.termsAccepted) {
            await AgroPrivacyStore.setAcceptedTerms(true);
            await AgroPrivacyStore.setOnboardingCompleted(true);
          }

          // Restore new consent model
          if (consents.cloudBackup == true) {
            await AgroPrivacyStore.setConsent(
                AgroPrivacyKeys.consentCloudBackup, true);
          }
          if (consents.socialNetwork == true) {
            await AgroPrivacyStore.setConsent(
                AgroPrivacyKeys.consentSocialNetwork, true);
          }
          if (consents.aggregateMetrics == true) {
            await AgroPrivacyStore.setConsent(
                AgroPrivacyKeys.consentAggregateMetrics, true);
          }

          // Restore legacy consents
          if (consents.sharePartners == true) {
            await AgroPrivacyStore.setConsent(
                AgroPrivacyKeys.consentSharePartners, true);
          }
          if (consents.adsPersonalization == true) {
            await AgroPrivacyStore.setConsent(
                AgroPrivacyKeys.consentAdsPersonalization, true);
          }

          debugPrint('[AuthGate] All consents restored from cloud');
        }
      }

      // 2. If still no data (New user), create initial
      if (userData == null) {
        debugPrint('[AuthGate] Creating initial user data...');
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
          uid: currentUser.uid,
          consents: consents,
        );
      }
    }

    // Update last active timestamp (fire-and-forget sync)
    cloudService.updateLastActive();
  }

  Future<void> _handleLoginSuccess() async {
    // Show spinner while preparing app
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      // Initialize user data after successful login
      await _initializeUserData();

      final user = AuthService.currentUser;
      debugPrint(
          '[Main] Login Success. User: ${user?.uid}, Anonymous: ${user?.isAnonymous}');

      if (user != null && !user.isAnonymous) {
        // CHUVA-64: Login implies consent for Cloud Backup (Terms of Use)
        // Enforce this locally for UI consistency
        if (!AgroPrivacyStore.consentCloudBackup) {
          debugPrint('[Main] Enforcing implicit Cloud Backup consent.');
          await AgroPrivacyStore.setConsent(
              AgroPrivacyKeys.consentCloudBackup, true);
        }

        // Check for existing cloud backups
        try {
          final backups =
              await CloudBackupService.instance.listAvailableBackups();

          if (backups.isNotEmpty && mounted) {
            final result = await showBackupRestoreDialog(context, backups);
            if (result != null && result.restore) {
              try {
                await CloudBackupService.instance
                    .restoreFromSlot(result.slotIndex);
                debugPrint(
                    '[BackupRestore] Restored from slot ${result.slotIndex}');
              } catch (e) {
                debugPrint('[BackupRestore] Restore failed: $e');
              }
            }
          }
        } catch (e) {
          debugPrint('[Main] Cloud backup check failed (non-fatal): $e');
        }

        // Auto-enable rain alerts if user accepted terms
        if (AgroPrivacyStore.hasAcceptedTerms()) {
          try {
            final isAlreadyEnabled =
                await BackgroundService().isRainAlertsEnabled();
            if (!isAlreadyEnabled) {
              await BackgroundService().enableRainAlerts();
              debugPrint('[RainAlerts] Auto-enabled after login');
            }
          } catch (e) {
            debugPrint('[Main] Rain alerts auto-enable failed (non-fatal): $e');
          }
        }
      }

      // Now try automatic backup (if enabled)
      CloudBackupService.instance.tryAutoBackup(
        autoBackupEnabled: AgroPrivacyStore.autoBackupEnabled,
        hasCloudBackupConsent: true,
      );
    } catch (e, stackTrace) {
      debugPrint('[Main] ERROR in _handleLoginSuccess: $e');
      debugPrint('[Main] Stack trace: $stackTrace');
    }

    // Stop loading and Refresh UI (always, even on error)
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auth status OR while processing login
    if (!_isInitialized || _isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentUser = AuthService.currentUser;

    if (currentUser == null) {
      // No user signed in, show login screen
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        appName: 'RuraRain',
        appDescription: 'Registre e acompanhe as chuvas na sua propriedade',
        appIcon: Icons.water_drop_outlined,
        appLogoLightPath: 'assets/images/rurarain-icon.png',
        appLogoDarkPath: 'assets/images/rurarain-icon.png',
      );
    }

    // User is signed in, show main app
    return AgroOnboardingGate(
      home: _PropertyNameGate(
        child: ListaChuvasScreen(
          onChangeLocale: widget.onChangeLocale,
          onChangeThemeMode: widget.onChangeThemeMode,
          currentLocale: widget.currentLocale,
          currentThemeMode: widget.currentThemeMode,
          preferences: widget.preferences,
          onReminderChanged: widget.onReminderChanged,
        ),
      ),
    );
  }
}

/// Gate that prompts for property name if using generic default name.
class _PropertyNameGate extends StatefulWidget {
  final Widget child;

  const _PropertyNameGate({required this.child});

  @override
  State<_PropertyNameGate> createState() => _PropertyNameGateState();
}

class _PropertyNameGateState extends State<_PropertyNameGate> {
  bool _hasChecked = false;

  @override
  void initState() {
    super.initState();
    // Defer check to after first frame to ensure context is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndPrompt();
    });
  }

  Future<void> _checkAndPrompt() async {
    if (_hasChecked) return;

    if (shouldPromptForPropertyName()) {
      final defaultProperty = PropertyService().getDefaultProperty();
      if (defaultProperty != null && mounted) {
        await showPropertyNamePromptDialog(
          context,
          currentName: defaultProperty.name,
        );
      }
    }

    if (mounted) {
      setState(() {
        _hasChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
