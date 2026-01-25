import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/property_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../privacy/consent_screen.dart';
import '../screens/location_picker_screen.dart';
import '../l10n/generated/app_localizations.dart';

class LocationHelper {
  /// Entry point to update property location.
  /// Checks consent -> Prompts "Are you here?" -> Gets Location OR Opens Manual Picker.
  static Future<void> checkAndUpdateLocation({
    required BuildContext context,
    required String propertyId,
    VoidCallback? onLocationUpdated,
    String? messageOverride,
  }) async {
    debugPrint('[LocationHelper] checkAndUpdateLocation started');
    // [CHANGED] Decoupled Location from Aggregate Metrics (Analytics).
    // Location is functional for Weather, not just for stats.
    // We proceed directly to asking the user.
    debugPrint(
        '[LocationHelper] checkAndUpdateLocation started (Consent check skipped)');

    if (!context.mounted) {
      debugPrint('[LocationHelper] Context not mounted. Aborting.');
      return;
    }

    // 2. Ask "Are you here?"
    debugPrint('[LocationHelper] Asking "Are you here?" for prop: $propertyId');
    await _askAreYouHere(
      context: context,
      propertyId: propertyId,
      onLocationUpdated: onLocationUpdated,
      messageOverride: messageOverride,
    );
  }

  static Future<void> _askAreYouHere({
    required BuildContext context,
    required String propertyId,
    VoidCallback? onLocationUpdated,
    String? messageOverride,
  }) async {
    final l10n = AgroLocalizations.of(context)!;

    debugPrint('[LocationHelper] Showing dialog...');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.weatherActivateForecast),
        content: Text(messageOverride ?? l10n.weatherActivateForecastMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.weatherNotHere),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.weatherYesHere),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true) {
      await _captureAndSaveLocation(
        context: context,
        propertyId: propertyId,
        onLocationUpdated: onLocationUpdated,
      );
    } else if (confirmed == false) {
      // User is not at the property. Offer manual configuration.
      await _offerManualConfiguration(
        context: context,
        propertyId: propertyId,
        onLocationUpdated: onLocationUpdated,
      );
    }
  }

  static Future<void> _captureAndSaveLocation({
    required BuildContext context,
    required String propertyId,
    VoidCallback? onLocationUpdated,
  }) async {
    final l10n = AgroLocalizations.of(context)!;

    // Show loading indicator usually handled by caller, but here we can show a snackbar or dialog?
    // For simplicity, we just proceed. A blocking dialog might be better but lets keep it simple.

    try {
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(l10n.weatherErrorServiceDisabled);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(l10n.weatherErrorPermissionDenied);
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(l10n.weatherErrorPermissionDeniedForever);
      }

      // 2. Get Location
      final position = await Geolocator.getCurrentPosition();

      // 3. Update Property
      await _updatePropertyCoordinates(
        context: context,
        propertyId: propertyId,
        lat: position.latitude,
        lng: position.longitude,
        onLocationUpdated: onLocationUpdated,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.weatherErrorGettingLocation(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  static Future<void> _offerManualConfiguration({
    required BuildContext context,
    required String propertyId,
    VoidCallback? onLocationUpdated,
  }) async {
    final l10n = AgroLocalizations.of(context)!;

    final manualConfig = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.weatherSetLocation),
        content: Text(l10n.weatherSetLocationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.weatherLater),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.weatherSetManually),
          ),
        ],
      ),
    );

    if (manualConfig == true && context.mounted) {
      final propertyService = PropertyService();
      final property = propertyService.getPropertyById(propertyId);

      if (property != null) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              initialLat: property.latitude,
              initialLng: property.longitude,
            ),
          ),
        );

        if (result != null && result is LatLng && context.mounted) {
          await _updatePropertyCoordinates(
            context: context,
            propertyId: propertyId,
            lat: result.latitude,
            lng: result.longitude,
            onLocationUpdated: onLocationUpdated,
          );
        }
      }
    }
  }

  static Future<void> _updatePropertyCoordinates({
    required BuildContext context,
    required String propertyId,
    required double lat,
    required double lng,
    VoidCallback? onLocationUpdated,
  }) async {
    final propertyService = PropertyService();
    final property = propertyService.getPropertyById(propertyId);

    if (property == null) return;

    property.updateLocation(lat, lng);
    await propertyService.updateProperty(property);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AgroLocalizations.of(context)!.weatherLocationUpdated),
          backgroundColor: Colors.green,
        ),
      );
      onLocationUpdated?.call();
    }
  }
}
