import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/property_service.dart';
import '../services/weather_service.dart';
import '../privacy/agro_privacy_store.dart';
import '../privacy/consent_screen.dart';
// WeatherService is used in _fetchWeather (state), but not in widget definition file?
// No, the State IS in the same file. WeatherService IS used.
// "packages\agro_core\lib\widgets\weather_card.dart:4:8 - unused_import" <- That likely refers to a duplicate or unneeded one.
// The file I viewed earlier had `import '../services/weather_service.dart';` at line 2.
// Then I replaced line 1 to include geolocator.
// Let's check imports.

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

  String _getWeatherDescription(int code) {
    if (code == 0) return 'Céu limpo';
    if (code >= 1 && code <= 3) return 'Parcialmente nublado';
    if (code >= 45 && code <= 48) return 'Neblina';
    if (code >= 51 && code <= 67) return 'Chuva fraca';
    if (code >= 80 && code <= 82) return 'Pancadas de chuva';
    if (code >= 95 && code <= 99) return 'Tempestade';
    return 'Nublado';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
      return _buildNoLocationState(theme);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        child: Row(
          children: [
            Icon(
              _getWeatherIcon(code),
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempo Agora',
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
            Expanded(
              child: Text(
                _getWeatherDescription(code),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoLocationState(ThemeData theme) {
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
                      'Localização Necessária',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque aqui se estiver na propriedade para ativar a previsão.',
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

  Future<void> _showUpdateLocationDialog() async {
    final l10n = AgroLocalizations.of(context)!;

    // 1. Check if "Aggregate Metrics" (which includes Location) is consented
    if (!AgroPrivacyStore.consentAggregateMetrics) {
      final shouldReview = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permissão Necessária'),
          content: const Text(
            'Para ativar a previsão do tempo automática, você precisa aceitar os Termos de Coleta de Métricas e Localização.\n\nDeseja revisar os termos agora?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Revisar Termos'),
            ),
          ],
        ),
      );

      if (shouldReview == true && mounted) {
        // Navigate to ConsentScreen
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
      }
      return;
    }

    // 2. If already consented, go straight to "Are you here?"
    await _askAreYouHere();
  }

  Future<void> _askAreYouHere() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ativar Previsão do Tempo'),
        content: const Text(
          'Para mostrar a previsão correta, precisamos da localização desta propriedade.\n\n'
          'Você está na propriedade agora?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Não, estou longe'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sim, estou aqui'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _captureAndSaveLocation();
    } else if (confirmed == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Sem problema! Você pode configurar a localização manualmente no menu "Propriedades" quando souber as coordenadas.'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _captureAndSaveLocation() async {
    if (widget.propertyId == null) return;

    setState(() => _isLoading = true);

    try {
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Serviço de localização desativado.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permissão de localização negada.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Permissão negada permanentemente. Habilite nas configurações.');
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
            const SnackBar(
              content: Text('Localização atualizada! Carregando previsão...'),
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
            content: Text('Erro ao obter localização: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }
}
