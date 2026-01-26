import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/safra.dart';
import '../services/safra_service.dart';
import 'safra_bottom_sheet.dart';

/// Compact chip widget showing the active crop season (e.g., "25/26").
///
/// Tapping the chip opens a [SafraBottomSheet] for viewing and
/// switching between seasons.
///
/// Usage in a screen header / AppBar:
/// ```dart
/// AppBar(
///   title: Text('My App'),
///   actions: [
///     SafraChip(farmId: currentFarmId),
///   ],
/// )
/// ```
///
/// See CORE-76.3 for specifications.
class SafraChip extends StatelessWidget {
  /// Farm ID to display the active safra for.
  final String farmId;

  /// Callback when the user selects a different safra.
  final ValueChanged<Safra>? onSafraChanged;

  /// Whether the chip is interactive (opens bottom sheet on tap).
  final bool interactive;

  const SafraChip({
    super.key,
    required this.farmId,
    this.onSafraChanged,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final safra = SafraService.instance.getAtiva(farmId);
    final label = safra?.shortLabel ?? '--/--';

    return ActionChip(
      avatar: const Icon(Icons.calendar_today, size: 16),
      label: Text(label),
      tooltip: safra?.nome ?? l10n.safraGlobal,
      onPressed: interactive ? () => _showBottomSheet(context) : null,
      backgroundColor:
          Theme.of(context).colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      labelStyle: Theme.of(context).textTheme.labelMedium,
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafraBottomSheet(
        farmId: farmId,
        onSafraChanged: onSafraChanged,
      ),
    );
  }
}
