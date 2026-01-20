import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'weather_service.dart';
import 'property_service.dart';
import '../models/property.dart';
import '../models/instant_weather_forecast.dart';

const String kRainCheckTask = 'rain_check_task';
const String kRainCheckId = 'rain_check_id';
const String kSettingsBox = 'settings';
const String kRainAlertsKey = 'rain_alerts_enabled';
const String kLastAlertKey = 'last_rain_alert_timestamp';
const String kLocaleKey = 'app_locale'; // For background L10n

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kRainCheckTask) {
      try {
        await BackgroundService().checkRain();
      } catch (e) {
        debugPrint('BackgroundService: Error in task: $e');
        return Future.value(false);
      }
    }
    return Future.value(true);
  });
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  Future<void> initialize() async {
    // Only works on Android/iOS
    // On web this will crash, but agro_core might be used on web?
    // We assume mobile for now.
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode, // True for dev
    );
  }

  Future<void> enableRainAlerts() async {
    debugPrint('BackgroundService: Enabling rain alerts...');
    final box = await Hive.openBox(kSettingsBox);
    await box.put(kRainAlertsKey, true);

    requestPermissions();

    await Workmanager().registerPeriodicTask(
      kRainCheckId,
      kRainCheckTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.update,
    );
  }

  Future<void> disableRainAlerts() async {
    debugPrint('BackgroundService: Disabling rain alerts...');
    final box = await Hive.openBox(kSettingsBox);
    await box.put(kRainAlertsKey, false);
    await Workmanager().cancelByUniqueName(kRainCheckId);
  }

  Future<bool> isRainAlertsEnabled() async {
    if (!Hive.isBoxOpen(kSettingsBox)) {
      await Hive.openBox(kSettingsBox);
    }
    return Hive.box(kSettingsBox).get(kRainAlertsKey, defaultValue: false);
  }

  Future<void> requestPermissions() async {
    await AgroNotificationService().requestPermissions();
  }

  /// The main logic running in background isolate
  Future<void> checkRain() async {
    // 1. Initialize Hive (since we are in a new isolate)
    await Hive.initFlutter();

    // 2. Register Adapters
    if (!Hive.isAdapterRegistered(10)) {
      // Property Adapter
      Hive.registerAdapter(PropertyAdapter());
    }
    // WeatherService handles its own adapter registration in init()

    // 3. Check if enabled
    final settingsBox = await Hive.openBox(kSettingsBox);
    final bool enabled = settingsBox.get(kRainAlertsKey, defaultValue: false);

    if (!enabled) {
      debugPrint('BackgroundService: Alerts disabled, skipping.');
      return;
    }

    // 4. Get Default Property
    // We use PropertyService directly?
    // PropertyService needs init.
    // Let's manually get properties to avoid complex service dependencies if possible,
    // Or just trust PropertyService.

    // PropertyService uses 'properties' box.
    final propertyService = PropertyService();
    // It assumes Hive used in user context (userId).
    // In background, we might not have 'auth' state easily?
    // AuthService.currentUser might be null or not initialized.
    // Hive boxes are usually local file based. If we know the box name, we can open it.
    // PropertyService uses "properties_v1" (global).
    // But it filters by userId.

    // Simplification: Iterate ALL properties in legal storage.
    // Or, store the "monitored property ID" in settings when toggled.
    // That's safer.

    // Let's assume we check ALL properties stored in device.
    await propertyService.init();
    final properties = propertyService.getAllProperties(); // Returns all in box

    if (properties.isEmpty) {
      debugPrint('BackgroundService: No properties found.');
      return;
    }

    for (final prop in properties) {
      // Skip properties without location
      if (!prop.hasLocation) {
        debugPrint('BackgroundService: Skipping ${prop.name} - no location set');
        continue;
      }

      // 5. Fetch Forecast
      // We force refresh because background task is sparse.
      try {
        await WeatherService().refreshForecast(
          latitude: prop.latitude!,
          longitude: prop.longitude!,
          propertyId: prop.id,
        );

        // We need the RAW data for minutely_15.
        // WeatherService.refreshForecast caches raw data too.
        final rawData = await WeatherService().getCurrentWeather(
            prop.latitude!, prop.longitude!,
            propertyId: prop.id);

        if (rawData == null) continue;

        final summary = WeatherService().parseInstantForecast(rawData);
        if (summary == null) continue;

        // 6. Analyze
        if (summary.willRainSoon) {
          // Check Debounce
          final lastAlert =
              settingsBox.get('${kLastAlertKey}_${prop.id}', defaultValue: 0);
          final now = DateTime.now().millisecondsSinceEpoch;
          final diff = now - lastAlert;

          // 2 hours debounce
          if (diff < 2 * 60 * 60 * 1000) {
            debugPrint('BackgroundService: Debounced alert for ${prop.name}');
            continue;
          }

          // Prepare Message
          // We don't have BuildContext for L10n.
          // We used hardcoded fallback or primitive L10n based on locale in Hive?
          // Or just Generic code.
          // "Vai chover em breve em [Propriedade]!"

          // Get time to rain
          int minutesParams = 0;
          for (var p in summary.points) {
            if (p.precipitationMm >= 0.1 && p.time.isAfter(DateTime.now())) {
              minutesParams = p.time.difference(DateTime.now()).inMinutes;
              break;
            }
          }
          if (minutesParams < 0) minutesParams = 0;

          // Get locale from Hive for background L10n
          final storedLocale =
              settingsBox.get(kLocaleKey, defaultValue: 'pt_BR') as String;
          final isEnglish = storedLocale.startsWith('en');

          final title =
              isEnglish ? 'Rain starting soon!' : 'Vai chover em breve!';
          final body = isEnglish
              ? 'Rain expected in $minutesParams min at ${prop.name}.'
              : 'Chuva prevista para começar em $minutesParams min na ${prop.name}.';

          await AgroNotificationService().showRainAlert(
            title: title,
            body: body,
            locale: storedLocale,
          );

          settingsBox.put('${kLastAlertKey}_${prop.id}', now);
        }
      } catch (e) {
        debugPrint(
            'BackgroundService: Error checking property ${prop.name}: $e');
      }
    }
  }
}
