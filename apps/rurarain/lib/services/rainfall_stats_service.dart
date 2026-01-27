import 'package:agro_core/agro_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';

import '../models/regional_stats.dart';

/// Service for fetching regional rainfall statistics.
///
/// Formerly 'SyncService', this service now focuses exclusively on
/// reading aggregated data. The write/sync logic has been migrated
/// to GenericSyncService's Tier 2 pipeline (CORE-95).
class RainfallStatsService {
  static final RainfallStatsService _instance = RainfallStatsService._internal();
  factory RainfallStatsService() => _instance;
  RainfallStatsService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _geoHasher = GeoHasher();

  /// Initialize service (stub for compatibility if needed)
  Future<void> init() async {
    // No initialization needed for stateless read service
  }

  /// Check if user has consented to data sharing
  /// (Required to view regional stats)
  bool get hasUserConsent => AgroPrivacyStore.consentAggregateMetrics;

  /// Fetch regional statistics for a location
  Future<RegionalStats?> fetchRegionalStats({
    required double latitude,
    required double longitude,
  }) async {
    final geoHash5 = _geoHasher.encode(longitude, latitude, precision: 5);
    final geoHash4 = geoHash5.substring(0, 4);
    final geoHash3 = geoHash5.substring(0, 3);

    // Try geoHash5 first (most precise)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash5)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // Ignore, try broader area
    }

    // Try geoHash4 (broader area)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash4)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // Ignore, try even broader
    }

    // Try geoHash3 (very broad area)
    try {
      final doc = await _firestore
          .collection('rainfall_stats')
          .doc(geoHash3)
          .get()
          .timeout(const Duration(seconds: 3));

      if (doc.exists) {
        final stats = RegionalStats.fromFirestore(doc);
        if (stats.meetsPrivacyThreshold) {
          return stats;
        }
      }
    } catch (e) {
      // No regional data available
    }

    return null;
  }
}
