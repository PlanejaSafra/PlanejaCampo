import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

/// Service to fetch and cache weather data from Open-Meteo.
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _boxName = 'weather_cache';

  // Singleton instance
  static final WeatherService _instance = WeatherService._internal();
  factory WeatherService() => _instance;
  WeatherService._internal();

  /// Gets weather forecast for [lat], [lng].
  /// Returns cached data if available and fresh (< 6 hours).
  /// Falls back to cache if API fails.
  Future<Map<String, dynamic>?> getCurrentWeather(
      double lat, double lng) async {
    try {
      final box = await Hive.openBox(_boxName);
      final cacheKey = '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';

      // Check cache validity (6 hours)
      final cachedData = box.get(cacheKey);
      if (cachedData != null) {
        final timestamp = cachedData['timestamp'] as int;
        final age = DateTime.now().millisecondsSinceEpoch - timestamp;

        if (age < 6 * 60 * 60 * 1000) {
          debugPrint('WeatherService: Using fresh cache');
          return cachedData['data'];
        }
      }

      // Fetch from API
      debugPrint('WeatherService: Fetching from API...');
      final url = Uri.parse(
          '$_baseUrl?latitude=$lat&longitude=$lng&current=temperature_2m,relative_humidity_2m,precipitation,weather_code&daily=temperature_2m_max,temperature_2m_min&timezone=auto');

      final response = await http.get(url).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Update cache
        await box.put(cacheKey, {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'data': data,
        });

        return data;
      } else {
        debugPrint('WeatherService: API Error ${response.statusCode}');
        // Fallback to stale cache if available
        if (cachedData != null) {
          debugPrint('WeatherService: Using stale cache due to API error');
          return cachedData['data'];
        }
      }
    } catch (e) {
      debugPrint('WeatherService: Exception $e');
      // Fallback to stale cache if available
      try {
        final box = await Hive.openBox(_boxName);
        final cacheKey = '${lat.toStringAsFixed(4)}_${lng.toStringAsFixed(4)}';
        final cachedData = box.get(cacheKey);
        if (cachedData != null) {
          debugPrint('WeatherService: Using stale cache due to exception');
          return cachedData['data'];
        }
      } catch (_) {}
    }

    return null;
  }
}
