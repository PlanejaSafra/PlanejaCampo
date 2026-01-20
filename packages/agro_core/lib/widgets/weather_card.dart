import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/property_service.dart';
import '../services/weather_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../privacy/consent_screen.dart';
import '../screens/property_form_screen.dart';
import '../screens/weather_detail_screen.dart';
import '../l10n/generated/app_localizations.dart';

class WeatherCard extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? propertyId; // Optional, for cache keying or logging
  final VoidCallback? onLocationUpdated;

  const WeatherCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.propertyId,
    this.onLocationUpdated,
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final data = await WeatherService().getCurrentWeather(
        widget.latitude,
        widget.longitude,
        propertyId: widget.propertyId,
      );

      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain; // Drizzle/Rain
    if (code >= 71 && code <= 77) return Icons.ac_unit; // Snow
    if (code >= 80 && code <= 82) return Icons.water_drop; // Showers
    if (code >= 95 && code <= 99) return Icons.thunderstorm;
    return Icons.cloud;
  }

  String _getWeatherDescription(int code, AgroLocalizations l10n) {
    if (code == 0) return l10n.weatherClearSky;
    if (code >= 1 && code <= 3) return l10n.weatherPartlyCloudy;
    if (code >= 45 && code <= 48) return l10n.weatherFog;
    if (code >= 51 && code <= 67) return l10n.weatherLightRain;
    if (code >= 80 && code <= 82) return l10n.weatherShowers;
    if (code >= 95 && code <= 99) return l10n.weatherThunderstorm;
    return l10n.weatherCloudy;
  }

  /// Get cardinal direction label (N, NE, E, SE, S, SW, W, NW)
  String _getWindDirectionLabel(int degrees) {
    const directions = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
    final index = ((degrees + 22.5) % 360) ~/ 45;
    return directions[index];
  }

  @override
  Widget build(BuildContext context) {
    // CORE-35.3: Reactive to consent changes
    return ValueListenableBuilder<Box>(
      valueListenable: AgroPrivacyStore.locationConsentListenable,
      builder: (context, box, child) {
        return _buildContent(context);
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    // Check consent first - if revoked, show consent required state
    if (!AgroPrivacyStore.canUseLocation &&
        widget.latitude != 0.0 &&
        widget.longitude != 0.0) {
      return _buildConsentRequiredState(theme, l10n);
    }

    if (_isLoading) {
      return const SizedBox.shrink(); // Hide while loading initial state
    }

    if (_weatherData == null) {
      return const SizedBox
          .shrink(); // Hide if no data available (offline & no cache)
    }

    final current = _weatherData!['current'];
    final temp = current['temperature_2m'];
    final code = current['weather_code'] as int;

    // Check for effectively "null" location (0,0 is in the ocean, used as default)
    if (widget.latitude == 0.0 && widget.longitude == 0.0) {
      return _buildNoLocationState(theme, l10n);
    }

    // Extract wind data (if available) - safe fallback
    final windSpeed = current['wind_speed_10m'] as double?; // km/h
    final windDirection = current['wind_direction_10m'] as int?; // degrees

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to Detail Screen
          if (_weatherData != null) {
            String? propName;
            if (widget.propertyId != null) {
              final prop =
                  PropertyService().getPropertyById(widget.propertyId!);
              propName = prop?.name;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WeatherDetailScreen(
                  weatherData: _weatherData!,
                  propertyName: propName,
                  propertyId: widget.propertyId,
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                theme.colorScheme.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property Label (CORE-38 + CORE-34.5: only show if user has > 1 property)
              if (widget.propertyId != null &&
                  PropertyService().getPropertyCount() > 1)
                FutureBuilder(
                  future: Future.value(PropertyService()
                      .getPropertyById(widget.propertyId!)
                      ?.name),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: theme.colorScheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            l10n.weatherForecastFor(snapshot.data!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // CORE-39: Weather Alerts
              ...() {
                if (widget.propertyId == null || _weatherData == null) {
                  return [const SizedBox.shrink()];
                }

                final forecasts = WeatherService()
                    .parseForecastsFromMap(_weatherData!, widget.propertyId!);
                final alerts = WeatherService().analyzeForecasts(forecasts);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);

                // Show alerts for today and tomorrow only in the card
                final activeAlerts = alerts.where((a) {
                  final diff = a.date.difference(today).inDays;
                  return diff >= 0 && diff <= 1;
                }).toList();

                if (activeAlerts.isEmpty) return [const SizedBox.shrink()];

                final alert =
                    activeAlerts.first; // Highest severity is sorted first
                final l10n = AgroLocalizations.of(context)!;

                String title;
                switch (alert.titleKey) {
                  case 'alertFrostTitle':
                    title = l10n.alertFrostTitle;
                    break;
                  case 'alertHeatWaveTitle':
                    title = l10n.alertHeatWaveTitle;
                    break;
                  case 'alertStormTitle':
                    title = l10n.alertStormTitle;
                    break;
                  case 'alertDroughtTitle':
                    title = l10n.alertDroughtTitle;
                    break;
                  case 'alertHighWindTitle':
                    title = l10n.alertHighWindTitle;
                    break;
                  default:
                    title = alert.titleKey;
                }

                return [
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: alert.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: alert.color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(alert.icon, color: alert.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: alert.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ];
              }(),

              // Main Row: Icon + Temp + Description
              Row(
                children: [
                  Icon(
                    _getWeatherIcon(code),
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),

                  // Temp Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weatherNow,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '$temp°C',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  // Description + See Details (right side, flexible)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _getWeatherDescription(code, l10n),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.weatherSeeDetails,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            Icon(Icons.chevron_right,
                                size: 16, color: theme.colorScheme.primary),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Wind Info Row (below main content) - CORE-38
              if (windSpeed != null && windDirection != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.air,
                          size: 12, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${windSpeed.round()} km/h',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Transform.rotate(
                        angle: (windDirection * 3.14159 / 180),
                        child: Icon(Icons.navigation,
                            size: 10, color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        _getWindDirectionLabel(windDirection),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoLocationState(ThemeData theme, AgroLocalizations l10n) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: _isLoading ? null : _showUpdateLocationDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.location_off_outlined,
                size: 32,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weatherLocationRequired,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.weatherLocationRequiredDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// CORE-35.3: State shown when user has location but revoked consent.
  Widget _buildConsentRequiredState(ThemeData theme, AgroLocalizations l10n) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: InkWell(
        onTap: _showUpdateLocationDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 32,
                color: theme.colorScheme.tertiary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weatherConsentRequired,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.weatherConsentRequiredDesc,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showUpdateLocationDialog() async {
    // 1. Check if "Aggregate Metrics" (which includes Location) is consented
    if (!AgroPrivacyStore.consentAggregateMetrics) {
      // Go directly to ConsentScreen (no intermediate dialog)
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsentScreen(
            onCompleted: () => Navigator.pop(context),
          ),
        ),
      );

      // Upon return, check again. If accepted, proceed automatically.
      if (AgroPrivacyStore.consentAggregateMetrics && mounted) {
        _askAreYouHere();
      }
      return;
    }

    // 2. If already consented, go straight to "Are you here?"
    await _askAreYouHere();
  }

  Future<void> _askAreYouHere() async {
    final l10n = AgroLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.weatherActivateForecast),
        content: Text(l10n.weatherActivateForecastMessage),
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

    if (confirmed == true) {
      await _captureAndSaveLocation();
    } else if (confirmed == false) {
      // User is not at the property. Offer manual configuration.
      if (!mounted) return;

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

      if (manualConfig == true && mounted && widget.propertyId != null) {
        final propertyService = PropertyService();
        final property = propertyService.getPropertyById(widget.propertyId!);

        if (property != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PropertyFormScreen(property: property),
            ),
          );
          // Refresh callback to update calling screen (e.g. reload default property)
          widget.onLocationUpdated?.call();
          // Also refresh this widget
          _fetchWeather();
        }
      }
    }
  }

  Future<void> _captureAndSaveLocation() async {
    if (widget.propertyId == null) return;

    final l10n = AgroLocalizations.of(context)!;

    setState(() => _isLoading = true);

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
      // Use LocationSettings for time limit (if needed, though getCurrentPosition defaults are usually fine)
      // For basic usage and to avoid deprecation warning:
      final position = await Geolocator.getCurrentPosition();

      // 3. Update Property
      final propertyService = PropertyService();
      final property = propertyService.getPropertyById(widget.propertyId!);

      if (property != null) {
        property.updateLocation(position.latitude, position.longitude);
        await propertyService.updateProperty(property);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.weatherLocationUpdated),
              backgroundColor: Colors.green,
            ),
          );
          // 4. Notify Parent to Refresh
          widget.onLocationUpdated?.call();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.weatherErrorGettingLocation(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
