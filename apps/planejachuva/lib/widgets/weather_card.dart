import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_forecast.dart';
import '../screens/weather_detail_screen.dart';
import '../services/weather_service.dart';

/// Card widget displaying today's weather forecast on the home screen.
/// Tapping opens detailed 5-day forecast.
class WeatherCard extends StatefulWidget {
  final String propertyId;
  final double? latitude;
  final double? longitude;

  const WeatherCard({
    super.key,
    required this.propertyId,
    this.latitude,
    this.longitude,
  });

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  final _weatherService = WeatherService();
  WeatherForecast? _todayForecast;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadForecast();
  }

  Future<void> _loadForecast() async {
    // Check if property has location configured
    if (widget.latitude == null || widget.longitude == null) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Configure a localização da propriedade';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _weatherService.init();

      // Try to get from cache first
      if (_weatherService.hasCachedForecast(widget.propertyId)) {
        _todayForecast = _weatherService.getTodayForecast(widget.propertyId);
      }

      // Fetch fresh forecast (will use cache if still valid)
      final forecasts = await _weatherService.getForecast(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        propertyId: widget.propertyId,
      );

      if (forecasts.isNotEmpty) {
        setState(() {
          _todayForecast = forecasts.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erro ao carregar previsão';
      });
    }
  }

  Future<void> _refreshForecast() async {
    if (widget.latitude == null || widget.longitude == null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final forecasts = await _weatherService.refreshForecast(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        propertyId: widget.propertyId,
      );

      if (forecasts.isNotEmpty) {
        setState(() {
          _todayForecast = forecasts.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erro ao atualizar previsão';
      });
    }
  }

  String _getCacheAgeText() {
    if (_todayForecast == null) return '';

    final age = DateTime.now().difference(_todayForecast!.cachedAt);
    if (age.inMinutes < 60) {
      return 'Atualizado há ${age.inMinutes} min';
    } else {
      return 'Atualizado há ${age.inHours}h';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          if (_todayForecast != null &&
              widget.latitude != null &&
              widget.longitude != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WeatherDetailScreen(
                  propertyId: widget.propertyId,
                  latitude: widget.latitude!,
                  longitude: widget.longitude!,
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildContent(theme, l10n),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AgroLocalizations l10n) {
    if (_isLoading && _todayForecast == null) {
      return Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Carregando previsão...',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      );
    }

    if (_hasError && _todayForecast == null) {
      return Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'Erro ao carregar previsão',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          if (widget.latitude != null && widget.longitude != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _refreshForecast,
              tooltip: 'Tentar novamente',
            ),
        ],
      );
    }

    if (_todayForecast == null) {
      return Row(
        children: [
          const Icon(Icons.cloud_off, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text('Nenhuma previsão disponível'),
          ),
          if (widget.latitude != null && widget.longitude != null)
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadForecast,
              tooltip: 'Carregar previsão',
            ),
        ],
      );
    }

    // Display forecast
    return Row(
      children: [
        // Weather icon
        Text(
          _todayForecast!.getWeatherIcon(),
          style: const TextStyle(fontSize: 40),
        ),
        const SizedBox(width: 16),
        // Forecast details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Previsão: ${_todayForecast!.getWeatherDescription()}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.water_drop,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${NumberFormat('#0.0', 'pt_BR').format(_todayForecast!.precipitationMm)} mm',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.thermostat,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_todayForecast!.temperatureMin.toStringAsFixed(0)}° - ${_todayForecast!.temperatureMax.toStringAsFixed(0)}°C',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getCacheAgeText(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  if (!_todayForecast!.isCacheValid)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Cache antigo',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Refresh button
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: _isLoading
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onPressed: _isLoading ? null : _refreshForecast,
          tooltip: 'Atualizar previsão',
        ),
      ],
    );
  }
}
