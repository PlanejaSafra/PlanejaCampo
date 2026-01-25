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
  final Map<int, double> _monthlyBalance = {}; // Cumulative Balance
  final List<DateTime> _months = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ... (didUpdateWidget is same)

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      _months.clear();
      _monthlyRain.clear();
      _monthlyEt0.clear();
      _monthlyBalance.clear();

      // 1. Prepare Last 12 Months
      for (int i = 11; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        _months.add(monthDate);
      }

      // 2. Load User Rain Data & First Record Date
      final chuvaService = ChuvaService();
      final allRecords = chuvaService.listarByTalhao(widget.propertyId,
          talhaoId: widget.talhaoId);

      // Determine start date for balance calculation
      // It should be the first record date, or the start of the chart, whichever is later?
      // Actually, if first record is older, we just start accumulation from 0 at the start of chart (relative balance)?
      // Or should we try to approximate? Sticking to "relative to period" or "relative to first record if inside period".

      DateTime? firstRecordDate;
      if (allRecords.isNotEmpty) {
        // Records are sorted desc, so last is oldest
        firstRecordDate = allRecords.last.data;
      }

      for (var month in _months) {
        final total = chuvaService.totalDoMesByTalhao(month, widget.propertyId,
            talhaoId: widget.talhaoId);
        _monthlyRain[_months.indexOf(month)] = total;
      }

      // 3. Load Historical ET0
      final startDate = _months.first;
      final endDate = now.subtract(const Duration(days: 1));

      final et0Map = await WeatherService().getHistoricalEvapotranspiration(
        latitude: widget.latitude,
        longitude: widget.longitude,
        startDate: startDate,
        endDate: endDate,
      );

      // Aggregate ET0
      for (var entry in et0Map.entries) {
        final date = entry.key;
        final val = entry.value;
        final monthIndex = _months
            .indexWhere((m) => m.year == date.year && m.month == date.month);

        if (monthIndex != -1) {
          _monthlyEt0[monthIndex] = (_monthlyEt0[monthIndex] ?? 0.0) + val;
        }
      }

      // 4. Calculate Cumulative Balance
      double currentBalance = 0.0;
      bool started = false;

      for (int i = 0; i < _months.length; i++) {
        final monthDate = _months[i];

        // Logic: Start accumulating only if we passed the first record date
        // If firstRecordDate is NULL (no data), we never start? Or start at 0?
        // If firstRecordDate is BEFORE chart start, we start at i=0.
        // If firstRecordDate is INSIDE chart, we start at that month.

        if (!started && firstRecordDate != null) {
          // Check if this month is equal or after the first record month
          // Normalize to month start for comparison
          final mStart = DateTime(monthDate.year, monthDate.month, 1);
          final fStart =
              DateTime(firstRecordDate.year, firstRecordDate.month, 1);

          if (mStart.isAtSameMomentAs(fStart) || mStart.isAfter(fStart)) {
            started = true;
          }
        } else if (firstRecordDate != null &&
            firstRecordDate.isBefore(_months.first)) {
          // If first record is older than chart, we start immediately
          started = true;
        }

        if (started) {
          final rain = _monthlyRain[i] ?? 0.0;
          final et0 = _monthlyEt0[i] ?? 0.0;
          final balance = rain - et0;
          currentBalance += balance;
          _monthlyBalance[i] = currentBalance;
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

    // Determine Y range
    double maxVal = 100.0;
    double minVal = 0.0;

    for (var v in _monthlyRain.values) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in _monthlyEt0.values) {
      if (v > maxVal) maxVal = v;
    }
    for (var v in _monthlyBalance.values) {
      if (v > maxVal) maxVal = v;
      if (v < minVal) minVal = v;
    }

    // Add padding
    final range = maxVal - minVal;
    maxVal += range * 0.1;
    minVal -= range * 0.1;
    if (maxVal == minVal) maxVal += 10; // Avoid flat line error

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
                _buildLegendItem(theme, 'Precipitação', Colors.blue),
                _buildLegendItem(theme, 'Evapotranspiração', Colors.orange),
                _buildLegendItem(theme, 'Saldo Acumulado', Colors.teal),
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
                    horizontalInterval: (maxVal - minVal) / 5,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: value == 0
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.outlineVariant,
                        strokeWidth:
                            value == 0 ? 1.5 : 1, // Highlight zero line
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
                        interval: (maxVal - minVal) / 5,
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
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 11,
                  minY: minVal,
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
                    // Balance Line (Teal)
                    LineChartBarData(
                      spots: _monthlyBalance.entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: Colors.teal,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.teal.withValues(alpha: 0.1),
                      ),
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
                            String label = '';
                            if (touchedSpot.barIndex == 0) label = 'Chuva';
                            if (touchedSpot.barIndex == 1) label = 'ET0';
                            if (touchedSpot.barIndex == 2) label = 'Saldo';

                            return LineTooltipItem(
                              '$label: ${touchedSpot.y.toStringAsFixed(1)} mm',
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
