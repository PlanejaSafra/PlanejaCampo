import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/heatmap_service.dart';
import '../services/property_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../l10n/generated/app_localizations.dart';

class RainHeatmapScreen extends StatefulWidget {
  const RainHeatmapScreen({super.key});

  @override
  State<RainHeatmapScreen> createState() => _RainHeatmapScreenState();
}

class _RainHeatmapScreenState extends State<RainHeatmapScreen> {
  GoogleMapController? _mapController;
  final Set<Circle> _circles = {};
  bool _isLoading = true;
  String _selectedFilter = '1h'; // 1h, 24h, 7d
  LatLng _initialPosition =
      const LatLng(-15.7942, -47.8822); // Brasilia default

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
  }

  Future<void> _loadInitialLocation() async {
    final prop = PropertyService().getDefaultProperty();
    if (prop != null && prop.hasLocation) {
      _initialPosition = LatLng(prop.latitude!, prop.longitude!);
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Check privacy consent before fetching community data
    if (!AgroPrivacyStore.consentAggregateMetrics) {
      // User has not consented to aggregate metrics sharing
      // Show empty or limited data
      if (mounted) {
        setState(() {
          _circles.clear();
          _isLoading = false;
        });
      }
      return;
    }

    setState(() => _isLoading = true);

    // Pass filter to service
    final points = await HeatmapService().fetchCommunityHeatmap(
      centerLat: _initialPosition.latitude,
      centerLng: _initialPosition.longitude,
      radiusKm: 50,
      timeFilter: _selectedFilter,
    );

    final Set<Circle> newCircles = {};
    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      newCircles.add(Circle(
        circleId: CircleId('hm_$i'),
        center: LatLng(p.latitude, p.longitude),
        radius: 2000, // 2km radius spots
        strokeWidth: 0,
        fillColor: _getColorForIntensity(p.intensity),
        consumeTapEvents: false,
      ));
    }

    if (mounted) {
      setState(() {
        _circles.clear();
        _circles.addAll(newCircles);
        _isLoading = false;
      });
    }
  }

  Color _getColorForIntensity(double mm) {
    if (mm < 5) return Colors.blue.withValues(alpha: 0.3);
    if (mm < 20) return Colors.indigo.withValues(alpha: 0.4);
    if (mm < 50) return Colors.purple.withValues(alpha: 0.5);
    return Colors.red.withValues(alpha: 0.6);
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _fetchData(); // Refresh mock data
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.heatmapTitle,
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
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 10,
            ),
            onMapCreated: (controller) => _mapController = controller,
            circles: _circles,
            mapType: MapType.hybrid, // Rich aesthetic (Satellite)
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoading) const Center(child: CircularProgressIndicator()),

          // Filter Chips (Top Center)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterChip(l10n.heatmapFilter1h, '1h', theme),
                    _buildFilterChip(l10n.heatmapFilter24h, '24h', theme),
                    _buildFilterChip(l10n.heatmapFilter7d, '7d', theme),
                  ],
                ),
              ),
            ),
          ),

          // Legend (Bottom Center)
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Container(
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
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String id, ThemeData theme) {
    final isSelected = _selectedFilter == id;
    return GestureDetector(
      onTap: () => _onFilterChanged(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.colorScheme.onPrimary : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
