import 'package:flutter/material.dart';

enum WeatherAlertType {
  frost, // Geada (Min < 3°C)
  heatWave, // Onda de Calor (Max > 35°C)
  storm, // Tempestade (High precip or wind)
  drought, // Estiagem (No rain for 7 days)
  highWind, // Ventos Fortes (> 45km/h)
}

enum AlertSeverity {
  low,
  medium,
  high,
}

class WeatherAlert {
  final WeatherAlertType type;
  final AlertSeverity severity;
  final DateTime date;
  final String titleKey;
  final String messageKey;

  WeatherAlert({
    required this.type,
    required this.severity,
    required this.date,
    required this.titleKey,
    required this.messageKey,
  });

  Color get color {
    switch (type) {
      case WeatherAlertType.frost:
        return Colors.blue;
      case WeatherAlertType.heatWave:
        return Colors.red;
      case WeatherAlertType.storm:
        return Colors.deepPurple;
      case WeatherAlertType.drought:
        return Colors.orange;
      case WeatherAlertType.highWind:
        return Colors.teal;
    }
  }

  IconData get icon {
    switch (type) {
      case WeatherAlertType.frost:
        return Icons.ac_unit;
      case WeatherAlertType.heatWave:
        return Icons.thermostat;
      case WeatherAlertType.storm:
        return Icons.thunderstorm;
      case WeatherAlertType.drought:
        return Icons.warning; // water_off might be missing in this SDK version
      case WeatherAlertType.highWind:
        return Icons.air;
    }
  }
}
