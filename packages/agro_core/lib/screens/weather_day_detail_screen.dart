import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherDayDetailScreen extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> dailyData;
  final Map<String, dynamic>? hourlyData;
  final int dailyIndex;
  final String? propertyName;

  const WeatherDayDetailScreen({
    super.key,
    required this.date,
    required this.dailyData,
    this.hourlyData,
    required this.dailyIndex,
    this.propertyName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Logic for relative date label
    String dateLabel;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(date.year, date.month, date.day);
    final diff = checkDate.difference(today).inDays;

    if (diff == 0) {
      dateLabel = 'Previsão para Hoje';
    } else if (diff == 1) {
      dateLabel = 'Previsão para Amanhã';
    } else {
      final weekday = DateFormat('EEEE', 'pt_BR').format(date);
      // Capitalize first letter
      final capitalized =
          weekday.replaceFirst(weekday[0], weekday[0].toUpperCase());
      dateLabel = 'Previsão para $capitalized';
    }

    // Secondary date label (e.g. 25 jan)
    final dateSuffix = DateFormat("d 'de' MMMM", 'pt_BR').format(date);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Detalhes da Previsão'),
            if (propertyName != null)
              Text(
                propertyName!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDailySummary(context, dateLabel, dateSuffix),
            const SizedBox(height: 24),
            if (hourlyData != null) _buildHourlyList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDailySummary(
      BuildContext context, String dateLabel, String dateSuffix) {
    final theme = Theme.of(context);

    final max = dailyData['temperature_2m_max'][dailyIndex];
    final min = dailyData['temperature_2m_min'][dailyIndex];
    final code = dailyData['weather_code'][dailyIndex] as int;
    final rain = dailyData['precipitation_sum']?[dailyIndex] ?? 0.0;
    final windSpeed =
        dailyData['wind_speed_10m_max']?[dailyIndex] as double? ?? 0.0;
    final windDir =
        dailyData['wind_direction_10m_dominant']?[dailyIndex] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          // Date Label Section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  dateLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  dateSuffix,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            _getWeatherIcon(code),
            size: 64,
            color: theme.colorScheme.onPrimaryContainer,
          ),
          const SizedBox(height: 16),
          Text(
            _getWeatherDescription(code),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                  context, Icons.thermostat, '$max° / $min°', 'Temp (Max/Min)'),
              _buildStatItem(context, Icons.water_drop, '${rain}mm',
                  'Precipitação' // TODO: l10n
                  ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                context,
                Icons.air,
                '${windSpeed.round()} km/h',
                'Vento Max',
                iconRotation: (windDir * 3.14159 / 180),
              ),
              // We could add Probability if available, but daily prob is tricky in Open-Meteo
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String value, String label,
      {double? iconRotation}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconRotation != null)
              Transform.rotate(
                angle: iconRotation,
                child: Icon(Icons.arrow_upward,
                    size: 24, color: theme.colorScheme.onPrimaryContainer),
              )
            else
              Icon(icon, size: 24, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(width: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyList(BuildContext context) {
    if (hourlyData == null) return const SizedBox.shrink();

    final times = hourlyData!['time'] as List;
    final temps = hourlyData!['temperature_2m'] as List;
    final codes = hourlyData!['weather_code'] as List;
    final precipitations = hourlyData!['precipitation'] as List?;
    final winds = hourlyData!['wind_speed_10m'] as List?;

    // Filter for this specific date
    // API times are ISO strings: "2023-10-25T00:00"
    // We want all hours where time matches our date (Year-Month-Day)

    final dayStr = DateFormat('yyyy-MM-dd').format(date);
    final dayIndices = <int>[];

    for (int i = 0; i < times.length; i++) {
      if (times[i].toString().startsWith(dayStr)) {
        dayIndices.add(i);
      }
    }

    if (dayIndices.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Evolução Horária', // TODO: L10n
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dayIndices.length,
            itemBuilder: (context, i) {
              final index = dayIndices[i];
              final time = DateTime.parse(times[index]);
              final temp = temps[index];
              final code = codes[index] as int;
              final precip = precipitations != null
                  ? (precipitations[index] as num).toDouble()
                  : 0.0;
              final wind =
                  winds != null ? (winds[index] as num).toDouble() : 0.0;

              return Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                margin: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(time),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Icon(_getWeatherIcon(code), size: 24),
                      if (precip >= 0.1)
                        Text(
                          '${precip}mm',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold),
                        )
                      else
                        const SizedBox(height: 14),
                      const SizedBox(height: 4),
                      Text(
                        '$temp°',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.air, size: 10, color: Colors.grey[600]),
                          Text(
                            ' ${wind.round()}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Helpers (Should be shared) ---
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
