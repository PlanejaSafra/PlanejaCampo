import 'dart:async';
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../models/weather_forecast.dart';

/// Service for fetching weather forecasts from Open-Meteo API.
/// Implements aggressive caching to minimize API calls.
class WeatherService {
  static const String _boxName = 'weather_cache';
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const Duration _requestTimeout = Duration(seconds: 3);

  late Box<WeatherForecast> _cacheBox;

  /// Initialize the Hive box for weather cache
  Future<void> init() async {
    _cacheBox = await Hive.openBox<WeatherForecast>(_boxName);
  }

  /// Fetch 5-day weather forecast for a property location.
  /// Returns cached data if still valid, otherwise fetches from API.
  Future<List<WeatherForecast>> getForecast({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    // Try to return cached forecast if still valid
    final cachedForecasts = _getCachedForecast(propertyId);
    if (cachedForecasts.isNotEmpty && cachedForecasts.first.isCacheValid) {
      return cachedForecasts;
    }

    // Cache is invalid or missing, fetch from API
    try {
      final forecasts = await _fetchFromApi(
        latitude: latitude,
        longitude: longitude,
        propertyId: propertyId,
      );

      // Save to cache
      await _saveForecastsToCache(forecasts);

      return forecasts;
    } catch (e) {
      // If API call fails, return stale cache if available
      if (cachedForecasts.isNotEmpty) {
        return cachedForecasts;
      }
      rethrow;
    }
  }

  /// Fetch fresh forecast from Open-Meteo API
  Future<List<WeatherForecast>> _fetchFromApi({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(queryParameters: {
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'daily': 'precipitation_sum,temperature_2m_max,temperature_2m_min,weathercode',
      'timezone': 'America/Sao_Paulo',
      'forecast_days': '5',
    });

    final response = await http.get(uri).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Open-Meteo API error: ${response.statusCode}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;

    final dates = (daily['time'] as List).cast<String>();
    final precipitations = (daily['precipitation_sum'] as List).cast<num>();
    final tempMaxList = (daily['temperature_2m_max'] as List).cast<num>();
    final tempMinList = (daily['temperature_2m_min'] as List).cast<num>();
    final weatherCodes = (daily['weathercode'] as List).cast<num>();

    final forecasts = <WeatherForecast>[];
    for (int i = 0; i < dates.length; i++) {
      forecasts.add(WeatherForecast.fromApi(
        date: DateTime.parse(dates[i]),
        precipitationMm: precipitations[i].toDouble(),
        temperatureMax: tempMaxList[i].toDouble(),
        temperatureMin: tempMinList[i].toDouble(),
        weatherCode: weatherCodes[i].toInt(),
        propertyId: propertyId,
      ));
    }

    return forecasts;
  }

  /// Get cached forecast for a property
  List<WeatherForecast> _getCachedForecast(String propertyId) {
    return _cacheBox.values
        .where((forecast) => forecast.propertyId == propertyId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Save forecasts to cache, replacing old data for the same property
  Future<void> _saveForecastsToCache(List<WeatherForecast> forecasts) async {
    if (forecasts.isEmpty) return;

    final propertyId = forecasts.first.propertyId;

    // Delete old forecasts for this property
    final keysToDelete = _cacheBox.keys.where((key) {
      final forecast = _cacheBox.get(key);
      return forecast?.propertyId == propertyId;
    }).toList();

    for (final key in keysToDelete) {
      await _cacheBox.delete(key);
    }

    // Save new forecasts
    for (final forecast in forecasts) {
      // Use date + propertyId as key
      final key = '${forecast.propertyId}_${forecast.date.toIso8601String()}';
      await _cacheBox.put(key, forecast);
    }
  }

  /// Get forecast for today (if available)
  WeatherForecast? getTodayForecast(String propertyId) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final forecasts = _getCachedForecast(propertyId);
    return forecasts.firstWhere(
      (f) {
        final fDate = DateTime(f.date.year, f.date.month, f.date.day);
        return fDate == todayDate;
      },
      orElse: () => forecasts.isNotEmpty ? forecasts.first : throw StateError('No forecast available'),
    );
  }

  /// Check if we have valid cached forecast for a property
  bool hasCachedForecast(String propertyId) {
    final forecasts = _getCachedForecast(propertyId);
    return forecasts.isNotEmpty && forecasts.first.isCacheValid;
  }

  /// Force refresh forecast (ignores cache)
  Future<List<WeatherForecast>> refreshForecast({
    required double latitude,
    required double longitude,
    required String propertyId,
  }) async {
    final forecasts = await _fetchFromApi(
      latitude: latitude,
      longitude: longitude,
      propertyId: propertyId,
    );
    await _saveForecastsToCache(forecasts);
    return forecasts;
  }

  /// Clear all cached forecasts
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }
}
