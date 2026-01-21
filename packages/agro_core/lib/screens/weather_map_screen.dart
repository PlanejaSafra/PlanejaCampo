import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../services/heatmap_service.dart';
import '../services/radar_service.dart';
import '../services/property_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../l10n/generated/app_localizations.dart';

enum MapLayer { community, radar }

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
          final max = _radarTimestamps!.allFrames.length;
          setState(() {
            _currentIndex = (_currentIndex + 1) % max;
            _animController.reset();
            _animController.forward();
          });
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
    _stopPlayback();
    _tileOverlays.clear();

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
    _circles.clear();
    setState(() => _radarLoading = true);

    final timestamps = await _radarService.fetchRadarTimestamps();
    if (timestamps == null) {
      if (mounted) _showSnackBar(AgroLocalizations.of(context)!.radarError);
      setState(() => _radarLoading = false);
      return;
    }

    _radarTimestamps = timestamps;
    // Start at Present (last of past list)
    _currentIndex = timestamps.radarPast.length - 1;
    if (_currentIndex < 0) _currentIndex = 0;

    _updateRadarOverlays();
    setState(() => _radarLoading = false);
  }

  /// Called when user stops moving the map - refresh radar data to avoid stale timestamps
  void _onCameraIdle() {
    if (_selectedLayer == MapLayer.radar && !_radarLoading) {
      // Refresh radar data to get fresh timestamps (they expire every ~10 min)
      _fetchRadarData();
    }
  }

  String _getRegionHash() {
    final target = _currentCameraPosition?.target ?? _initialPosition;
    // Round to integer to group tiles by large regions (~111km blocks)
    // This ensures that when moving to a new region, the ID changes and forces refresh
    return '${target.latitude.round()}_${target.longitude.round()}';
  }

  void _updateRadarOverlays() {
    if (_radarTimestamps == null) return;

    final allFrames = _radarTimestamps!.allFrames;
    if (allFrames.isEmpty) return;

    final currentFrame = allFrames[_currentIndex];
    final String regionHash = _getRegionHash();
    final Set<TileOverlay> overlays = {};
    final String host = _radarTimestamps!.host;

    // Current Frame - visible at 70% opacity (transparency 0.3)
    overlays.add(TileOverlay(
      tileOverlayId: TileOverlayId('radar_${currentFrame.time}_$regionHash'),
      tileProvider: RadarTileProvider(
          urlTemplate: _radarService.getTileUrlTemplate(
              path: currentFrame.path, host: host)),
      transparency: 0.3, // 70% visible (0.0 = fully visible, 1.0 = invisible)
      zIndex: 1,
    ));

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
    setState(() => _selectedLayer = layer);
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
            mapType: MapType.hybrid,
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
                FloatingActionButton.small(
                  heroTag: 'layer_radar',
                  backgroundColor: _selectedLayer == MapLayer.radar
                      ? Colors.blue
                      : Colors.white,
                  child: const Icon(Icons.radar, color: Colors.black),
                  onPressed: () => _onLayerChanged(MapLayer.radar),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'layer_community',
                  backgroundColor: _selectedLayer == MapLayer.community
                      ? Colors.orange
                      : Colors.white,
                  child: const Icon(Icons.people, color: Colors.black),
                  onPressed: () => _onLayerChanged(MapLayer.community),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: _selectedLayer == MapLayer.radar
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

    final allFrames = _radarTimestamps!.allFrames;
    final currentFrame = allFrames[_currentIndex];
    final date = DateTime.fromMillisecondsSinceEpoch(currentFrame.time * 1000);
    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final isPast =
        currentFrame.time <= (DateTime.now().millisecondsSinceEpoch / 1000);
    final statusText = isPast
        ? l10n.radarPast(formattedTime)
        : l10n.radarFuture(formattedTime);

    final bool isNow =
        _currentIndex == (_radarTimestamps!.radarPast.length - 1);
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
          Row(
            children: [
              IconButton(
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
                        value: _currentIndex + _animController.value,
                        min: 0,
                        max: (allFrames.length - 1).toDouble() + 0.99,
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
}

class RadarTileProvider implements TileProvider {
  final String urlTemplate;
  final int tileSize;

  RadarTileProvider({required this.urlTemplate, this.tileSize = 256});

  @override
  Future<Tile> getTile(int x, int y, int? zoom) async {
    try {
      final url = urlTemplate
          .replaceAll('{x}', x.toString())
          .replaceAll('{y}', y.toString())
          .replaceAll('{z}', zoom.toString());

      // debugPrint('RadarTileProvider: $url');

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return Tile(tileSize, tileSize, response.bodyBytes);
      } else {
        debugPrint(
            'RadarTileProvider HTTP Error: $url => ${response.statusCode}');
        return TileProvider.noTile;
      }
    } catch (e) {
      debugPrint('RadarTileProvider Exception: $e');
      return TileProvider.noTile;
    }
  }
}
