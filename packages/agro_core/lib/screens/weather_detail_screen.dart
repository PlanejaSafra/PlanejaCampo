import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/weather_service.dart'; // Ensure this import exists or use appropriate model imports
import '../widgets/weather_card.dart'; // Likely not needed if we duplicate icon logic or move it to a helper, but let's see.

class WeatherDetailScreen extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final String? propertyName;

  const WeatherDetailScreen({
    super.key,
    required this.weatherData,
    this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Extract data
    final current = weatherData['current'];
    final daily = weatherData['daily'];
    final hourly = weatherData['hourly'];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Previsão do Tempo'),
            if (propertyName != null)
              Text(
                '📍 $propertyName',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_upward,
                  size: 16, color: theme.colorScheme.onPrimaryContainer),
              Text('$max°  ',
                  style:
                      TextStyle(color: theme.colorScheme.onPrimaryContainer)),
              Icon(Icons.arrow_downward,
                  size: 16, color: theme.colorScheme.onPrimaryContainer),
              Text('$min°',
                  style:
                      TextStyle(color: theme.colorScheme.onPrimaryContainer)),
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
      height: 140, // Height for card
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        itemBuilder: (context, i) {
          final index = startIndex + i;
          final time = DateTime.parse(times[index]);
          final temp = temps[index];
          final code = codes[index] as int;

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
                  const Spacer(),
                  Text(
                    '$temp°',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rain > 0)
            Row(
              children: [
                Icon(Icons.water_drop, size: 14, color: Colors.blue[400]),
                Text(' ${rain}mm  ',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ],
            ),
          Text('$max° / $min°',
              style: const TextStyle(fontWeight: FontWeight.bold)),
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
}
