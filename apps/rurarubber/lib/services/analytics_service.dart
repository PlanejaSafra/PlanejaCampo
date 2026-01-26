import 'package:agro_core/agro_core.dart';

import '../models/entrega.dart';

/// Stateless analytics utility for partner production data (RUBBER-21).
///
/// All methods are static -- no state is held. They filter entregas
/// by parceiroId (checking each item's parceiroId inside entrega.itens)
/// and by the safra's date range.
class AnalyticsService {
  AnalyticsService._();

  // ───────────────────────────────────────────────────────────
  // Biweekly data: splits each month into 1st-15th and 16th-end
  // ───────────────────────────────────────────────────────────

  /// Returns a map of period label -> total kg for a specific partner
  /// within the given safra, grouped by biweekly periods.
  ///
  /// Keys are formatted as "MM/1" (1st-15th) or "MM/2" (16th-end).
  static Map<String, double> getBiweeklyData(
    String parceiroId,
    Safra safra,
    List<Entrega> entregas,
  ) {
    final filtered = _filterEntregasBySafra(entregas, safra);
    final result = <String, double>{};

    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        if (item.parceiroId != parceiroId) continue;
        final month = entrega.data.month.toString().padLeft(2, '0');
        final half = entrega.data.day <= 15 ? '1' : '2';
        final key = '$month/$half';
        result[key] = (result[key] ?? 0) + item.pesoTotal;
      }
    }

    // Sort by month then half
    final sorted = Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) {
          final aParts = a.key.split('/');
          final bParts = b.key.split('/');
          final monthCmp =
              int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
          if (monthCmp != 0) return monthCmp;
          return int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
        }),
    );
    return sorted;
  }

  // ───────────────────────────────────────────────────────────
  // Monthly data: total per month within safra
  // ───────────────────────────────────────────────────────────

  /// Returns a map of month label -> total kg for a specific partner
  /// within the given safra.
  ///
  /// Keys are formatted as "MM/YYYY".
  static Map<String, double> getMonthlyData(
    String parceiroId,
    Safra safra,
    List<Entrega> entregas,
  ) {
    final filtered = _filterEntregasBySafra(entregas, safra);
    final result = <String, double>{};

    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        if (item.parceiroId != parceiroId) continue;
        final key =
            '${entrega.data.month.toString().padLeft(2, '0')}/${entrega.data.year}';
        result[key] = (result[key] ?? 0) + item.pesoTotal;
      }
    }

    // Sort chronologically
    final sorted = Map.fromEntries(
      result.entries.toList()
        ..sort((a, b) {
          final aParts = a.key.split('/');
          final bParts = b.key.split('/');
          final yearCmp =
              int.parse(aParts[1]).compareTo(int.parse(bParts[1]));
          if (yearCmp != 0) return yearCmp;
          return int.parse(aParts[0]).compareTo(int.parse(bParts[0]));
        }),
    );
    return sorted;
  }

  // ───────────────────────────────────────────────────────────
  // Season data: total per safra across multiple safras
  // ───────────────────────────────────────────────────────────

  /// Returns a map of safra name -> total kg for a specific partner.
  static Map<String, double> getSeasonData(
    String parceiroId,
    List<Safra> safras,
    List<Entrega> entregas,
  ) {
    final result = <String, double>{};

    for (final safra in safras) {
      final filtered = _filterEntregasBySafra(entregas, safra);
      double total = 0;
      for (final entrega in filtered) {
        for (final item in entrega.itens) {
          if (item.parceiroId != parceiroId) continue;
          total += item.pesoTotal;
        }
      }
      if (total > 0) {
        result[safra.shortLabel] = total;
      }
    }

    return result;
  }

  // ───────────────────────────────────────────────────────────
  // Farm average for comparison (phantom line)
  // ───────────────────────────────────────────────────────────

  /// Computes the farm average weight per period within a safra.
  ///
  /// [periodCount] is the number of periods (biweekly, monthly, or season)
  /// used to compute the average. If zero, returns 0.
  static double getFarmAverage(
    Safra safra,
    List<Entrega> entregas,
    int periodCount,
  ) {
    if (periodCount <= 0) return 0;
    final filtered = _filterEntregasBySafra(entregas, safra);
    double totalWeight = 0;
    for (final entrega in filtered) {
      totalWeight += entrega.pesoTotalGeral;
    }
    return totalWeight / periodCount;
  }

  /// Computes the farm average per partner per period.
  ///
  /// Total weight in safra / (number of active partners * periodCount).
  static double getFarmAveragePerPartner(
    Safra safra,
    List<Entrega> entregas,
    int periodCount,
  ) {
    if (periodCount <= 0) return 0;
    final filtered = _filterEntregasBySafra(entregas, safra);

    // Count distinct partners and total weight
    final partnerIds = <String>{};
    double totalWeight = 0;
    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        partnerIds.add(item.parceiroId);
        totalWeight += item.pesoTotal;
      }
    }

    final activePartners = partnerIds.length;
    if (activePartners == 0) return 0;

    return totalWeight / (activePartners * periodCount);
  }

  // ───────────────────────────────────────────────────────────
  // Phantom line visibility
  // ───────────────────────────────────────────────────────────

  /// Whether to show the phantom line (farm average) in the chart.
  ///
  /// Only shown when there are at least 2 active partners and
  /// at least 7 days with data in the safra period.
  static bool shouldShowPhantomLine(int activePartners, int daysWithData) {
    return activePartners >= 2 && daysWithData >= 7;
  }

  // ───────────────────────────────────────────────────────────
  // Partner season total
  // ───────────────────────────────────────────────────────────

  /// Total weight for a specific partner within a safra.
  static double getPartnerSeasonTotal(
    String parceiroId,
    Safra safra,
    List<Entrega> entregas,
  ) {
    final filtered = _filterEntregasBySafra(entregas, safra);
    double total = 0;
    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        if (item.parceiroId != parceiroId) continue;
        total += item.pesoTotal;
      }
    }
    return total;
  }

  // ───────────────────────────────────────────────────────────
  // Active partners count and days with data
  // ───────────────────────────────────────────────────────────

  /// Returns the number of distinct partners with data in this safra.
  static int getActivePartnerCount(Safra safra, List<Entrega> entregas) {
    final filtered = _filterEntregasBySafra(entregas, safra);
    final ids = <String>{};
    for (final entrega in filtered) {
      for (final item in entrega.itens) {
        ids.add(item.parceiroId);
      }
    }
    return ids.length;
  }

  /// Returns the number of distinct days with entregas in this safra.
  static int getDaysWithData(Safra safra, List<Entrega> entregas) {
    final filtered = _filterEntregasBySafra(entregas, safra);
    final days = <String>{};
    for (final entrega in filtered) {
      days.add(
        '${entrega.data.year}-${entrega.data.month}-${entrega.data.day}',
      );
    }
    return days.length;
  }

  // ───────────────────────────────────────────────────────────
  // Private helpers
  // ───────────────────────────────────────────────────────────

  /// Filters entregas that fall within the safra's date range.
  static List<Entrega> _filterEntregasBySafra(
    List<Entrega> entregas,
    Safra safra,
  ) {
    return entregas.where((e) => safra.containsDate(e.data)).toList();
  }
}
