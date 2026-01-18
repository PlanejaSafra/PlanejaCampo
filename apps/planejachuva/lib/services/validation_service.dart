import '../models/registro_chuva.dart';
import 'chuva_service.dart';

/// Service for intelligent validation of rainfall data.
/// Detects anomalies, duplicates, and extreme values.
class ValidationService {
  static const double extremeRainThreshold = 100.0; // mm
  static const int duplicateWindowHours = 2; // hours
  static const int droughtWarningDays = 30; // days

  /// Check if a rainfall value is extreme (> 100mm in 1 day).
  bool isExtremeRainfall(double millimeters) {
    return millimeters > extremeRainThreshold;
  }

  /// Check if there's already a record for the same day.
  bool isDuplicateDate(DateTime date) {
    final service = ChuvaService();
    final registros = service.listarTodos();

    // Check if any existing record has the same date (ignoring time)
    return registros.any((r) =>
        r.data.year == date.year &&
        r.data.month == date.month &&
        r.data.day == date.day);
  }

  /// Find existing record on the same date.
  RegistroChuva? findRecordOnDate(DateTime date) {
    final service = ChuvaService();
    final registros = service.listarTodos();

    return registros.cast<RegistroChuva?>().firstWhere(
          (r) =>
              r!.data.year == date.year &&
              r.data.month == date.month &&
              r.data.day == date.day,
          orElse: () => null,
        );
  }

  /// Calculate days since last rainfall.
  /// Returns null if there are no records.
  int? daysSinceLastRain() {
    final service = ChuvaService();
    final registros = service.listarTodos();

    if (registros.isEmpty) return null;

    // Sort by date descending (most recent first)
    registros.sort((a, b) => b.data.compareTo(a.data));
    final mostRecent = registros.first;

    final today = DateTime.now();
    final lastRainDate = mostRecent.data;

    return today.difference(lastRainDate).inDays;
  }

  /// Check if there's a drought warning (> 30 days without rain).
  bool hasDroughtWarning() {
    final days = daysSinceLastRain();
    if (days == null) return false;
    return days > droughtWarningDays;
  }

  /// Get a user-friendly message for extreme rainfall.
  String getExtremeRainfallMessage(double mm, String locale) {
    if (locale.startsWith('pt')) {
      return 'Chuva muito forte! Confirma $mm mm em um único dia?';
    } else {
      return 'Very heavy rain! Confirm $mm mm in a single day?';
    }
  }

  /// Get a user-friendly message for duplicate date.
  String getDuplicateDateMessage(RegistroChuva existing, String locale) {
    if (locale.startsWith('pt')) {
      return 'Já existe um registro de ${existing.milimetros} mm para este dia. Deseja criar outro?';
    } else {
      return 'There\'s already a ${existing.milimetros} mm record for this day. Create another?';
    }
  }

  /// Get a user-friendly message for drought warning.
  String getDroughtWarningMessage(int days, String locale) {
    if (locale.startsWith('pt')) {
      return '⚠️ Atenção: $days dias sem chuva registrada';
    } else {
      return '⚠️ Warning: $days days without rainfall';
    }
  }
}
