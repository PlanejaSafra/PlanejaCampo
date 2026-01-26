import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/cloud_backup_service.dart';

/// Shows the restore confirmation dialog (Phase 2 of 3-phase restore).
///
/// Presents the [RestoreSession] analysis to the user before execution.
/// Returns `true` if the user confirms, `false` if cancelled.
///
/// See CORE-77 Section 5 for full architecture.
Future<bool> showRestoreConfirmationDialog(
  BuildContext context,
  RestoreSession session,
) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _RestoreConfirmationDialog(session: session),
  );
  return result ?? false;
}

class _RestoreConfirmationDialog extends StatelessWidget {
  final RestoreSession session;

  const _RestoreConfirmationDialog({required this.session});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    // Check if any provider blocks restore (no farm access)
    final hasNoAccess = session.analyses.values.any((a) => !a.canProceed);

    // Aggregate analysis across all providers
    final totalAdds = session.totalAdds;
    final totalDeletes = session.totalDeletes;
    final totalBlocked = session.totalBlocked;
    final hasWarnings = session.hasWarnings;
    final noChanges =
        totalAdds == 0 && totalDeletes == 0 && totalBlocked == 0;

    // Collect all warnings and recalculations
    final allWarnings = <String>[];
    final allRecalculations = <String>[];
    for (final analysis in session.analyses.values) {
      allWarnings.addAll(analysis.warnings);
      allRecalculations.addAll(analysis.recalculations);
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.restore, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.restoreConfirmTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.restoreConfirmSubtitle,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Blocked: user has no access to the backup farm
              if (hasNoAccess) ...[
                _InfoTile(
                  icon: Icons.lock_outline,
                  color: theme.colorScheme.error,
                  text: l10n.restoreNoFarmAccess,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 32, bottom: 12),
                  child: Text(
                    l10n.restoreNoFarmAccessExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],

              if (!hasNoAccess && noChanges)
                _InfoTile(
                  icon: Icons.check_circle_outline,
                  color: Colors.green,
                  text: l10n.restoreNoChanges,
                ),

              // Additions
              if (totalAdds > 0)
                _InfoTile(
                  icon: Icons.add_circle_outline,
                  color: Colors.green,
                  text: l10n.restoreWillAdd(totalAdds),
                ),

              // Deletions
              if (totalDeletes > 0)
                _InfoTile(
                  icon: Icons.remove_circle_outline,
                  color: Colors.orange,
                  text: l10n.restoreWillDelete(totalDeletes),
                ),

              // Blocked
              if (totalBlocked > 0) ...[
                _InfoTile(
                  icon: Icons.block,
                  color: Colors.red,
                  text: l10n.restoreBlocked(totalBlocked),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 40, bottom: 8),
                  child: Text(
                    l10n.restoreBlockedExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Show blocked items detail
                ...session.analyses.entries.expand((entry) {
                  final analysis = entry.value;
                  if (!analysis.hasBlocked) return <Widget>[];
                  return analysis.blocked.entries.map((blocked) {
                    final checkResult = blocked.value;
                    return Padding(
                      padding: const EdgeInsets.only(left: 40, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              checkResult.summary,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  });
                }),
              ],

              // Warnings
              if (hasWarnings && allWarnings.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.restoreWarningsSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                ...allWarnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.amber.shade800,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              warning,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              // Recalculations
              if (allRecalculations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.restoreRecalculationsSection,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    l10n.restoreRecalculationsExplanation,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                ...allRecalculations.map((recalc) => Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calculate_outlined,
                            size: 16,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recalc,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.restoreCancelButton),
        ),
        FilledButton.icon(
          onPressed: hasNoAccess
              ? null
              : () => Navigator.of(context).pop(true),
          icon: const Icon(Icons.restore),
          label: Text(l10n.restoreConfirmButton),
        ),
      ],
    );
  }
}

/// Compact info tile for restore summary items.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InfoTile({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
