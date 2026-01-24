import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agro_core/agro_core.dart';
import '../services/chuva_service.dart';

class BalancoHidricoChart extends StatefulWidget {
  final String propertyId;
  final String? talhaoId; // Added optional talhaoId
  final double latitude;
  final double longitude;

  const BalancoHidricoChart({
    super.key,
    required this.propertyId,
    this.talhaoId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<BalancoHidricoChart> createState() => _BalancoHidricoChartState();
}

class _BalancoHidricoChartState extends State<BalancoHidricoChart> {
  bool _isLoading = true;
  final Map<int, double> _monthlyRain = {};
  final Map<int, double> _monthlyEt0 = {};
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant BalancoHidricoChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.propertyId != widget.propertyId ||
        oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.talhaoId != widget.talhaoId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      _months.clear();
      _monthlyRain.clear();
      _monthlyEt0.clear();

      // 1. Prepare Last 12 Months
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        _months.add(monthDate);
      }

      // 2. Load User Rain Data
      // Assuming ChuvaService is available and initialized
      final chuvaService = ChuvaService();
      // Ensure box is open? The parent screen usually handles this, but safe check:
      // await chuvaService.init(); // Usually safe to skip if app already runs.

      for (var month in _months) {
        // Use totalDoMesByTalhao to respect filters
        final total = chuvaService.totalDoMesByTalhao(month, widget.propertyId,
            talhaoId: widget.talhaoId);
        // Use month index (0..11) for X-axis
        _monthlyRain[_months.indexOf(month)] = total;
      }

      // 3. Load Historical ET0 from Open-Meteo
      // Start date: 1st day of 11 months ago
      // End date: last day of current month (or yesterday)
      final startDate = _months.first;
      final endDate = now.subtract(
          const Duration(days: 1)); // Archive is until yesterday usually

      final et0Map = await WeatherService().getHistoricalEvapotranspiration(
        latitude: widget.latitude,
        longitude: widget.longitude,
        startDate: startDate,
        endDate: endDate,
      );

      // Aggregate ET0 by month
      for (var entry in et0Map.entries) {
        final date = entry.key;
        final val = entry.value;

        // Find which month-index this date belongs to
        // We match by year and month
        final monthIndex = _months
            .indexWhere((m) => m.year == date.year && m.month == date.month);

        if (monthIndex != -1) {
          _monthlyEt0[monthIndex] = (_monthlyEt0[monthIndex] ?? 0.0) + val;
        }
      }
    } catch (e) {
      debugPrint('Error loading water balance data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Determine Y max for scaling
    double maxVal = 100.0;
    for (var v in _monthlyRain.values) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in _monthlyEt0.values) {
      if (v > maxVal) maxVal = v;
    }
    maxVal = maxVal * 1.1; // 10% padding

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Balanço Hídrico (12 Meses)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem(theme, 'Precipitação (Você)', Colors.blue),
                _buildLegendItem(
                    theme, 'Evapotranspiração (Estimada)', Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: theme.colorScheme.outlineVariant,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < _months.length) {
                            // Show abbreviated month: "Jan"
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                DateFormat.MMM('pt_BR').format(_months[index]),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxVal / 5,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: theme.textTheme.labelSmall,
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: 11,
                  minY: 0,
                  maxY: maxVal,
                  lineBarsData: [
                    // Rain Line (Blue)
                    LineChartBarData(
                      spots: _monthlyRain.entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withValues(alpha: 0.1),
                      ),
                    ),
                    // ET0 Line (Orange)
                    LineChartBarData(
                      spots: _monthlyEt0.entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dashArray: [5, 5],
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (touchedSpot) =>
                            theme.colorScheme.surfaceContainerHighest,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            final textStyle = TextStyle(
                              color: touchedSpot.bar.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            );
                            return LineTooltipItem(
                              '${touchedSpot.y.toStringAsFixed(1)} mm',
                              textStyle,
                            );
                          }).toList();
                        }),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
