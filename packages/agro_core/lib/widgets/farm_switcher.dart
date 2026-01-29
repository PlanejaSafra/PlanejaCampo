import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm.dart';
import '../models/farm_role.dart';
import '../services/farm_service.dart';

/// A dropdown widget for switching the active farm.
///
/// Displays the currently active farm with type icon and role chip.
/// If the user has multiple farms, shows a dropdown to switch.
/// If only one farm, shows a simple display (non-interactive).
///
/// Place this in the AgroDrawer header or as a standalone widget.
///
/// See CORE-90 for architecture.
class FarmSwitcher extends StatelessWidget {
  /// Callback when the active farm changes.
  final ValueChanged<Farm>? onFarmChanged;

  /// Callback to navigate to the farm management screen.
  final VoidCallback? onManageFarms;

  const FarmSwitcher({
    super.key,
    this.onFarmChanged,
    this.onManageFarms,
  });

  @override
  Widget build(BuildContext context) {
    final farms = FarmService.instance.getAccessibleFarms();
    final activeFarm = FarmService.instance.getActiveFarm();
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (farms.isEmpty || activeFarm == null) {
      return Text(
        l10n.farmSwitcherEmpty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.brightness == Brightness.dark
              ? Colors.white70
              : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
        ),
      );
    }

    // Single farm — simple display
    if (farms.length == 1) {
      return _FarmChip(farm: activeFarm, compact: true);
    }

    // Multiple farms — dropdown
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _showFarmSwitcherSheet(context, farms, activeFarm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: _FarmChip(farm: activeFarm, compact: true)),
          const SizedBox(width: 4),
          Icon(
            Icons.swap_horiz,
            size: 16,
            color: theme.brightness == Brightness.dark
                ? Colors.white70
                : theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          ),
        ],
      ),
    );
  }

  void _showFarmSwitcherSheet(
    BuildContext context,
    List<Farm> farms,
    Farm activeFarm,
  ) {
    final l10n = AgroLocalizations.of(context)!;
    final ownedFarms = farms.where((f) => f.isOwned).toList();
    final joinedFarms = farms.where((f) => f.isJoined).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.farmSwitcherTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            // Owned farms
            if (ownedFarms.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  l10n.farmSwitcherOwned,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              ...ownedFarms.map((farm) => _FarmTile(
                    farm: farm,
                    isActive: farm.id == activeFarm.id,
                    onTap: () => _selectFarm(context, farm),
                  )),
            ],
            // Joined farms
            if (joinedFarms.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Text(
                  l10n.farmSwitcherJoined,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              ...joinedFarms.map((farm) => _FarmTile(
                    farm: farm,
                    isActive: farm.id == activeFarm.id,
                    onTap: () => _selectFarm(context, farm),
                  )),
            ],
            const Divider(),
            // Manage farms
            if (onManageFarms != null)
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.farmSwitcherManage),
                onTap: () {
                  Navigator.pop(context);
                  onManageFarms!();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFarm(BuildContext context, Farm farm) async {
    Navigator.pop(context);
    await FarmService.instance.setActiveFarm(farm.id);
    onFarmChanged?.call(farm);
  }
}

/// Compact chip showing farm name + type icon + role badge.
class _FarmChip extends StatelessWidget {
  final Farm farm;
  final bool compact;

  const _FarmChip({required this.farm, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : theme.colorScheme.onPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          farm.type.icon,
          size: compact ? 14 : 18,
          color: textColor.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            farm.displayName,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (farm.isJoined) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: farm.effectiveRole.color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              farm.effectiveRole.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A list tile for selecting a farm in the bottom sheet.
class _FarmTile extends StatelessWidget {
  final Farm farm;
  final bool isActive;
  final VoidCallback onTap;

  const _FarmTile({
    required this.farm,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isActive
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          farm.type.icon,
          color: isActive
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      title: Text(
        farm.displayName,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: farm.isJoined
          ? Text(farm.effectiveRole.localizedName(l10n))
          : farm.isDefault
              ? Text(l10n.farmDefaultBadge)
              : null,
      trailing: isActive
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
      selected: isActive,
      onTap: isActive ? null : onTap,
    );
  }
}
