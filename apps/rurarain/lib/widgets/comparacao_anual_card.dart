import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget that displays a year-over-year comparison table.
/// Shows monthly totals for current year vs previous year side-by-side.
class ComparacaoAnualCard extends StatelessWidget {
  /// Map of month keys to rainfall totals.
  /// Key format: "2024-01" (year-month)
  final Map<String, double> monthlyData;

  /// Locale for date formatting.
  final String locale;

  const ComparacaoAnualCard({
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
    final now = DateTime.now();
    final currentYear = now.year;
    final previousYear = currentYear - 1;

    // Group data by year
    final currentYearData = <int, double>{};
    final previousYearData = <int, double>{};

    for (final entry in monthlyData.entries) {
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);

      if (year == currentYear) {
        currentYearData[month] = entry.value;
      } else if (year == previousYear) {
        previousYearData[month] = entry.value;
      }
    }

    // Build comparison table
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              locale.startsWith('pt')
                  ? 'Comparação Anual'
                  : 'Year Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Table header
            _buildTableHeader(context, currentYear, previousYear),
            const Divider(),
            // Monthly rows
            ...List.generate(12, (index) {
              final month = index + 1;
              return _buildMonthRow(
                context,
                month: month,
                currentYearValue: currentYearData[month] ?? 0.0,
                previousYearValue: previousYearData[month] ?? 0.0,
              );
            }),
            const Divider(),
            // Totals row
            _buildTotalsRow(
              context,
              currentYearTotal: currentYearData.values.fold(0.0, (sum, v) => sum + v),
              previousYearTotal: previousYearData.values.fold(0.0, (sum, v) => sum + v),
            ),
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
                ? 'Nenhum dado para comparar'
                : 'No data to compare',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, int currentYear, int previousYear) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            locale.startsWith('pt') ? 'Mês' : 'Month',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            currentYear.toString(),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            previousYear.toString(),
            textAlign: TextAlign.end,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthRow(
    BuildContext context, {
    required int month,
    required double currentYearValue,
    required double previousYearValue,
  }) {
    final theme = Theme.of(context);
    final date = DateTime(2024, month, 1);
    final monthName = DateFormat.MMM(locale).format(date);

    // Determine color based on comparison
    Color? currentColor;
    if (currentYearValue > 0 && previousYearValue > 0) {
      if (currentYearValue > previousYearValue) {
        currentColor = Colors.green;
      } else if (currentYearValue < previousYearValue) {
        currentColor = Colors.orange;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              monthName,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Text(
              currentYearValue > 0 ? currentYearValue.toStringAsFixed(1) : '-',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: currentColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              previousYearValue > 0 ? previousYearValue.toStringAsFixed(1) : '-',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(
    BuildContext context, {
    required double currentYearTotal,
    required double previousYearTotal,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              locale.startsWith('pt') ? 'TOTAL' : 'TOTAL',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${currentYearTotal.toStringAsFixed(1)} mm',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${previousYearTotal.toStringAsFixed(1)} mm',
              textAlign: TextAlign.end,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
