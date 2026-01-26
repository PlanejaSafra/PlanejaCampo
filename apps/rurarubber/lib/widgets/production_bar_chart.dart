import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// A simple horizontal bar chart built with basic Flutter widgets.
///
/// Each bar shows: label, value in kg, and a colored Container
/// proportional to the maximum value. An optional dashed phantom
/// line represents the farm average for comparison.
///
/// NO fl_chart dependency -- pure Container-based bars.
///
/// See RUBBER-21.3.
class ProductionBarChart extends StatelessWidget {
  const ProductionBarChart({
    super.key,
    required this.data,
    this.phantomLineValue,
  });

  /// Map of period label -> weight in kg.
  final Map<String, double> data;

  /// Optional farm average value to display as a phantom reference line.
  final double? phantomLineValue;

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (data.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.homeSummaryNoData,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final maxValue = _computeMaxValue();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Phantom line legend
        if (phantomLineValue != null && phantomLineValue! > 0) ...[
          _PhantomLineLegend(
            value: phantomLineValue!,
            label: l10n.mediaFazenda,
          ),
          const SizedBox(height: 8),
        ],
        // Bars
        ...data.entries.map(
          (entry) => _BarRow(
            label: entry.key,
            value: entry.value,
            maxValue: maxValue,
            phantomLineValue: phantomLineValue,
            barColor: Colors.green.shade600,
          ),
        ),
      ],
    );
  }

  double _computeMaxValue() {
    double max = 0;
    for (final v in data.values) {
      if (v > max) max = v;
    }
    if (phantomLineValue != null && phantomLineValue! > max) {
      max = phantomLineValue!;
    }
    return max > 0 ? max : 1;
  }
}

/// A single horizontal bar row.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.barColor,
    this.phantomLineValue,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color barColor;
  final double? phantomLineValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
    final pv = phantomLineValue;
    final phantomFraction = (pv != null && maxValue > 0)
        ? (pv / maxValue).clamp(0.0, 1.0)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label and value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.toStringAsFixed(1)} kg',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Bar with optional phantom line marker
          LayoutBuilder(
            builder: (context, constraints) {
              final barWidth = constraints.maxWidth * fraction;
              final phantomX = phantomFraction != null
                  ? constraints.maxWidth * phantomFraction
                  : null;

              return SizedBox(
                height: 20,
                child: Stack(
                  children: [
                    // Background
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Filled bar
                    Container(
                      width: barWidth,
                      height: 20,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Phantom line marker
                    if (phantomX != null && phantomX > 0)
                      Positioned(
                        left: phantomX - 1,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          size: const Size(2, 20),
                          painter: _DashedLinePainter(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Legend row for the phantom (farm average) line.
class _PhantomLineLegend extends StatelessWidget {
  const _PhantomLineLegend({
    required this.value,
    required this.label,
  });

  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Dashed line indicator
        SizedBox(
          width: 24,
          height: 2,
          child: CustomPaint(
            painter: _DashedLinePainter(
              color: Colors.grey.shade600,
              horizontal: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${value.toStringAsFixed(1)} kg',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Simple custom painter for dashed lines (vertical or horizontal).
class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({
    required this.color,
    this.horizontal = false,
  });

  final Color color;
  final bool horizontal;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashLength = 3.0;
    const gapLength = 2.0;

    if (horizontal) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
          Offset(x, size.height / 2),
          Offset((x + dashLength).clamp(0, size.width), size.height / 2),
          paint,
        );
        x += dashLength + gapLength;
      }
    } else {
      double y = 0;
      while (y < size.height) {
        canvas.drawLine(
          Offset(size.width / 2, y),
          Offset(size.width / 2, (y + dashLength).clamp(0, size.height)),
          paint,
        );
        y += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.horizontal != horizontal;
  }
}
