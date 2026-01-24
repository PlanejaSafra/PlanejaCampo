import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/weather_forecast.dart';
import '../models/weather_alert.dart';
import '../models/instant_weather_forecast.dart';
import '../models/rain_alert_metadata.dart';

/// Service to fetch and cache weather data from Open-Meteo.
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _boxNameList = 'weather_cache';
  static const String _boxNameRaw = 'weather_cache_raw';

  // Singleton instance
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  bool _initialized = false;

  /// Initialize the service (open Hive boxes, register adapter)
  Future<void> init() async {
    if (_initialized) return;

    try {
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(WeatherForecastAdapter());
      }
      // Box for List<WeatherForecast>
      await Hive.openBox<List<dynamic>>(_boxNameList);
      // Box for Map<String, dynamic> (raw JSON)
      await Hive.openBox<Map<dynamic, dynamic>>(_boxNameRaw);

      _initialized = true;
    } catch (e) {
      debugPrint('WeatherService: Error initializing: $e');
    }
  }

  /// Gets weather forecast for [latitude], [longitude].
  /// Returns cached data if available and fresh (< 6 hours).
  Future<List<WeatherForecast>> getForecast({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    await init();
    final box = Hive.box<List<dynamic>>(_boxNameList);
    final cacheKey =
        '${propertyId}_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';

    // Check cache
    if (box.containsKey(cacheKey)) {
      final cachedList = box.get(cacheKey)?.cast<WeatherForecast>() ?? [];
      if (cachedList.isNotEmpty && cachedList.first.isCacheValid) {
        debugPrint('WeatherService: Using fresh cache for $cacheKey');
        return cachedList;
      }
    }

    return refreshForecast(
        latitude: latitude, longitude: longitude, propertyId: propertyId);
  }

  /// Parse raw API response map into `List<WeatherForecast>`
  List<WeatherForecast> parseForecastsFromMap(
      Map<String, dynamic> data, String propertyId) {
    final daily = data['daily'];
    if (daily == null) return [];

    final forecasts = <WeatherForecast>[];
    final dates = daily['time'] as List;
    final maxTemps = daily['temperature_2m_max'] as List;
    final minTemps = daily['temperature_2m_min'] as List;
    final precipitations = daily['precipitation_sum'] as List;
    final weatherCodes = daily['weather_code'] as List;
    final windSpeeds = daily['wind_speed_10m_max'] as List;
    final windDirections = daily['wind_direction_10m_dominant'] as List;

    // Calculate daily humidity from hourly data (avg)
    final hourly = data['hourly'];
    final hourlyHumidity = hourly?['relative_humidity_2m'] as List?;

    for (var i = 0; i < dates.length; i++) {
      // Calculate avg humidity for this day (24 hours)
      int avgHumidity = 0;
      if (hourlyHumidity != null && hourlyHumidity.length >= (i + 1) * 24) {
        final dayHumidities = hourlyHumidity.sublist(i * 24, (i + 1) * 24);
        if (dayHumidities.isNotEmpty) {
          final sum = dayHumidities.fold(0, (a, b) => a + (b as num).toInt());
          avgHumidity = sum ~/ dayHumidities.length;
        }
      }

      forecasts.add(WeatherForecast.fromApi(
        date: DateTime.parse(dates[i]),
        precipitationMm: (precipitations[i] as num).toDouble(),
        temperatureMax: (maxTemps[i] as num).toDouble(),
        temperatureMin: (minTemps[i] as num).toDouble(),
        weatherCode: (weatherCodes[i] as num).toInt(),
        propertyId: propertyId,
        windSpeed: (windSpeeds[i] as num).toDouble(),
        windDirection: (windDirections[i] as num).toInt(),
        relativeHumidity: avgHumidity,
      ));
    }
    return forecasts;
  }

  /// Force fetch from API
  Future<List<WeatherForecast>> refreshForecast({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    await init();
    try {
      debugPrint('WeatherService: Fetching from API for $propertyId...');
      // Added minutely_15=precipitation
      final url = Uri.parse(
          '$_baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_direction_10m&minutely_1=precipitation&minutely_15=precipitation&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,wind_speed_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,relative_humidity_2m,precipitation,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m&timezone=auto&forecast_days=7');

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the raw data for getCurrentWeather
        final boxRaw = Hive.box<Map<dynamic, dynamic>>(_boxNameRaw);
        final rawCacheKey =
            'raw_${propertyId}_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';

        // Hive maps keys must be strings usually, values dynamic
        await boxRaw.put(rawCacheKey, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        });

        final daily = data['daily'];
        final List<WeatherForecast> forecasts = [];
        final dates = daily['time'] as List;
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;
        final precipitations = daily['precipitation_sum'] as List;
        final weatherCodes = daily['weather_code'] as List;
        final windSpeeds = daily['wind_speed_10m_max'] as List;

        final windDirections = daily['wind_direction_10m_dominant'] as List;

        // Calculate daily humidity from hourly data (avg)
        final hourly = data['hourly'];
        final hourlyHumidity = hourly?['relative_humidity_2m'] as List?;

        for (var i = 0; i < dates.length; i++) {
          // Calculate avg humidity for this day (24 hours)
          int avgHumidity = 0;
          if (hourlyHumidity != null && hourlyHumidity.length >= (i + 1) * 24) {
            final dayHumidities = hourlyHumidity.sublist(i * 24, (i + 1) * 24);
            if (dayHumidities.isNotEmpty) {
              final sum =
                  dayHumidities.fold(0, (a, b) => a + (b as num).toInt());
              avgHumidity = sum ~/ dayHumidities.length;
            }
          }

          forecasts.add(WeatherForecast.fromApi(
            date: DateTime.parse(dates[i]),
            precipitationMm: (precipitations[i] as num).toDouble(),
            temperatureMax: (maxTemps[i] as num).toDouble(),
            temperatureMin: (minTemps[i] as num).toDouble(),
            weatherCode: (weatherCodes[i] as num).toInt(),
            propertyId: propertyId,
            windSpeed: (windSpeeds[i] as num).toDouble(),
            windDirection: (windDirections[i] as num).toInt(),
            relativeHumidity: avgHumidity,
          ));
        }

        // Cache the list
        final boxList = Hive.box<List<dynamic>>(_boxNameList);
        // Ensure propertyId is part of key
        final listCacheKey =
            '${propertyId}_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
        await boxList.put(listCacheKey, forecasts);

        return forecasts;
      } else {
        debugPrint('WeatherService: API Error ${response.statusCode}');
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('WeatherService: Exception $e');
      // Fallback to stale cache if available
      return _getCachedForecast(latitude, longitude, propertyId);
    }
  }

  List<WeatherForecast> _getCachedForecast(
      double latitude, double longitude, String propertyId) {
    try {
      final box = Hive.box<List<dynamic>>(_boxNameList);
      final cacheKey =
          '${propertyId}_${latitude.toStringAsFixed(4)}_${longitude.toStringAsFixed(4)}';
      return box.get(cacheKey)?.cast<WeatherForecast>() ?? [];
    } catch (e) {
      return [];
    }
  }

  /// Get current weather data (raw map) for WeatherCard
  Future<Map<String, dynamic>?> getCurrentWeather(double lat, double lng,
      {String? propertyId}) async {
    await init();
    // If no propertyId, we can't reliably find the key unless we scan or use a key without propertyId.
    // Given the constraints and the previous usage, let's assume propertyId is provided or we fail gracefully.

    if (propertyId == null) {
      debugPrint('WeatherService: getCurrentWeather called without propertyId');
      return null;
    }

    final rawCacheKey =
        'raw_${propertyId}_${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
    final boxRaw = Hive.box<Map<dynamic, dynamic>>(_boxNameRaw);

    final cachedEntry = boxRaw.get(rawCacheKey);
    if (cachedEntry != null) {
      final data = Map<String, dynamic>.from(cachedEntry['data'] as Map);
      // Simple age check - 1 hour for current weather?
      final timestamp = cachedEntry['timestamp'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;

      if (age < 60 * 60 * 1000) {
        // Check if data structure is complete (has hourly)
        if (data.containsKey('hourly')) {
          return data;
        }
        // If missing hourly (old cache), fall through to refresh
      }
      // If stale, we might want to refresh?
      // Async refresh and return stale?
      refreshForecast(
          latitude: lat,
          longitude: lng,
          propertyId: propertyId); // fire and forget
      return data;
    }

    // If not in cache, wait for refresh
    try {
      await refreshForecast(
          latitude: lat, longitude: lng, propertyId: propertyId);
      // recursive call or just get from cache now
      final newEntry = boxRaw.get(rawCacheKey);
      if (newEntry != null) {
        return Map<String, dynamic>.from(newEntry['data'] as Map);
      }
    } catch (e) {
      // ignore
    }
    return null;
  }

  /// Extract detailed rain metadata (Start Time, Duration, Intensity)
  /// Prioritizes `minutely_1` if available, falls back to `minutely_15`.
  RainAlertMetadata? analyzeRainMetadata(Map<String, dynamic>? data) {
    if (data == null) return null;

    final now = DateTime.now();

    List<DateTime> times = [];
    List<double> precips = [];
    bool isMinutely1 = false;

    // 1. Try minutely_1 (Best Precision)
    if (data.containsKey('minutely_1') && data['minutely_1'] != null) {
      final min1 = data['minutely_1'];
      final t = min1['time'] as List;
      final p = min1['precipitation'] as List;

      // Sometimes APIs return nulls or weird lengths
      if (t.length == p.length && t.isNotEmpty) {
        times = t.map((e) => DateTime.parse(e.toString())).toList();
        precips = p.map((e) => (e as num).toDouble()).toList();
        isMinutely1 = true;
      }
    }

    // 2. Fallback to minutely_15 (Good Precision)
    if (times.isEmpty &&
        data.containsKey('minutely_15') &&
        data['minutely_15'] != null) {
      final min15 = data['minutely_15'];
      final t = min15['time'] as List;
      final p = min15['precipitation'] as List;

      if (t.length == p.length && t.isNotEmpty) {
        times = t.map((e) => DateTime.parse(e.toString())).toList();
        precips = p.map((e) => (e as num).toDouble()).toList();
        isMinutely1 = false;
      }
    }

    if (times.isEmpty) return null;

    // Analysis Logic
    DateTime? startTime;
    int durationMinutes = 0;
    double totalVolume = 0;
    double maxRate = 0;

    // Threshold to consider "raining" (0.1mm)
    const double threshold = 0.1;

    // Find first rain event in the future
    int startIndex = -1;

    for (var i = 0; i < times.length; i++) {
      // Skip past data
      if (times[i].isBefore(now)) continue;

      final mm = precips[i];
      if (mm >= threshold) {
        if (startIndex == -1) {
          startIndex = i;
          startTime = times[i];
        }

        // Accumulate
        totalVolume += mm;

        // Normalize rate to mm/h
        // If minutely_1, value is mm/min -> * 60
        // If minutely_15, value is mm/15min -> * 4
        final rate = isMinutely1 ? mm * 60 : mm * 4;
        if (rate > maxRate) maxRate = rate;

        // Add duration
        durationMinutes += isMinutely1 ? 1 : 15;
      } else {
        // Stop if we found a start and now it's dry (break event)
        // Or should we allow gaps? Let's stop at first dry period > 15 min?
        // Simple Version: Stop at first 0 if we already started.
        if (startIndex != -1) {
          // Allow small gap? For now, strict contiguous.
          break;
        }
      }
    }

    // 3. Find Probability from Hourly Data
    int eventProbability =
        100; // Default to 100 if missing (conservative for past/nowcast)

    if (startTime == null || totalVolume < 0.2)
      return null; // Too light or no rain

    // Determine Intensity Class
    RainIntensity intensity = RainIntensity.light;
    if (maxRate < 0.5)
      intensity = RainIntensity.veryLight;
    else if (maxRate < 2.0)
      intensity = RainIntensity.light;
    else if (maxRate < 8.0)
      intensity = RainIntensity.moderate;
    else if (maxRate < 30.0)
      intensity = RainIntensity.heavy;
    else
      intensity = RainIntensity.violent;

    if (startTime != null && data.containsKey('hourly')) {
      final hourly = data['hourly'];
      final hTimes = hourly['time'] as List;
      final hProbs = hourly['precipitation_probability'] as List;

      // Hourly times are usually ISO strings "2023-10-10T10:00"
      // We need to find the hour block that contains startTime
      // Simple string matching or parsing

      // Strategy: Find the hourly index where time <= startTime < time + 1h
      // Since arrays are sorted:
      for (var i = 0; i < hTimes.length; i++) {
        final hTime = DateTime.parse(hTimes[i].toString());
        // Check if this hour matches the rain start event (roughly)
        // If rain starts at 14:15, we look for 14:00 slot.
        final diff = startTime.difference(hTime).inMinutes;

        if (diff >= 0 && diff < 60) {
          // This is the hour
          if (i < hProbs.length) {
            final val = hProbs[i];
            if (val != null) {
              eventProbability = (val as num).toInt();
            }
          }
          break;
        }
      }
    }

    return RainAlertMetadata(
      startTime: startTime!,
      durationMinutes: durationMinutes,
      intensity: intensity,
      totalVolumeMm: totalVolume,
      peakIntensity: maxRate,
      confidence: isMinutely1 ? 0.95 : 0.8,
      probability: eventProbability,
    );
  }

  /// Extract instant forecast (Nowcasting) from raw data
  InstantForecastSummary? parseInstantForecast(Map<String, dynamic>? data) {
    if (data == null) return null;

    // Legacy support or fallback
    final minutely = data['minutely_15'];
    if (minutely == null) return null;

    final times = minutely['time'] as List;
    final precips = minutely['precipitation'] as List;

    final points = <InstantWeatherForecast>[];
    for (var i = 0; i < times.length; i++) {
      points.add(InstantWeatherForecast.fromApi(
        times[i] as String,
        precips[i] as num,
      ));
    }

    return InstantForecastSummary(points: points);
  }

  /// Analyze forecasts to identify critical weather conditions
  List<WeatherAlert> analyzeForecasts(List<WeatherForecast> forecasts) {
    final alerts = <WeatherAlert>[];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 1. Drought Check (Look ahead 7 days)
    // We need at least 5 days of data to call it a "forecast drought"
    if (forecasts.length >= 5) {
      double totalPrecip = 0;
      for (var f in forecasts) {
        if (f.date.isAfter(today.subtract(const Duration(days: 1)))) {
          totalPrecip += f.precipitationMm;
        }
      }
      // If total rain < 2mm for the whole forecast period
      if (totalPrecip < 2.0) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.drought,
          severity: AlertSeverity.medium,
          date: today, // Applies generally
          titleKey: 'alertDroughtTitle',
          messageKey: 'alertDroughtMessage',
        ));
      }
    }

    // 2. Daily Checks
    for (var f in forecasts) {
      // Only check future or today
      if (f.date.isBefore(today)) continue;

      // Frost Risk (Min Temp < 3°C)
      if (f.temperatureMin < 3.0) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.frost,
          severity:
              f.temperatureMin < 0 ? AlertSeverity.high : AlertSeverity.medium,
          date: f.date,
          titleKey: 'alertFrostTitle',
          messageKey: 'alertFrostMessage',
        ));
      }

      // Heat Wave (Max Temp > 35°C)
      if (f.temperatureMax > 35.0) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.heatWave,
          severity:
              f.temperatureMax > 40 ? AlertSeverity.high : AlertSeverity.medium,
          date: f.date,
          titleKey: 'alertHeatWaveTitle',
          messageKey: 'alertHeatWaveMessage',
        ));
      }

      // Hail Alert (WMO codes 96 and 99 - thunderstorm with hail)
      if (f.weatherCode == 96 || f.weatherCode == 99) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.hail,
          severity:
              f.weatherCode == 99 ? AlertSeverity.high : AlertSeverity.medium,
          date: f.date,
          titleKey: 'alertHailTitle',
          messageKey: 'alertHailMessage',
        ));
      }

      // Storm Alert
      // High precip (> 50mm) OR (Strong Wind > 60km/h AND (Rain or Thunder code))
      bool heavyRain = f.precipitationMm > 50.0;
      bool strongWindStorm = f.windSpeed > 60.0 &&
          (f.weatherCode >= 51 || f.weatherCode >= 95); // Rain or Thunder

      // Don't add storm if already added hail (codes 96, 99 are also thunderstorms)
      if ((heavyRain || strongWindStorm) &&
          f.weatherCode != 96 &&
          f.weatherCode != 99) {
        alerts.add(WeatherAlert(
          type: WeatherAlertType.storm,
          severity: AlertSeverity.high,
          date: f.date,
          titleKey: 'alertStormTitle',
          messageKey: 'alertStormMessage',
        ));
      } else if (f.windSpeed > 45.0 &&
          f.weatherCode != 96 &&
          f.weatherCode != 99) {
        // High Wind (if not a storm or hail)
        alerts.add(WeatherAlert(
          type: WeatherAlertType.highWind,
          severity: AlertSeverity.medium,
          date: f.date,
          titleKey: 'alertHighWindTitle',
          messageKey: 'alertHighWindMessage',
        ));
      }
    }

    // Sort by date then severity
    alerts.sort((a, b) {
      int dateComp = a.date.compareTo(b.date);
      if (dateComp != 0) return dateComp;
      return b.severity.index.compareTo(a.severity.index); // High first
    });

    return alerts;
  }
}
