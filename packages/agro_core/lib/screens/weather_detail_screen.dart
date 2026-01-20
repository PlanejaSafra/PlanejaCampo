import 'package:flutter/material.dart';
import '../utils/location_helper.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart';
import '../models/weather_alert.dart';
import '../l10n/generated/app_localizations.dart';

class WeatherDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final String? propertyName;
  final String? propertyId;

  const WeatherDetailScreen({
    super.key,
    required this.weatherData,
    this.propertyName,
    this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract data
    // Extract data
    final current = weatherData['current'];
    final daily = weatherData['daily'];
    final hourly = weatherData['hourly'];

    // CORE-39: Weather Alerts
    List<WeatherAlert> alerts = [];
    if (propertyId != null) {
      final forecasts =
          WeatherService().parseForecastsFromMap(weatherData, propertyId!);
      alerts = WeatherService().analyzeForecasts(forecasts);
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Previsão do Tempo'),
            if (propertyName != null)
              InkWell(
                onTap: propertyId == null
                    ? null
                    : () {
                        LocationHelper.checkAndUpdateLocation(
                          context: context,
                          propertyId: propertyId!,
                          onLocationUpdated: () {
                            // Force reload?
                            // WeatherService implicitly fetches on next build if we invalidate
                            // But since this is a StatelessWidget, we can't setState.
                            // However, if location updates, the user likely navigates back?
                            // Or we provide visual feedback.
                          },
                        );
                      },
                child: Row(
                  // Row to make tap area better and add an icon hint
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '📍 $propertyName',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                        decoration:
                            TextDecoration.underline, // Hint it is clickable
                      ),
                    ),
                    Icon(Icons.edit,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ],
                ),
              ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Current Weather Highlight
          SliverToBoxAdapter(
            child: _buildCurrentHeader(context, current, daily),
          ),

          // CORE-39: Alerts Section
          if (alerts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildAlertsSection(context, alerts),
            ),

          // 2. Hourly Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Próximas 24 Horas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 3. Hourly Horizontal List
          if (hourly != null)
            SliverToBoxAdapter(
              child: _buildHourlyList(context, hourly),
            ),

          // 4. Daily Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Próximos 7 Dias',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 5. Daily Vertical List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dates = daily['time'] as List;
                if (index >= dates.length) return null;
                return _buildDailyItem(context, daily, index);
              },
              childCount: (daily['time'] as List).length,
            ),
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
    );
  }

  Widget _buildCurrentHeader(BuildContext context, Map current, Map daily) {
    final theme = Theme.of(context);
    final temp = current['temperature_2m'];
    final code = current['weather_code'] as int;
    final max = daily['temperature_2m_max'][0]; // Today max
    final min = daily['temperature_2m_min'][0]; // Today min
    // Wind (CORE-38)
    final windSpeed = current['wind_speed_10m'] as double?; // km/h
    final windDirection = current['wind_direction_10m'] as int?; // degrees

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(
            _getWeatherIcon(code),
            size: 64,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            '$temp°C',
            style: theme.textTheme.displayLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          Text(
            _getWeatherDescription(code),
            style: theme.textTheme.titleLarge?.copyWith(
              color:
                  theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Min/Max Temp
              Row(
                children: [
                  Icon(Icons.arrow_upward,
                      size: 16, color: theme.colorScheme.onPrimaryContainer),
                  Text('$max°  ',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer)),
                  Icon(Icons.arrow_downward,
                      size: 16, color: theme.colorScheme.onPrimaryContainer),
                  Text('$min°',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer)),
                ],
              ),
              // Wind Info (CORE-38)
              if (windSpeed != null && windDirection != null)
                Row(
                  children: [
                    Icon(Icons.air,
                        size: 16, color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      '${windSpeed.round()} km/h',
                      style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 2),
                    Transform.rotate(
                      angle: (windDirection * 3.14159 / 180),
                      child: Icon(Icons.arrow_upward,
                          size: 14,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyList(BuildContext context, Map hourly) {
    final times = hourly['time'] as List;
    final temps = hourly['temperature_2m'] as List;
    final codes = hourly['weather_code'] as List;
    final windSpeeds = hourly['wind_speed_10m'] as List?;
    final windDirections = hourly['wind_direction_10m'] as List?;

    // Open-Meteo returns huge list (7 days hourly). We only want next 24h.
    // We need to find "now" index.

    final now = DateTime.now();
    final hourFormat = DateFormat('HH:mm');

    // Simple filter: start from current hour, take 24.
    // Since API returns string ISO8601, we parse.

    int startIndex = 0;
    for (int i = 0; i < times.length; i++) {
      if (DateTime.parse(times[i])
          .isAfter(now.subtract(const Duration(hours: 1)))) {
        startIndex = i;
        break;
      }
    }

    final count =
        (times.length - startIndex) > 24 ? 24 : (times.length - startIndex);

    return SizedBox(
      height: 160, // Increased height for wind info
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        itemBuilder: (context, i) {
          final index = startIndex + i;
          final time = DateTime.parse(times[index]);
          final temp = temps[index];
          final code = codes[index] as int;
          final wSpeed = windSpeeds != null ? windSpeeds[index] as double : 0.0;
          final wDir =
              windDirections != null ? windDirections[index] as int : 0;

          return Card(
            elevation: 0,
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            margin: const EdgeInsets.only(right: 12),
            child: Container(
              width: 80,
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    i == 0 ? 'Agora' : hourFormat.format(time),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Icon(_getWeatherIcon(code), size: 32),
                  const SizedBox(height: 8),
                  Text(
                    '$temp°',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Wind Info Hourly
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.air, size: 10, color: Colors.grey[600]),
                      Text(
                        ' ${(wSpeed).round()}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(fontSize: 10, color: Colors.grey[700]),
                      ),
                      Transform.rotate(
                        angle: (wDir * 3.14159 / 180),
                        child: Icon(Icons.arrow_upward,
                            size: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyItem(BuildContext context, Map daily, int index) {
    final date = DateTime.parse(daily['time'][index]);
    final max = daily['temperature_2m_max'][index];
    final min = daily['temperature_2m_min'][index];
    final code = daily['weather_code'][index] as int;
    // Some OpenMeteo versions use precipitation_sum, some precipitation_probability_max
    final rain = daily['precipitation_sum']?[index] ?? 0.0;
    // Wind (CORE-38)
    final wSpeed = daily['wind_speed_10m_max']?[index] as double? ?? 0.0;
    final wDir = daily['wind_direction_10m_dominant']?[index] as int? ?? 0;

    final dateFormat = DateFormat('E, d MMM', 'pt_BR');

    return ListTile(
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getWeatherIcon(code)),
        ],
      ),
      title: Text(
        dateFormat.format(date),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _getWeatherDescription(code),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (rain > 0)
                Row(
                  children: [
                    Icon(Icons.water_drop, size: 14, color: Colors.blue[400]),
                    Text('${rain}mm  ',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ],
                ),
              Text('$max° / $min°',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.air, size: 12, color: Colors.grey[600]),
              Text(
                ' ${wSpeed.round()} km/h ',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Transform.rotate(
                angle: (wDir * 3.14159 / 180),
                child:
                    Icon(Icons.arrow_upward, size: 12, color: Colors.grey[600]),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- Helper Methods (Duplicated from WeatherCard for standalone) ---
  // Ideally these should be in a shared helper/mixin.

  IconData _getWeatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny;
    if (code >= 1 && code <= 3) return Icons.wb_cloudy;
    if (code >= 45 && code <= 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.water_drop;
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

  Widget _buildAlertsSection(BuildContext context, List<WeatherAlert> alerts) {
    final l10n = AgroLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.alertsSectionTitle,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              String title, message;
              switch (alert.titleKey) {
                case 'alertFrostTitle':
                  title = l10n.alertFrostTitle;
                  message = l10n.alertFrostMessage;
                  break;
                case 'alertHeatWaveTitle':
                  title = l10n.alertHeatWaveTitle;
                  message = l10n.alertHeatWaveMessage;
                  break;
                case 'alertStormTitle':
                  title = l10n.alertStormTitle;
                  message = l10n.alertStormMessage;
                  break;
                case 'alertDroughtTitle':
                  title = l10n.alertDroughtTitle;
                  message = l10n.alertDroughtMessage;
                  break;
                case 'alertHighWindTitle':
                  title = l10n.alertHighWindTitle;
                  message = l10n.alertHighWindMessage;
                  break;
                case 'alertHailTitle':
                  title = l10n.alertHailTitle;
                  message = l10n.alertHailMessage;
                  break;
                default:
                  title = alert.titleKey;
                  message = alert.messageKey;
              }

              final dateStr =
                  DateFormat('E, d MMM', 'pt_BR').format(alert.date);

              return Container(
                width: 260,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alert.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: alert.color.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(alert.icon, color: alert.color, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(title,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: alert.color,
                                  fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(dateStr,
                        style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(message,
                        style: TextStyle(color: Colors.grey[800], fontSize: 12),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
