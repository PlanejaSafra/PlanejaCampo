import '../l10n/generated/app_localizations.dart';

/// Precipitation intensity levels based on mm per 15 minutes
/// Note: Minimum threshold is 0.3mm to avoid false positives from API noise
enum PrecipIntensity {
  none, // < 0.3 mm (not significant / noise)
  drizzle, // 0.3 - 0.5 mm (possível garoa)
  light, // 0.5 - 2.0 mm (chuva fraca)
  moderate, // 2.0 - 5.0 mm (chuva moderada)
  heavy, // > 5.0 mm (chuva forte)
}

/// Represents a specific point in time for immediate forecast (15-min intervals)
class InstantWeatherForecast {
  final DateTime time;
  final double precipitationMm;

  InstantWeatherForecast({
    required this.time,
    required this.precipitationMm,
  });

  /// Factory from raw API arrays (index based)
  factory InstantWeatherForecast.fromApi(String isoTime, num precip) {
    return InstantWeatherForecast(
      time: DateTime.parse(isoTime),
      precipitationMm: precip.toDouble(),
    );
  }

  /// Get precipitation intensity level
  PrecipIntensity get intensity {
    if (precipitationMm < 0.3) return PrecipIntensity.none;
    if (precipitationMm < 0.5) return PrecipIntensity.drizzle;
    if (precipitationMm < 2.0) return PrecipIntensity.light;
    if (precipitationMm < 5.0) return PrecipIntensity.moderate;
    return PrecipIntensity.heavy;
  }
}

/// A summary of the immediate future (next hour)
class InstantForecastSummary {
  final List<InstantWeatherForecast> points;

  InstantForecastSummary({required this.points});

  bool get willRainSoon {
    // Check if any point in the next hour has rain >= 0.3mm
    return points.any((p) => p.precipitationMm >= 0.3);
  }

  /// Returns a human readable status, e.g. "Chuva em 15 min"
  String getStatusMessage(AgroLocalizations l10n) {
    if (points.isEmpty) return '';

    final now = DateTime.now();
    // Filter out past points just in case
    final futurePoints = points
        .where((p) => p.time.isAfter(now.subtract(const Duration(minutes: 5))))
        .toList();

    if (futurePoints.isEmpty) return '';

    // Find first precipitation (any intensity >= 0.3mm threshold)
    int firstPrecipIndex = -1;
    for (int i = 0; i < futurePoints.length; i++) {
      if (futurePoints[i].precipitationMm >= 0.3) {
        firstPrecipIndex = i;
        break;
      }
    }

    if (firstPrecipIndex == -1) return l10n.rainNoRainNextHour;

    final point = futurePoints[firstPrecipIndex];
    final intensity = point.intensity;

    // Currently precipitating (first point)
    if (firstPrecipIndex == 0) {
      switch (intensity) {
        case PrecipIntensity.drizzle:
          return l10n.rainDrizzleNow;
        case PrecipIntensity.light:
          return l10n.rainLightNow;
        case PrecipIntensity.moderate:
          return l10n.rainModerateNow;
        case PrecipIntensity.heavy:
          return l10n.rainHeavyNow;
        case PrecipIntensity.none:
          return l10n.rainNoRainNextHour;
      }
    }

    // Precipitation starting soon
    final minutes = point.time.difference(now).inMinutes;

    // For drizzle, use specific message
    if (intensity == PrecipIntensity.drizzle) {
      final roundedMinutes = ((minutes / 15).round() * 15).clamp(15, 60);
      return l10n.rainDrizzleIn(roundedMinutes);
    }

    // For rain (light+), use existing messages
    if (minutes <= 15) return l10n.rainStartingIn15;
    if (minutes <= 30) return l10n.rainStartingIn30;
    if (minutes <= 45) return l10n.rainStartingIn45;

    return l10n.rainNextHour;
  }
}
