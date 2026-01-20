import 'dart:math';

class HeatmapPoint {
  final double latitude;
  final double longitude;
  final double intensity; // mm

  HeatmapPoint(this.latitude, this.longitude, this.intensity);
}

class HeatmapService {
  static final HeatmapService _instance = HeatmapService._internal();
  factory HeatmapService() => _instance;
  HeatmapService._internal();

  /// Fetch community data (Currently placeholders for Backend Integration)
  /// [timeFilter] can be '1h', '24h', or '7d'
  Future<List<HeatmapPoint>> fetchCommunityHeatmap({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    String timeFilter = '1h',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Connect to Firestore Cloud Function here.
    // Currently returns empty list as per user requirement (No Mocks).
    return <HeatmapPoint>[];
  }
}
