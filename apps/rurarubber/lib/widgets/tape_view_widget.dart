import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TapeViewWidget extends StatelessWidget {
  final List<double> entries;
  final VoidCallback? onDeleteLast;
  final VoidCallback? onShare;

  const TapeViewWidget({
    super.key,
    required this.entries,
    this.onDeleteLast,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    // Calculate intermediate sums for the "tape" effect
    // But for simplicity, we just show the list of inputs

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.amber[50], // Paper roll color hint
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.tapeViewTitle,
                  style: const TextStyle(
                    fontFamily: 'Monospace',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entries.isNotEmpty && onShare != null)
                      InkWell(
                        onTap: onShare,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.share, size: 18, color: Colors.green),
                        ),
                      ),
                    if (entries.isNotEmpty && onDeleteLast != null)
                      InkWell(
                        onTap: onDeleteLast,
                        child: const Icon(Icons.undo, size: 16, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              reverse: true, // Show newest at bottom like a receipt? Or top?
              // Usually calculators show history:
              // 120
              // + 95
              // = 215
              // Let's scroll to bottom logic.
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                // If we reverse, index 0 is the last item added
                final value = entries[entries.length - 1 - index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.grey),
                      Text(
                        '${value.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                          fontFamily: 'Monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (entries.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  l10n.tapeViewEmpty,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.pesagemTotalAccumulated,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${entries.fold(0.0, (sum, e) => sum + e).toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
