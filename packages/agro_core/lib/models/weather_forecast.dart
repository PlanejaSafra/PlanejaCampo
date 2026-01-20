import 'package:hive/hive.dart';

part 'weather_forecast.g.dart';

/// Weather forecast data model (cached from Open-Meteo API).
/// Stores daily weather predictions with precipitation and temperature.
@HiveType(typeId: 3)
class WeatherForecast extends HiveObject {
  /// Date of the forecast
  @HiveField(0)
  final DateTime date;

  /// Predicted precipitation in millimeters
  @HiveField(1)
  final double precipitationMm;

  /// Maximum temperature in Celsius
  @HiveField(2)
  final double temperatureMax;

  /// Minimum temperature in Celsius
  @HiveField(3)
  final double temperatureMin;

  /// Weather code from Open-Meteo (0=clear, 1-3=partly cloudy, 45-48=fog, 51-99=rain/snow)
  @HiveField(4)
  final int weatherCode;

  /// When this forecast was cached locally
  @HiveField(5)
  final DateTime cachedAt;

  /// Property ID this forecast is for
  @HiveField(6)
  final String propertyId;

  WeatherForecast({
    required this.date,
    required this.precipitationMm,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.weatherCode,
    required this.cachedAt,
    required this.propertyId,
  });

  /// Factory constructor to create from Open-Meteo API response
  factory WeatherForecast.fromApi({
    required DateTime date,
    required double precipitationMm,
    required double temperatureMax,
    required double temperatureMin,
    required int weatherCode,
    required String propertyId,
  }) {
    return WeatherForecast(
      date: date,
      precipitationMm: precipitationMm,
      temperatureMax: temperatureMax,
      temperatureMin: temperatureMin,
      weatherCode: weatherCode,
      cachedAt: DateTime.now(),
      propertyId: propertyId,
    );
  }

  /// Check if cache is still valid (< 6 hours old)
  bool get isCacheValid {
    final now = DateTime.now();
    final cacheAge = now.difference(cachedAt);
    return cacheAge.inHours < 6;
  }

  /// Get human-readable weather description based on weather code
  String getWeatherDescription() {
    if (weatherCode == 0) return 'Céu limpo';
    if (weatherCode >= 1 && weatherCode <= 3) return 'Parcialmente nublado';
    if (weatherCode >= 45 && weatherCode <= 48) return 'Neblina';
    if (weatherCode >= 51 && weatherCode <= 55) return 'Garoa';
    if (weatherCode >= 56 && weatherCode <= 57) return 'Garoa gelada';
    if (weatherCode >= 61 && weatherCode <= 65) return 'Chuva';
    if (weatherCode >= 66 && weatherCode <= 67) return 'Chuva gelada';
    if (weatherCode >= 71 && weatherCode <= 75) return 'Neve';
    if (weatherCode >= 77) return 'Neve granulada';
    if (weatherCode >= 80 && weatherCode <= 82) return 'Pancadas de chuva';
    if (weatherCode >= 85 && weatherCode <= 86) return 'Pancadas de neve';
    if (weatherCode >= 95) return 'Trovoada';
    return 'Indefinido';
  }

  /// Get weather icon based on weather code
  String getWeatherIcon() {
    if (weatherCode == 0) return '☀️';
    if (weatherCode >= 1 && weatherCode <= 3) return '⛅';
    if (weatherCode >= 45 && weatherCode <= 48) return '🌫️';
    if (weatherCode >= 51 && weatherCode <= 67) return '🌧️';
    if (weatherCode >= 71 && weatherCode <= 86) return '❄️';
    if (weatherCode >= 95) return '⛈️';
    return '🌤️';
  }

  @override
  String toString() {
    return 'WeatherForecast(date: $date, precipitation: ${precipitationMm}mm, temp: $temperatureMin-$temperatureMax°C, code: $weatherCode)';
  }
}
