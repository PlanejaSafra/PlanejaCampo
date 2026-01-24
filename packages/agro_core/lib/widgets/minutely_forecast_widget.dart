import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/instant_weather_forecast.dart';
import '../l10n/generated/app_localizations.dart';

class MinutelyForecastWidget extends StatelessWidget {
  final InstantForecastSummary summary;

  const MinutelyForecastWidget({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.points.isEmpty || !summary.willRainSoon) {
      return const SizedBox.shrink();
    }

    final l10n = AgroLocalizations.of(context)!;
    final now = DateTime.now();

    // Filter for next 60 minutes only (approx 4 points)
    final futurePoints = summary.points
        .where((p) => p.time.isAfter(now.subtract(const Duration(minutes: 5))))
        .take(4) // Only show next hour (15min * 4)
        .toList();

    if (futurePoints.isEmpty) return const SizedBox.shrink();

    // Only show if there is actual rain in this period (>= 0.3mm threshold)
    if (!futurePoints.any((p) => p.precipitationMm >= 0.3)) {
      return const SizedBox.shrink();
    }

    // Find max intensity for scaling (min 2.0mm for visual baseline)
    double maxMm = 2.0;
    for (var p in futurePoints) {
      if (p.precipitationMm > maxMm) maxMm = p.precipitationMm;
    }

    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.umbrella, size: 18, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  summary.getStatusMessage(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: futurePoints.map((p) {
                double intensity = p.precipitationMm;
                if (intensity < 0) intensity = 0;

                // Scale height relative to max in this period
                // Max height = 50px
                double heightFactor = (intensity / maxMm).clamp(0.0, 1.0);
                // Min visual height for 0mm is small just to show the slot
                double barHeight = intensity == 0 ? 4 : (50 * heightFactor);
                if (barHeight < 4) barHeight = 4;

                Color barColor = intensity == 0
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.blue.withValues(
                        alpha: 0.5 + (intensity / maxMm).clamp(0, 0.5));

                return Column(
                  children: [
                    // Intensity Label (e.g. 2.5 mm)
                    if (intensity > 0)
                      Text(
                        "${intensity.toStringAsFixed(1)}mm",
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold),
                      )
                    else
                      const SizedBox(height: 14), // Spacer

                    const SizedBox(height: 4),

                    // Bar
                    Container(
                      width: 16,
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Time Label
                    Text(
                      DateFormat.Hm().format(p.time),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
