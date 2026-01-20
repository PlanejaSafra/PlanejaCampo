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
    final futurePoints = summary.points
        .where((p) => p.time.isAfter(now.subtract(const Duration(minutes: 5))))
        .toList();

    if (futurePoints.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      color: Colors.blue.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.blue.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.umbrella, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  summary.getStatusMessage(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: futurePoints.map((p) {
                  // Normalize height: 0.1mm to 5.0mm scale
                  // 0.1mm -> 10% height
                  // 2.0mm -> 100% height (heavy rain)
                  double intensity = p.precipitationMm;
                  if (intensity < 0.0) intensity = 0;

                  double heightFactor = (intensity / 2.0).clamp(0.05, 1.0);
                  if (intensity == 0) heightFactor = 0.02; // Tiny baseline

                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 30 * heightFactor,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(
                                alpha: (intensity > 0
                                    ? 0.4 + (intensity / 5.0).clamp(0, 0.6)
                                    : 0.1)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Only show label for every other point to save space?
                        // Or just first and last?
                        // Api is 15 min interval, so we probably have 4-5 points.
                        Text(
                          DateFormat.Hm().format(p.time),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
