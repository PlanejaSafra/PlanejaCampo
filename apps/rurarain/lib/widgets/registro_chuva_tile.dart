import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/share_service.dart';

/// Tile widget for displaying a single rainfall record.
class RegistroChuvasTile extends StatelessWidget {
  final RegistroChuva registro;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showTalhaoName;

  const RegistroChuvasTile({
    super.key,
    required this.registro,
    this.onTap,
    this.onDelete,
    this.showTalhaoName = true,
  });

  /// Returns an icon based on rainfall intensity.
  IconData _getIntensityIcon() {
    if (registro.milimetros < 10) {
      return Icons.water_drop_outlined; // Leve
    } else if (registro.milimetros < 30) {
      return Icons.water_drop; // Moderada
    } else {
      return Icons.thunderstorm; // Forte
    }
  }

  /// Returns a color based on rainfall intensity.
  Color _getIntensityColor(BuildContext context) {
    final theme = Theme.of(context);
    if (registro.milimetros < 10) {
      return theme.colorScheme.primary.withValues(alpha: 0.6);
    } else if (registro.milimetros < 30) {
      return theme.colorScheme.primary;
    } else {
      return theme.colorScheme.error;
    }
  }

  /// Returns a formatted date string.
  String _formatDate(BuildContext context, DateTime date) {
    final l10n = AgroLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final recordDate = DateTime(date.year, date.month, date.day);

    if (recordDate == today) {
      return l10n.chuvaHoje;
    } else if (recordDate == yesterday) {
      return l10n.chuvaOntem;
    } else {
      final locale = Localizations.localeOf(context).toString();
      return DateFormat.yMMMd(locale).format(date);
    }
  }

  /// Returns a formatted number respecting locale (comma or dot).
  String _formatNumber(BuildContext context, double value) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat('#0.0', locale).format(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return Dismissible(
      key: Key('registro_${registro.id}'),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(
          Icons.delete,
          color: theme.colorScheme.onError,
        ),
      ),
      confirmDismiss: (direction) async {
        if (onDelete == null) return false;
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.chuvaConfirmarExclusaoTitle),
            content: Text(l10n.chuvaConfirmarExclusaoMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.chuvaBotaoCancelar),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                ),
                child: Text(l10n.chuvaBotaoExcluir),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Intensity icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getIntensityColor(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIntensityIcon(),
                    color: _getIntensityColor(context),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Date and observation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(context, registro.data),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // CORE-34.6: Only show talhão name if property has > 1 talhão
                      if (showTalhaoName && registro.talhaoId != null)
                        Builder(
                          builder: (context) {
                            final talhao =
                                TalhaoService().getById(registro.talhaoId!);
                            if (talhao == null) return const SizedBox.shrink();

                            // Only show if property has more than one talhão
                            final talhaoCount = TalhaoService()
                                .countByProperty(talhao.propertyId);
                            if (talhaoCount <= 1)
                              return const SizedBox.shrink();

                            return Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.landscape,
                                    size: 14,
                                    color: theme.colorScheme.secondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    talhao.nome,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      if (registro.observacao != null &&
                          registro.observacao!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            registro.observacao!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Millimeters value (prominent)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatNumber(context, registro.milimetros),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getIntensityColor(context),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.chuvaMm,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Share Button
                        InkWell(
                          onTap: () async {
                            final property = PropertyService()
                                .getPropertyById(registro.propertyId);
                            if (context.mounted && property != null) {
                              await ShareService().shareRainRecord(
                                context,
                                registro: registro,
                                propertyName: property.name,
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.share_outlined,
                              size: 16,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
