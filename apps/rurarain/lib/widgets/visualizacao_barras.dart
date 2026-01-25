import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays monthly rainfall data as ASCII-style bar charts.
/// Uses Unicode block characters for visual representation without external libraries.
class VisualizacaoBarrasWidget extends StatelessWidget {
  /// Map of month keys to total rainfall in mm.
  /// Key format: "2024-01" (year-month)
  final Map<String, double> monthlyData;

  /// Locale for date formatting.
  final String locale;

  const VisualizacaoBarrasWidget({
    super.key,
    required this.monthlyData,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return _buildEmptyState(context);
    }

    final theme = Theme.of(context);
    final sortedMonths = monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));
    final maxValue = monthlyData.values.reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.startsWith('pt')
                  ? 'Chuva Mensal (últimos 12 meses)'
                  : 'Monthly Rainfall (last 12 months)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedMonths.take(12).map((monthKey) {
              final value = monthlyData[monthKey]!;
              return _buildBarRow(
                context,
                monthKey: monthKey,
                value: value,
                maxValue: maxValue,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            locale.startsWith('pt')
                ? 'Nenhum dado para visualizar'
                : 'No data to visualize',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarRow(
    BuildContext context, {
    required String monthKey,
    required double value,
    required double maxValue,
  }) {
    final theme = Theme.of(context);

    // Parse month key (format: "YYYY-MM")
    final parts = monthKey.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final date = DateTime(year, month, 1);

    // Format month name
    final monthName = DateFormat.MMM(locale).format(date);

    // Calculate bar width (0-100%)
    final percentage = maxValue > 0 ? (value / maxValue) : 0;
    final barWidth = (percentage * 100).clamp(0, 100);

    // Choose color based on value
    Color barColor;
    if (value < 50) {
      barColor = Colors.orange; // Low rainfall
    } else if (value < 100) {
      barColor = Colors.lightGreen; // Moderate rainfall
    } else {
      barColor = Colors.green; // Good rainfall
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month name and value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$monthName $year',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} mm',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Bar visualization
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: barWidth / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
