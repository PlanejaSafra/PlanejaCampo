import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../models/weather_forecast.dart';

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

  /// Force fetch from API
  Future<List<WeatherForecast>> refreshForecast({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    await init();
    try {
      debugPrint('WeatherService: Fetching from API for $propertyId...');
      final url = Uri.parse(
          '$_baseUrl?latitude=$latitude&longitude=$longitude&current=temperature_2m,relative_humidity_2m,precipitation,weather_code,wind_speed_10m,wind_direction_10m&daily=temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code,wind_speed_10m_max,wind_direction_10m_dominant&hourly=temperature_2m,precipitation_probability,weather_code,wind_speed_10m,wind_direction_10m&timezone=auto&forecast_days=7');

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

        for (var i = 0; i < dates.length; i++) {
          forecasts.add(WeatherForecast.fromApi(
            date: DateTime.parse(dates[i]),
            precipitationMm: (precipitations[i] as num).toDouble(),
            temperatureMax: (maxTemps[i] as num).toDouble(),
            temperatureMin: (minTemps[i] as num).toDouble(),
            weatherCode: (weatherCodes[i] as num).toInt(),
            propertyId: propertyId,
            windSpeed: (windSpeeds[i] as num).toDouble(),
            windDirection: (windDirections[i] as num).toInt(),
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
}
