import 'package:cloud_firestore/cloud_firestore.dart';

/// Regional rainfall statistics fetched from Firestore.
/// Aggregated data for comparing user's rainfall with regional averages.
class RegionalStats {
  /// GeoHash precision (3, 4, or 5 characters)
  final int geoHashPrecision;

  /// GeoHash string
  final String geoHash;

  /// Average precipitation in millimeters
  final double averageMm;

  /// Total accumulated precipitation
  final double totalMm;

  /// Number of contributing properties/users
  final int contributorCount;

  /// Last update timestamp
  final DateTime lastUpdated;

  /// Approximate area coverage in km²
  final double areaCoverageKm2;

  RegionalStats({
    required this.geoHashPrecision,
    required this.geoHash,
    required this.averageMm,
    required this.totalMm,
    required this.contributorCount,
    required this.lastUpdated,
    required this.areaCoverageKm2,
  });

  /// Create from Firestore document
  factory RegionalStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RegionalStats(
      geoHashPrecision: data['geohash_precision'] as int,
      geoHash: doc.id,
      averageMm: (data['avg_mm'] as num).toDouble(),
      totalMm: (data['total_mm'] as num).toDouble(),
      contributorCount: data['count'] as int,
      lastUpdated: (data['last_updated'] as Timestamp).toDate(),
      areaCoverageKm2: _calculateAreaCoverage(data['geohash_precision'] as int),
    );
  }

  /// Calculate approximate area coverage based on GeoHash precision
  static double _calculateAreaCoverage(int precision) {
    // Approximate area for each GeoHash precision level
    switch (precision) {
      case 5:
        return 25.0; // ~5km x 5km
      case 4:
        return 625.0; // ~25km x 25km
      case 3:
        return 15625.0; // ~156km x 156km
      default:
        return 25.0;
    }
  }

  /// Check if this data meets K-Anonymity threshold (minimum 3 contributors)
  bool get meetsPrivacyThreshold => contributorCount >= 3;

  /// Get human-readable area description
  String getAreaDescription() {
    if (areaCoverageKm2 < 100) {
      return '~${areaCoverageKm2.toStringAsFixed(0)}km²';
    } else if (areaCoverageKm2 < 10000) {
      return '~${(areaCoverageKm2 / 100).toStringAsFixed(0)}00km²';
    } else {
      return '~${(areaCoverageKm2 / 1000).toStringAsFixed(0)}k km²';
    }
  }

  /// Get confidence level based on contributor count
  String getConfidenceLevel() {
    if (contributorCount < 3) return 'Insuficiente';
    if (contributorCount < 10) return 'Baixa';
    if (contributorCount < 30) return 'Média';
    if (contributorCount < 100) return 'Boa';
    return 'Excelente';
  }

  @override
  String toString() {
    return 'RegionalStats(geoHash: $geoHash, avgMm: $averageMm, contributors: $contributorCount, area: ${getAreaDescription()})';
  }
}
