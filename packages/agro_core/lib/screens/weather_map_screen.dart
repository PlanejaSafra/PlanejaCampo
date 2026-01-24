import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/heatmap_service.dart';
import '../services/radar_service.dart';
import '../services/property_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../l10n/generated/app_localizations.dart';

enum MapLayer { community, radar, cloud }

class WeatherMapScreen extends StatefulWidget {
  const WeatherMapScreen({super.key});

  @override
  State<WeatherMapScreen> createState() => _WeatherMapScreenState();
}

class _WeatherMapScreenState extends State<WeatherMapScreen>
    with SingleTickerProviderStateMixin {
  CameraPosition? _currentCameraPosition;

  // Connectors
  final _heatmapService = HeatmapService();
  final _radarService = RadarService();

  // State
  MapLayer _selectedLayer = MapLayer.radar;
  bool _isLoading = true;
  LatLng _initialPosition =
      const LatLng(-15.7942, -47.8822); // Brasilia default

  // Heatmap State
  final Set<Circle> _circles = {};
  String _heatmapFilter = '1h';

  // Radar Animation State
  Set<TileOverlay> _tileOverlays = {};
  RadarTimestamps? _radarTimestamps;
  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _radarLoading = false;
  bool _isPrefetching = false;
  int _prefetchTotal = 0;
  int _prefetchDone = 0;
  MapType _currentMapType = MapType.normal; // Default to road map

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    // Animation Duration: 1 second per frame step (interpolated)
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_onAnimationTick);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_radarTimestamps != null) {
          // Use the frames from the currently selected layer
          final frames = _selectedLayer == MapLayer.cloud
              ? _radarTimestamps!.satellite
              : _radarTimestamps!.allRadarFrames;

          if (frames.isNotEmpty) {
            final max = frames.length;
            setState(() {
              _currentIndex = (_currentIndex + 1) % max;
              _animController.reset();
              _animController.forward();
            });
          }
        }
      }
    });

    _loadInitialLocation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    _updateRadarOverlays();
  }

  Future<void> _loadInitialLocation() async {
    final prop = PropertyService().getDefaultProperty();
    if (prop != null && prop.hasLocation) {
      _initialPosition = LatLng(prop.latitude!, prop.longitude!);
    }
    // Initialize camera position with current default
    _currentCameraPosition = CameraPosition(target: _initialPosition, zoom: 8);
    await _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    if (_selectedLayer == MapLayer.community) {
      await _fetchHeatmapData();
    } else {
      await _fetchRadarData();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchHeatmapData() async {
    // Note: _stopPlayback and _tileOverlays.clear() are now done
    // synchronously in _onLayerChanged for immediate visual feedback

    if (!AgroPrivacyStore.consentAggregateMetrics) {
      _circles.clear();
      return;
    }

    final points = await _heatmapService.fetchCommunityHeatmap(
      centerLat: _initialPosition.latitude,
      centerLng: _initialPosition.longitude,
      radiusKm: 50,
      timeFilter: _heatmapFilter,
    );

    final Set<Circle> newCircles = {};
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      newCircles.add(Circle(
        circleId: CircleId('hm_$i'),
        center: LatLng(p.latitude, p.longitude),
        radius: 2000,
        strokeWidth: 0,
        fillColor: _getColorForIntensity(p.intensity),
        consumeTapEvents: false,
      ));
    }

    if (mounted) {
      setState(() => _circles.addAll(newCircles));
      if (points.isEmpty) {
        _showSnackBar(AgroLocalizations.of(context)!.heatmapNoData);
      }
    }
  }

  Future<void> _fetchRadarData() async {
    // Clear community heatmap circles immediately with setState
    setState(() {
      _circles.clear();
      _radarLoading = true;
    });

    final timestamps = await _radarService.fetchRadarTimestamps();
    if (timestamps == null) {
      if (mounted) _showSnackBar(AgroLocalizations.of(context)!.radarError);
      setState(() => _radarLoading = false);
      return;
    }

    _radarTimestamps = timestamps;

    final frames = _selectedLayer == MapLayer.cloud
        ? timestamps.satellite
        : timestamps.allRadarFrames;

    // Start at Present (last of list)
    _currentIndex = frames.length - 1;
    if (_currentIndex < 0) _currentIndex = 0;

    _updateRadarOverlays();
    setState(() => _radarLoading = false);
  }

  /// Called when user stops moving the map - refresh radar data and prefetch tiles
  void _onCameraIdle() {
    // Don't refresh while playing, loading, or prefetching
    if (_isPlaying || _radarLoading || _isPrefetching) return;
    if (_selectedLayer != MapLayer.radar && _selectedLayer != MapLayer.cloud) {
      return;
    }

    _refreshAndPrefetch();
  }

  /// Refresh timestamps and prefetch all tiles for smooth playback
  Future<void> _refreshAndPrefetch() async {
    // First refresh timestamps
    await _fetchRadarData();

    // Then prefetch all frames
    if (_radarTimestamps != null && mounted) {
      await _prefetchAllFrames();
    }
  }

  /// Pre-download tiles for all frames at current zoom level
  Future<void> _prefetchAllFrames() async {
    if (_radarTimestamps == null || _currentCameraPosition == null) return;

    final frames = _selectedLayer == MapLayer.cloud
        ? _radarTimestamps!.satellite
        : _radarTimestamps!.allRadarFrames;

    final host = _radarTimestamps!.host;
    final zoom = _currentCameraPosition!.zoom.round();
    final target = _currentCameraPosition!.target;

    // Calculate center tile coordinates
    final centerX = _lngToTileX(target.longitude, zoom);
    final centerY = _latToTileY(target.latitude, zoom);

    // Pre-fetch 3x3 grid around center for each frame
    final tilesToFetch = <String>[];
    for (final frame in frames) {
      final baseUrl = _radarService.getTileUrlTemplate(
        path: frame.path,
        host: host,
        colorScheme: _selectedLayer == MapLayer.cloud ? 0 : 2,
      );
      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final url = baseUrl
              .replaceAll('{x}', (centerX + dx).toString())
              .replaceAll('{y}', (centerY + dy).toString())
              .replaceAll('{z}', zoom.toString());
          tilesToFetch.add(url);
        }
      }
    }

    setState(() {
      _isPrefetching = true;
      _prefetchTotal = tilesToFetch.length;
      _prefetchDone = 0;
    });

    // Fetch in batches of 30 for faster download
    for (int i = 0; i < tilesToFetch.length; i += 30) {
      if (!mounted) break;

      final batch = tilesToFetch.skip(i).take(30).toList();
      await Future.wait(batch.map((url) async {
        try {
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
        } catch (_) {}
        if (mounted) {
          setState(() => _prefetchDone++);
        }
      }));
    }

    if (mounted) {
      setState(() => _isPrefetching = false);
    }
  }

  int _lngToTileX(double lng, int zoom) {
    return ((lng + 180) / 360 * (1 << zoom)).floor();
  }

  int _latToTileY(double lat, int zoom) {
    final latRad = lat * math.pi / 180;
    return ((1 -
                (math.log(math.tan(latRad) + 1 / math.cos(latRad)) / math.pi)) /
            2 *
            (1 << zoom))
        .floor();
  }

  String _getRegionHash() {
    final target = _currentCameraPosition?.target ?? _initialPosition;
    // Round to integer to group tiles by large regions (~111km blocks)
    // This ensures that when moving to a new region, the ID changes and forces refresh
    return '${target.latitude.round()}_${target.longitude.round()}';
  }

  void _updateRadarOverlays() {
    if (_radarTimestamps == null) return;

    final frames = _selectedLayer == MapLayer.cloud
        ? _radarTimestamps!.satellite
        : _radarTimestamps!.allRadarFrames;

    if (frames.isEmpty) return;

    final String regionHash = _getRegionHash();
    final Set<TileOverlay> overlays = {};
    final String host = _radarTimestamps!.host;

    // Load ALL frames simultaneously, show only current one via transparency
    for (int i = 0; i < frames.length; i++) {
      final frame = frames[i];
      final isCurrentFrame = i == _currentIndex;

      // Cloud uses scheme 0 or 1 usually
      final scheme = _selectedLayer == MapLayer.cloud ? 0 : 2;

      overlays.add(TileOverlay(
        tileOverlayId:
            TileOverlayId('radar_${frame.time}_${regionHash}_$scheme'),
        tileProvider: RadarTileProvider(
            urlTemplate: _radarService.getTileUrlTemplate(
                path: frame.path, host: host, colorScheme: scheme)),
        // Current frame: 30% transparent (70% visible)
        // Other frames: 100% transparent (invisible, but loaded)
        transparency: isCurrentFrame ? 0.3 : 1.0,
        zIndex: isCurrentFrame ? 2 : 1,
      ));
    }

    setState(() {
      _tileOverlays = overlays;
    });
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _animController.forward();
      } else {
        _animController.stop();
      }
    });
  }

  void _stopPlayback() {
    _animController.stop();
    setState(() => _isPlaying = false);
  }

  void _onLayerChanged(MapLayer layer) {
    if (_selectedLayer == layer) return;

    // When switching to community, clear radar/cloud overlays immediately
    // to avoid visual overlap during async data fetch
    if (layer == MapLayer.community) {
      _stopPlayback();
      setState(() {
        _selectedLayer = layer;
        _tileOverlays.clear();
      });
    } else {
      setState(() => _selectedLayer = layer);
    }

    _fetchData();
  }

  void _onSliderChanged(double value) {
    _stopPlayback();
    setState(() {
      _currentIndex = value.toInt();
      _animController.value = 0; // Reset interpolation
      _updateRadarOverlays();
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Color _getColorForIntensity(double mm) {
    if (mm < 5) return Colors.blue.withValues(alpha: 0.3);
    if (mm < 20) return Colors.indigo.withValues(alpha: 0.4);
    if (mm < 50) return Colors.purple.withValues(alpha: 0.5);
    return Colors.red.withValues(alpha: 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.drawerHeatmap,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _currentCameraPosition ??
                CameraPosition(
                  target: _initialPosition,
                  zoom: 8,
                ),
            onCameraMove: (pos) => _currentCameraPosition = pos,
            onCameraIdle: _onCameraIdle,
            circles: _circles,
            tileOverlays: _tileOverlays,
            mapType: _currentMapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          if (_isLoading || _radarLoading)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 100,
            right: 16,
            child: Column(
              children: [
                // ═══════════════════════════════════════════════
                // GROUP 1: Data Layers (Estatísticas, Chuva, Nuvem, Geada)
                // ═══════════════════════════════════════════════
                // 1. Community Data (estatísticas)
                FloatingActionButton.small(
                  heroTag: 'layer_community',
                  backgroundColor: _selectedLayer == MapLayer.community
                      ? Colors.orange
                      : Colors.white,
                  tooltip: l10n.heatmapTitle,
                  child: const Icon(Icons.people, color: Colors.black),
                  onPressed: () => _onLayerChanged(MapLayer.community),
                ),
                const SizedBox(height: 6),
                // 2. Rain Mode (chuva)
                FloatingActionButton.small(
                  heroTag: 'mode_rain',
                  backgroundColor: _selectedLayer == MapLayer.radar
                      ? Colors.blue
                      : Colors.white,
                  onPressed: () => _onLayerChanged(MapLayer.radar),
                  tooltip: l10n.radarRainMode,
                  child: Icon(Icons.water_drop,
                      color: _selectedLayer == MapLayer.radar
                          ? Colors.white
                          : Colors.black54),
                ),
                const SizedBox(height: 6),
                // 3. Cloud (nuvem - satélite infravermelho)
                FloatingActionButton.small(
                  heroTag: 'layer_cloud',
                  backgroundColor: _selectedLayer == MapLayer.cloud
                      ? Colors.lightBlue[100]
                      : Colors.white,
                  tooltip: l10n.mapLayerCloud,
                  child: const Icon(Icons.cloud, color: Colors.black),
                  onPressed: () => _onLayerChanged(MapLayer.cloud),
                ),
                // ═══════════════════════════════════════════════
                // GROUP 2: Base Map (Mapa, Satélite)
                // ═══════════════════════════════════════════════
                const SizedBox(height: 24), // Larger gap between groups
                // 5. Map Type: Normal (mapa/rodoviário)
                FloatingActionButton.small(
                  heroTag: 'map_normal',
                  backgroundColor: _currentMapType == MapType.normal
                      ? Colors.green
                      : Colors.white,
                  onPressed: () =>
                      setState(() => _currentMapType = MapType.normal),
                  tooltip: l10n.mapTypeNormal,
                  child: const Icon(Icons.map, color: Colors.black),
                ),
                const SizedBox(height: 6),
                // 6. Map Type: Satellite
                FloatingActionButton.small(
                  heroTag: 'map_satellite',
                  backgroundColor: _currentMapType == MapType.hybrid
                      ? Colors.green
                      : Colors.white,
                  onPressed: () =>
                      setState(() => _currentMapType = MapType.hybrid),
                  tooltip: l10n.mapTypeSatellite,
                  child: const Icon(Icons.satellite_alt, color: Colors.black),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _selectedLayer == MapLayer.radar ||
                    _selectedLayer == MapLayer.cloud
                ? _buildRadarControls(l10n)
                : _buildHeatmapControls(l10n),
          ),
          if (_selectedLayer == MapLayer.radar)
            Positioned(
              bottom: 4,
              right: 8,
              child: Text(
                l10n.radarAttribution,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    shadows: [Shadow(blurRadius: 2, color: Colors.black)]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeatmapControls(AgroLocalizations l10n) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterChip('1h', l10n.heatmapFilter1h),
              _buildFilterChip('24h', l10n.heatmapFilter24h),
              _buildFilterChip('7d', l10n.heatmapFilter7d),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem(Colors.blue, l10n.heatmapLegendLight),
              _buildLegendItem(Colors.indigo, l10n.heatmapLegendModerate),
              _buildLegendItem(Colors.red, l10n.heatmapLegendHeavy),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final theme = Theme.of(context);
    final isSelected = _heatmapFilter == id;

    return GestureDetector(
      onTap: () {
        setState(() => _heatmapFilter = id);
        _fetchHeatmapData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected ? theme.colorScheme.onPrimary : Colors.white,
              fontWeight: FontWeight.bold,
            )),
      ),
    );
  }

  Widget _buildRadarControls(AgroLocalizations l10n) {
    if (_radarTimestamps == null) return const SizedBox.shrink();

    final frames = _selectedLayer == MapLayer.cloud
        ? _radarTimestamps!.satellite
        : _radarTimestamps!.allRadarFrames;

    // Guard against empty frames list to prevent red screen error
    if (frames.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          l10n.radarNoData,
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    // Ensure _currentIndex is within bounds
    final safeIndex = _currentIndex.clamp(0, frames.length - 1);
    if (safeIndex != _currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentIndex = safeIndex);
      });
    }

    final currentFrame = frames[safeIndex];
    final date = DateTime.fromMillisecondsSinceEpoch(currentFrame.time * 1000);
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final isPast =
        currentFrame.time <= (DateTime.now().millisecondsSinceEpoch / 1000);
    final statusText = isPast
        ? l10n.radarPast(formattedTime)
        : l10n.radarFuture(formattedTime);

    final bool isNow = _selectedLayer == MapLayer.cloud
        ? safeIndex == (frames.length - 1)
        : safeIndex == (_radarTimestamps!.radarPast.length - 1);

    final displayLabel =
        isNow ? '${l10n.radarPresent} ($formattedTime)' : statusText;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          _buildRadarLegend(l10n),
          const SizedBox(height: 12),
          Row(
            children: [
              // Play button - disabled during prefetch, shows progress
              _isPrefetching
                  ? SizedBox(
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _prefetchTotal > 0
                                ? _prefetchDone / _prefetchTotal
                                : null,
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                          Text(
                            '${(_prefetchTotal > 0 ? _prefetchDone * 100 ~/ _prefetchTotal : 0)}%',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10),
                          ),
                        ],
                      ),
                    )
                  : IconButton(
                      icon: Icon(_isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_fill),
                      color: Colors.white,
                      iconSize: 48,
                      onPressed: _togglePlay,
                    ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayLabel,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        value: safeIndex.toDouble(),
                        min: 0,
                        max: (frames.length - 1).toDouble(),
                        onChanged: _onSliderChanged,
                        activeColor: isPast ? Colors.blue : Colors.purpleAccent,
                        inactiveColor: Colors.white24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  Widget _buildRadarLegend(AgroLocalizations l10n) {
    if (_selectedLayer == MapLayer.cloud) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.mapLayerCloud, // Need to add this
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Container(
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [Colors.black, Colors.white],
              ),
              border: Border.all(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Clear',
                  style: TextStyle(color: Colors.white70, fontSize: 10)),
              Text('Cloudy',
                  style: TextStyle(color: Colors.white70, fontSize: 10)),
            ],
          ),
        ],
      );
    }
    // Current scheme colors
    // Universal Blue (Rain) - ID 2
    // Scheme matches standard radar: Transparent -> Light Blue -> Dark Blue -> Purple -> Pink -> Red -> Orange -> Yellow
    final rainColors = [
      Colors.transparent, // N/A
      const Color(0xFF9BE1FF), // Light Rain
      const Color(0xFF0094F7), // Moderate
      const Color(0xFF0000FF), // Heavy
      const Color(0xFF9000FF), // Very Heavy
      const Color(0xFFFF0000), // Extreme
      const Color(0xFFFFFF00), // Hail/Storm
      const Color(0xFFFFFFFF), // Max
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            l10n.radarRainIntensity,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(colors: rainColors),
            border: Border.all(color: Colors.white24),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('Light',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
            Text('Heavy',
                style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

/// Cached tile with expiration timestamp
class _CachedTile {
  final Uint8List bytes;
  final DateTime cachedAt;

  _CachedTile(this.bytes) : cachedAt = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > const Duration(hours: 2);
}

class RadarTileProvider implements TileProvider {
  final String urlTemplate;
  final int tileSize;

  // Static cache shared across all provider instances
  // Key: URL, Value: CachedTile with expiration
  static final Map<String, _CachedTile> _cache = {};
  static const int _maxCacheSize = 500; // ~500 tiles * ~50KB = ~25MB max

  RadarTileProvider({required this.urlTemplate, this.tileSize = 256});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    final url = urlTemplate
        .replaceAll('{x}', x.toString())
        .replaceAll('{y}', y.toString())
        .replaceAll('{z}', zoom.toString());

    // Check cache first (skip if expired)
    final cached = _cache[url];
    if (cached != null && !cached.isExpired) {
      return Tile(tileSize, tileSize, cached.bytes);
    }

    // Remove expired entry
    if (cached != null && cached.isExpired) {
      _cache.remove(url);
    }

    // Retry up to 2 times with timeout
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Timeout');
          },
        );

        if (response.statusCode == 200) {
          final bytes = response.bodyBytes;

          // Store in cache (evict oldest if full)
          _cleanupExpired();
          if (_cache.length >= _maxCacheSize) {
            _cache.remove(_cache.keys.first);
          }
          _cache[url] = _CachedTile(Uint8List.fromList(bytes));

          return Tile(tileSize, tileSize, bytes);
        } else if (response.statusCode == 403 || response.statusCode == 404) {
          return TileProvider.noTile;
        }
      } catch (e) {
        if (attempt == 1) {
          debugPrint('RadarTileProvider failed after retry: $url');
        }
      }
    }
    return TileProvider.noTile;
  }

  /// Remove all expired entries from cache
  static void _cleanupExpired() {
    _cache.removeWhere((_, tile) => tile.isExpired);
  }

  /// Clear the tile cache entirely
  static void clearCache() {
    _cache.clear();
  }
}
