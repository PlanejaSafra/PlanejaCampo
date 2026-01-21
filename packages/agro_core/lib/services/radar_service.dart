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
  /// [host] should come from the API response (e.g., "https://tilecache.rainviewer.com").
  /// [path] is the API path (e.g., "/v2/radar/1769032200" or "/v2/radar/nowcast_xxx").
  String getTileUrlTemplate({
    required String path,
    required String host,
    int size = 256,
    int colorScheme = 2,
    int smooth = 1,
  }) {
    return '$host$path/$size/{z}/{x}/{y}/$colorScheme/${smooth}_1.png';
  }
}

/// Represents a single radar frame with time and path.
class RadarFrame {
  final int time;
  final String path;

  RadarFrame({required this.time, required this.path});

  factory RadarFrame.fromJson(Map<String, dynamic> json) {
    return RadarFrame(
      time: json['time'] as int? ?? 0,
      path: json['path'] as String? ?? '',
    );
  }
}

/// Model to hold radar timestamps from RainViewer.
class RadarTimestamps {
  final String version;
  final int generated;
  final String host;
  final List<RadarFrame> radarPast; // Past frames (Radar)
  final List<RadarFrame> radarNowcast; // Future frames (Satellite/AI)

  RadarTimestamps({
    required this.version,
    required this.generated,
    required this.host,
    required this.radarPast,
    required this.radarNowcast,
  });

  /// All frames combined (Past + Nowcast).
  List<RadarFrame> get allFrames => [...radarPast, ...radarNowcast];

  factory RadarTimestamps.fromJson(Map<String, dynamic> json) {
    return RadarTimestamps(
      version: json['version'] ?? '',
      generated: json['generated'] ?? 0,
      host: json['host'] ?? '',
      radarPast: _parseFrames(json['radar']?['past']),
      radarNowcast: _parseFrames(json['radar']?['nowcast']),
    );
  }

  static List<RadarFrame> _parseFrames(dynamic list) {
    if (list is! List) return [];
    return list
        .where((e) => e is Map)
        .map((e) => RadarFrame.fromJson(e as Map<String, dynamic>))
        .where((f) => f.time > 0 && f.path.isNotEmpty)
        .toList();
  }
}
