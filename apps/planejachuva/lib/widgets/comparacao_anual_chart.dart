import 'package:agro_core/agro_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ComparacaoAnualChart extends StatelessWidget {
  final Map<String, double> monthlyData;
  final String locale;

  const ComparacaoAnualChart({
    super.key,
    required this.monthlyData,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final now = DateTime.now();
    final currentYear = now.year;
    final previousYear = currentYear - 1;

    // Process data
    final currentYearData = <int, double>{};
    final previousYearData = <int, double>{};

    for (int i = 1; i <= 12; i++) {
      currentYearData[i] = 0.0;
      previousYearData[i] = 0.0;
    }

    for (final entry in monthlyData.entries) {
      final parts = entry.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);

      if (y == currentYear) {
        currentYearData[m] = entry.value;
      } else if (y == previousYear) {
        previousYearData[m] = entry.value;
      }
    }

    final maxY = [...currentYearData.values, ...previousYearData.values]
        .reduce((a, b) => a > b ? a : b);

    // Add 20% headroom
    final targetMaxY = maxY > 0 ? maxY * 1.2 : 10.0;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AgroLocalizations.of(context)!.chuvaChartComparativeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildLegend(context, currentYear, previousYear),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: targetMaxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) =>
                            theme.colorScheme.surfaceContainerHighest,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final year =
                              rodIndex == 0 ? previousYear : currentYear;
                          return BarTooltipItem(
                            '${_getMonthName(group.x.toInt())} $year\n',
                            theme.textTheme.bodySmall!,
                            children: [
                              TextSpan(
                                text: '${rod.toY.toStringAsFixed(1)} mm',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: rod.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value < 1 || value > 12)
                              return const SizedBox.shrink();
                            // Show abbreviated month: J, F, M... or Jan, Feb
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                _getMonthName(value.toInt()).substring(0, 3),
                                style: theme.textTheme.labelSmall,
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value == 0) return const SizedBox.shrink();
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            );
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.5),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: List.generate(12, (index) {
                      final month = index + 1;
                      return BarChartGroupData(
                        x: month,
                        barRods: [
                          BarChartRodData(
                            toY: previousYearData[month] ?? 0,
                            color: theme.colorScheme.outline
                                .withValues(alpha: 0.5),
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          BarChartRodData(
                            toY: currentYearData[month] ?? 0,
                            color: theme.colorScheme.primary,
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context, int currentYear, int previousYear) {
    final theme = Theme.of(context);
    return Flexible(
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        alignment: WrapAlignment.end,
        children: [
          _buildLegendItem(context, previousYear.toString(),
              theme.colorScheme.outline.withValues(alpha: 0.5)),
          _buildLegendItem(
              context, currentYear.toString(), theme.colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String text, Color color) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    // Basic date formatting without complex intl setup for this specific widget if needed,
    // or reusing standard DateFormat
    final date = DateTime(2024, month, 1);
    return DateFormat.MMM(locale).format(date);
  }
}
