import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Period options for the partner analytics view.
enum AnalyticsPeriod {
  biweekly,
  monthly,
  season,
}

/// A segmented button selector for choosing between
/// "15 Days", "Month", and "Season" periods.
///
/// See RUBBER-21.2.
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onChanged,
  });

  final AnalyticsPeriod selectedPeriod;
  final ValueChanged<AnalyticsPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SegmentedButton<AnalyticsPeriod>(
      segments: [
        ButtonSegment<AnalyticsPeriod>(
          value: AnalyticsPeriod.biweekly,
          label: Text(
            l10n.periodo15Dias,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment<AnalyticsPeriod>(
          value: AnalyticsPeriod.monthly,
          label: Text(
            l10n.periodoMes,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        ButtonSegment<AnalyticsPeriod>(
          value: AnalyticsPeriod.season,
          label: Text(
            l10n.periodoSafra,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
      selected: {selectedPeriod},
      onSelectionChanged: (selection) {
        onChanged(selection.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: WidgetStatePropertyAll(
          BorderSide(color: theme.colorScheme.outline),
        ),
      ),
      showSelectedIcon: false,
    );
  }
}
