import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/generated/app_localizations.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late MapController _mapController;
  late LatLng _currentCenter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Set initial position
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentCenter = LatLng(widget.initialLat!, widget.initialLng!);
      _isLoading = false;
    } else {
      _currentCenter = const LatLng(-15.793889, -47.882778); // Brasilia default
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentCenter = LatLng(position.latitude, position.longitude);
          _mapController.move(_currentCenter, 15);
          _isLoading = false;
        });
      }
    } catch (_) {
      // If fails, keeps default or previous
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // We don't have direct access to l10n here easily unless passed or context available?
    // context IS available in build.
    final l10n = AgroLocalizations.of(context);
    // If l10n fails (packaging issues), use fallback
    final title = l10n?.propertyLocation ?? 'Selecionar Localização';
    final confirm = l10n?.chuvaBotaoSalvar ?? 'Confirmar';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,
              onPositionChanged: (position, hasGesture) {
                if (position.center != null) {
                  _currentCenter = position.center!;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'br.com.planejacampo.agro_core',
              ),
            ],
          ),

          // Center Pin (Fixed)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Adjust for pin tip
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Colors.red,
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          // Confirm Button
          Positioned(
            left: 16,
            right: 16,
            bottom: 32,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context, _currentCenter);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(confirm),
            ),
          ),

          // My Location Button
          Positioned(
            right: 16,
            bottom: 100,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
