import '../l10n/generated/app_localizations.dart';

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
}

/// A summary of the immediate future (next hour)
class InstantForecastSummary {
  final List<InstantWeatherForecast> points;

  InstantForecastSummary({required this.points});

  bool get willRainSoon {
    // Check if any point in the next hour has rain > 0.1mm
    return points.any((p) => p.precipitationMm >= 0.1);
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

    // Find first rain
    int firstRainIndex = -1;
    for (int i = 0; i < futurePoints.length; i++) {
      if (futurePoints[i].precipitationMm >= 0.1) {
        firstRainIndex = i;
        break;
      }
    }

    if (firstRainIndex == -1) return l10n.rainNoRainNextHour;

    if (firstRainIndex == 0) return l10n.rainRainingNow;

    final minutes = futurePoints[firstRainIndex].time.difference(now).inMinutes;
    // Round to nearest 5 or 15 visually
    if (minutes <= 15) return l10n.rainStartingIn15;
    if (minutes <= 30) return l10n.rainStartingIn30;
    if (minutes <= 45) return l10n.rainStartingIn45;

    return l10n.rainNextHour;
  }
}
