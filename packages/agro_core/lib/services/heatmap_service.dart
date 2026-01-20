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

  /// Mock fetching community data
  /// [timeFilter] can be '1h', '24h', or '7d'
  Future<List<HeatmapPoint>> fetchCommunityHeatmap({
    required double centerLat,
    required double centerLng,
    required double radiusKm,
    String timeFilter = '1h',
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final random = Random();
    final points = <HeatmapPoint>[];

    // Vary point count based on filter (more data for longer timeframes)
    int baseCount;
    switch (timeFilter) {
      case '7d':
        baseCount = 100;
        break;
      case '24h':
        baseCount = 70;
        break;
      default:
        baseCount = 40;
    }
    final count = baseCount + random.nextInt(30);

    // Roughly, 1 degree lat is ~111km. 10km is ~0.1 deg.
    final range = (radiusKm / 111.0) * 1.5; // wider range

    for (var i = 0; i < count; i++) {
      final lat = centerLat + (random.nextDouble() - 0.5) * range * 2;
      final lng = centerLng + (random.nextDouble() - 0.5) * range * 2;

      // Intensity weighted by "clusters"
      // Let's make some high intensity clusters
      double intensity = random.nextDouble() * 20.0; // 0-20mm

      // Boost some points to simulated storm
      if (random.nextDouble() > 0.8) {
        intensity += 30; // Heavy rain 30-50mm
      }

      points.add(HeatmapPoint(lat, lng, intensity));
    }

    return points;
  }
}
