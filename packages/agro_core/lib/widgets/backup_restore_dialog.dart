import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/cloud_backup_service.dart';

/// Result of the backup restore dialog.
class BackupRestoreResult {
  final bool restore;
  final int slotIndex;

  BackupRestoreResult({required this.restore, required this.slotIndex});

  @override
  String toString() => 'BackupRestoreResult(restore: $restore, slotIndex: $slotIndex)';
}

/// Shows a dialog asking user if they want to restore from an existing backup.
/// Returns BackupRestoreResult if user made a choice, null if dismissed.
Future<BackupRestoreResult?> showBackupRestoreDialog(
  BuildContext context,
  List<CloudBackupMetadata> backups,
) async {
  return showDialog<BackupRestoreResult>(
    context: context,
    barrierDismissible: false,
    builder: (context) => _BackupRestoreDialog(backups: backups),
  );
}

class _BackupRestoreDialog extends StatefulWidget {
  final List<CloudBackupMetadata> backups;

  const _BackupRestoreDialog({required this.backups});

  @override
  State<_BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends State<_BackupRestoreDialog> {
  int _selectedIndex = 0;
  bool _isLoading = false;

  String _formatDate(DateTime? date, BuildContext context) {
    if (date == null) return '-';
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat.yMMMd(locale).add_Hm();
    return formatter.format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_download, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.backupRestoreTitle)),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.backupRestoreMessage,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.backups.length,
                itemBuilder: (context, index) {
                  final backup = widget.backups[index];
                  final isSelected = index == _selectedIndex;

                  return Card(
                    elevation: isSelected ? 4 : 1,
                    color:
                        isSelected ? theme.colorScheme.primaryContainer : null,
                    child: ListTile(
                      leading: Radio<int>(
                        value: index,
                        groupValue: _selectedIndex,
                        onChanged: (value) {
                          setState(() => _selectedIndex = value ?? 0);
                        },
                      ),
                      title: Text(
                        index == 0
                            ? l10n.backupMostRecent
                            : '${l10n.backupSlot} ${index + 1}',
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(backup.updated, context),
                        style: theme.textTheme.bodySmall,
                      ),
                      onTap: () {
                        setState(() => _selectedIndex = index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop(
                    BackupRestoreResult(restore: false, slotIndex: 0),
                  );
                },
          child: Text(l10n.backupSkip),
        ),
        FilledButton.icon(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop(
                    BackupRestoreResult(
                        restore: true, slotIndex: _selectedIndex),
                  );
                },
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.restore),
          label: Text(l10n.backupRestore),
        ),
      ],
    );
  }
}
