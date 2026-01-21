import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service to interact with RainViewer API.
/// See: https://www.rainviewer.com/api/weather-maps-api.html
class RadarService {
  static const String _baseUrl =
      'https://api.rainviewer.com/public/weather-maps.json';

  // Singleton instance
  static final RadarService _instance = RadarService._internal();
  factory RadarService() => _instance;
  RadarService._internal();

  /// Fetches the available radar frame timestamps.
  /// Returns a [RadarTimestamps] object containing past, nowcast, and all frames.
  Future<RadarTimestamps?> fetchRadarTimestamps() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return RadarTimestamps.fromJson(data);
      } else {
        debugPrint(
            'RadarService: Error fetching timestamps: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('RadarService: Exception fetching timestamps: $e');
      return null;
    }
  }

  /// Construct the tile URL template with {x}, {y}, {z} placeholders.
  String getTileUrlTemplate({
    required int ts,
    int size = 256,
    int colorScheme = 2,
    int smooth = 1,
  }) {
    return 'https://tile.rainviewer.com/v2/radar/$ts/$size/{z}/{x}/{y}/$colorScheme/${smooth}_1.png';
  }

  /// Construct a specific tile URL (legacy use).
  String getTileUrl({
    required int ts,
    required int z,
    required int x,
    required int y,
    int size = 256,
    int colorScheme = 2,
    int smooth = 1,
  }) {
    return 'https://tile.rainviewer.com/v2/radar/$ts/$size/$z/$x/$y/$colorScheme/${smooth}_1.png';
  }
}

/// Model to hold radar timestamps from RainViewer.
class RadarTimestamps {
  final String version;
  final int generated;
  final String host;
  final List<int> radarPast; // Past frames (Radar)
  final List<int> radarNowcast; // Future frames (Satellite/AI)

  RadarTimestamps({
    required this.version,
    required this.generated,
    required this.host,
    required this.radarPast,
    required this.radarNowcast,
  });

  /// All timestamps combined (Past + Nowcast) sorted.
  List<int> get allTimestamps => [...radarPast, ...radarNowcast];

  factory RadarTimestamps.fromJson(Map<String, dynamic> json) {
    return RadarTimestamps(
      version: json['version'] ?? '',
      generated: json['generated'] ?? 0,
      host: json['host'] ?? '',
      radarPast: _parseTimestamps(json['radar']?['past']),
      radarNowcast: _parseTimestamps(json['radar']?['nowcast']),
    );
  }

  static List<int> _parseTimestamps(dynamic list) {
    if (list is! List) return [];
    return list
        .map((e) {
          if (e is int) return e;
          if (e is Map) return e['time'] as int? ?? 0;
          return 0;
        })
        .where((t) => t > 0)
        .toList();
  }
}
