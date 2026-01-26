import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Screen showing 5-day weather forecast with detailed information.
class WeatherDetailScreen extends StatefulWidget {
  final String propertyId;
  final double latitude;
  final double longitude;

  const WeatherDetailScreen({
    super.key,
    required this.propertyId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherDetailScreen> createState() => _WeatherDetailScreenState();
}

class _WeatherDetailScreenState extends State<WeatherDetailScreen> {
  final _weatherService = WeatherService();
  List<WeatherForecast> _forecasts = [];
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorDetail;

  @override
  void initState() {
    super.initState();
    _loadForecasts();
  }

  Future<void> _loadForecasts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      await _weatherService.init();

      final forecasts = await _weatherService.getForecast(
        latitude: widget.latitude,
        longitude: widget.longitude,
        propertyId: widget.propertyId,
      );

      setState(() {
        _forecasts = forecasts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorDetail = e.toString();
      });
    }
  }

  Future<void> _refreshForecasts() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final forecasts = await _weatherService.refreshForecast(
        latitude: widget.latitude,
        longitude: widget.longitude,
        propertyId: widget.propertyId,
      );

      setState(() {
        _forecasts = forecasts;
        _isLoading = false;
      });

      if (mounted) {
        final l10n = AgroLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.weatherForecastUpdated),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorDetail = e.toString();
      });
    }
  }

  String _formatDate(DateTime date, AgroLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final forecastDate = DateTime(date.year, date.month, date.day);

    if (forecastDate == today) {
      return l10n.chuvaHoje;
    } else if (forecastDate == tomorrow) {
      return l10n.weatherTomorrow;
    } else {
      return DateFormat.MMMMEEEEd(locale).format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.weatherForecastTitle),
        actions: [
          IconButton(
            icon: Icon(_isLoading ? Icons.hourglass_empty : Icons.refresh),
            onPressed: _isLoading ? null : _refreshForecasts,
            tooltip: l10n.weatherRefreshTooltip,
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  Widget _buildBody(ThemeData theme, AgroLocalizations l10n) {
    if (_isLoading && _forecasts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError && _forecasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.weatherForecastLoadError(_errorDetail ?? ''),
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadForecasts,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.tryAgainButton),
              ),
            ],
          ),
        ),
      );
    }

    if (_forecasts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cloud_queue,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.weatherNoForecastAvailable,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadForecasts,
                icon: const Icon(Icons.download),
                label: Text(l10n.loadForecastButton),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshForecasts,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Cache status info
          if (_forecasts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getCacheInfo(l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Forecast cards
          ..._forecasts
              .map((forecast) => _buildForecastCard(forecast, theme, l10n)),
          const SizedBox(height: 16),
          // Attribution
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.weatherAttribution,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getCacheInfo(AgroLocalizations l10n) {
    if (_forecasts.isEmpty) return '';

    final age = DateTime.now().difference(_forecasts.first.cachedAt);
    final isValid = _forecasts.first.isCacheValid;
    final stale = isValid ? '' : l10n.weatherCacheStale;

    if (age.inMinutes < 60) {
      return '${l10n.weatherCacheMinutes(age.inMinutes)}$stale';
    } else if (age.inHours < 24) {
      return '${l10n.weatherCacheHours(age.inHours)}$stale';
    } else {
      return '${l10n.weatherCacheDays(age.inDays)}$stale';
    }
  }

  Widget _buildForecastCard(
      WeatherForecast forecast, ThemeData theme, AgroLocalizations l10n) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and weather icon
            Row(
              children: [
                Text(
                  forecast.getWeatherIcon(),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(forecast.date, l10n),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        forecast.getWeatherDescription(),
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            // Precipitation
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.water_drop,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weatherPrecipitation,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#0.0', 'pt_BR').format(forecast.precipitationMm)} mm',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Temperature
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.thermostat,
                    color: theme.colorScheme.secondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.weatherTemperature,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '${forecast.temperatureMin.toStringAsFixed(0)}° - ${forecast.temperatureMax.toStringAsFixed(0)}°C',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
