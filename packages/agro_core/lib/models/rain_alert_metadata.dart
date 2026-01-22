enum RainIntensity {
  none,
  veryLight, // < 0.25 mm/h
  light, // 0.25 - 1.0 mm/h
  moderate, // 1.0 - 4.0 mm/h
  heavy, // > 4.0 mm/h
  violent // > 16.0 mm/h
}

/// Metadata containing precise rain alert information
class RainAlertMetadata {
  /// Estimated start time of the rain
  final DateTime startTime;

  /// Estimated duration in minutes
  final int durationMinutes;

  /// Calculated intensity
  final RainIntensity intensity;

  /// Total expected volume in mm during this event
  final double totalVolumeMm;

  /// Peak precipitation in mm/h (or mm/min * 60)
  final double peakIntensity;

  /// Probability of precipitation (0-100)
  final int probability;

  /// Confidence of prediction (0.0 to 1.0) - kept for internal logic
  final double confidence;

  RainAlertMetadata({
    required this.startTime,
    required this.durationMinutes,
    required this.intensity,
    required this.totalVolumeMm,
    required this.peakIntensity,
    this.confidence = 1.0,
    required this.probability,
  });

  /// Human-readable label for intensity
  String get intensityLabel {
    switch (intensity) {
      case RainIntensity.veryLight:
        return 'Garoa';
      case RainIntensity.light:
        return 'Chuva Leve';
      case RainIntensity.moderate:
        return 'Chuva Moderada';
      case RainIntensity.heavy:
        return 'Chuva Forte';
      case RainIntensity.violent:
        return 'Tempestade';
      default:
        return 'Sem Chuva';
    }
  }

  /// English label for intensity
  String get intensityLabelEn {
    switch (intensity) {
      case RainIntensity.veryLight:
        return 'Drizzle';
      case RainIntensity.light:
        return 'Light Rain';
      case RainIntensity.moderate:
        return 'Moderate Rain';
      case RainIntensity.heavy:
        return 'Heavy Rain';
      case RainIntensity.violent:
        return 'Violent Storm';
      default:
        return 'No Rain';
    }
  }
}
