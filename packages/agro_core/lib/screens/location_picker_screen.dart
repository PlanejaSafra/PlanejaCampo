import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _mapController;
  late CameraPosition _currentCameraPosition;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // Set initial position
    if (widget.initialLat != null && widget.initialLng != null) {
      _currentCameraPosition = CameraPosition(
        target: LatLng(widget.initialLat!, widget.initialLng!),
        zoom: 16,
      );
      _isLoading = false;
    } else {
      // Default to Brasilia
      _currentCameraPosition = const CameraPosition(
        target: LatLng(-15.793889, -47.882778),
        zoom: 12,
      );
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied, do nothing or show snackbar if context available
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentCameraPosition = CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18, // Closer zoom for current location
          );

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newCameraPosition(_currentCameraPosition),
            );
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      // If fails, keeps default or previous
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context);
    final title = l10n?.propertyLocation ?? 'Selecionar Localização';
    final confirm = l10n?.chuvaBotaoSalvar ?? 'Confirmar';

    // Google Maps needs explicit padding/margin for "Google" logo if obscured.
    // But since we just have buttons at the bottom, it's fine.

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _currentCameraPosition,
            mapType: MapType.hybrid, // Satellite + Labels (Premium feel)
            myLocationEnabled: true,
            myLocationButtonEnabled: false, // Using custom button
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _currentCameraPosition = position;
            },
            onTap: (latLng) {
              // Optional: Move camera to tap if desired, but dragging is standard
            },
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
                // Return selected target
                Navigator.pop(context, _currentCameraPosition.target);
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
