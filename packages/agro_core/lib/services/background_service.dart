import 'package:workmanager/workmanager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'weather_service.dart';
import 'property_service.dart';
import '../models/property.dart';
import '../models/instant_weather_forecast.dart';
import '../models/rain_alert_metadata.dart';

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
        debugPrint(
            'BackgroundService: Skipping ${prop.name} - no location set');
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

        // 6. Analyze with new Metadata Logic
        final metadata = WeatherService().analyzeRainMetadata(rawData);

        if (metadata != null) {
          // Check Debounce
          final lastAlert =
              settingsBox.get('${kLastAlertKey}_${prop.id}', defaultValue: 0);
          final now = DateTime.now().millisecondsSinceEpoch;
          final diff = now - lastAlert;

          // 2 hours debounce (avoid spamming for same storm)
          if (diff < 2 * 60 * 60 * 1000) {
            debugPrint('BackgroundService: Debounced alert for ${prop.name}');
            continue;
          }

          // Get locale from Hive for background L10n
          final storedLocale =
              settingsBox.get(kLocaleKey, defaultValue: 'pt_BR') as String;
          final isEnglish = storedLocale.startsWith('en');

          // Construct Rich Message
          // Construct Rich Message with Natural Language (CORE-60)
          final minutesUntil =
              metadata.startTime.difference(DateTime.now()).inMinutes;
          // Clean up negative minutes (if slightly past)
          final minDisplay = minutesUntil < 0 ? 0 : minutesUntil;

          final timeStr =
              '${metadata.startTime.hour.toString().padLeft(2, '0')}:${metadata.startTime.minute.toString().padLeft(2, '0')}';

          String title;
          String body;

          final prob = metadata.probability;
          final intensity =
              isEnglish ? metadata.intensityLabelEn : metadata.intensityLabel;
          final volume = metadata.totalVolumeMm.toStringAsFixed(1);

          if (isEnglish) {
            // English Logic (Simplified for now, focusing on PT-BR as per request)
            String certainty = prob > 70 ? "Forecast" : "Chance of";
            title = '$certainty ${metadata.intensityLabelEn} at ${prop.name}';
            body = 'Starting at $timeStr. Prob: $prob%. Vol: ${volume}mm.';
          } else {
            // Portuguese Logic for "Homens do Campo"

            // 1. Determine Certainty Phrase
            String callToAction; // Abertura da frase

            if (prob >= 80) {
              // Alta certeza - "Vai chover", "Chuva confirmada"
              // Cravar na certeza.
              callToAction = '🌧️ Vem chuva aí!';
              title = 'Vai chover na ${prop.name}';
            } else if (prob >= 50) {
              // Incerteza média/alta - "Pode chover"
              callToAction = '🌦️ Atenção: Pode chover.';
              title = 'Possibilidade de chuva na ${prop.name}';
            } else {
              // Baixa certeza - "Possibilidade remota"
              // O usuário pediu pra não cravar se for incerto.
              callToAction = '☁️ Tempo instável.';
              title = 'Chance de chuva na ${prop.name}';
            }

            // 2. Build the Body Text naturally
            // Ex: "Pode chover forte (12mm) por volta das 15:30."
            // Ex: "Chuva forte (12mm) esperada às 15:30."

            String intensityPhrase =
                metadata.intensityLabel.toLowerCase(); // "chuva forte"

            if (prob >= 80) {
              // Direct style
              body =
                  'Prepare-se: $intensityPhrase ($volume mm) deve começar às $timeStr.';
            } else if (prob >= 50) {
              // Possibility style
              body =
                  'Há chance de $intensityPhrase ($volume mm) por volta das $timeStr.';
            } else {
              // Low probability style
              body =
                  'Existe uma pequena chance de $intensityPhrase ($volume mm) perto das $timeStr.';
            }

            // Add duration context if long
            if (metadata.durationMinutes > 60) {
              final h = metadata.durationMinutes ~/ 60;
              body += ' Duração estimada de ${h}h.';
            }
          }

          final channelName = isEnglish ? 'Rain Alerts' : 'Alertas de Chuva';
          final channelDesc = isEnglish
              ? 'Notifies when heavy rain is approaching'
              : 'Notifica quando chuvas fortes estão próximas';

          await AgroNotificationService().showRainAlert(
            title: title,
            body: body,
            channelName: channelName,
            channelDesc: channelDesc,
            payload: 'rain_alert:${prop.id}',
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
