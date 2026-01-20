import '../models/registro_chuva.dart';

class ComparativeStatsHelper {
  /// Aggregates rainfall data by month for two specific years.
  ///
  /// Returns a Map where key is the year, and value is another Map (Month -> Total).
  static Map<int, Map<int, double>> aggregateByYear(
    List<RegistroChuva> records, {
    required int yearA,
    required int yearB,
  }) {
    final Map<int, Map<int, double>> result = {
      yearA: {},
      yearB: {},
    };

    // Initialize months with 0.0
    for (int m = 1; m <= 12; m++) {
      result[yearA]![m] = 0.0;
      result[yearB]![m] = 0.0;
    }

    // Sum data
    for (final record in records) {
      final y = record.data.year;
      final m = record.data.month;

      if (y == yearA || y == yearB) {
        final current = result[y]![m] ?? 0.0;
        result[y]![m] = current + record.milimetros;
      }
    }

    return result;
  }

  /// Calculates the total rainfall difference (percentage) between two years.
  /// Returns null if previous year is 0.
  static double? calculateDiffPercentage(double totalA, double totalB) {
    if (totalB == 0) return null;
    return ((totalA - totalB) / totalB) * 100;
  }
}
