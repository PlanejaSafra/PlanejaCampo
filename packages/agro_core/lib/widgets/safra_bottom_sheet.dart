import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/safra.dart';
import '../services/safra_service.dart';

/// Bottom sheet for viewing and managing crop seasons (safras).
///
/// Shows:
/// - Active safra at the top with a "close season" action
/// - Previous (closed) safras listed below
///
/// See CORE-76.4 for close-safra specifications.
class SafraBottomSheet extends StatefulWidget {
  /// Farm ID to display safras for.
  final String farmId;

  /// Callback when the user selects a safra (active or previous).
  final ValueChanged<Safra>? onSafraChanged;

  const SafraBottomSheet({
    super.key,
    required this.farmId,
    this.onSafraChanged,
  });

  @override
  State<SafraBottomSheet> createState() => _SafraBottomSheetState();
}

class _SafraBottomSheetState extends State<SafraBottomSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final safraService = SafraService.instance;
    final ativa = safraService.getAtiva(widget.farmId);
    final anteriores = safraService.getSafrasAnteriores(widget.farmId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Text(
              l10n.safraGlobal,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Active safra section
            if (ativa != null) ...[
              Text(
                l10n.safraAtiva,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              _SafraTile(
                safra: ativa,
                isActive: true,
                onTap: () {
                  widget.onSafraChanged?.call(ativa);
                  Navigator.of(context).pop();
                },
                trailing: TextButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined, size: 18),
                  label: Text(l10n.encerrarSafra),
                  onPressed: () => _confirmEncerrar(context, ativa),
                ),
              ),
            ],

            // No safra state
            if (ativa == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    l10n.safraNenhuma,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ),

            // Previous safras section
            if (anteriores.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.safraAnterior,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              ...anteriores.map(
                (safra) => _SafraTile(
                  safra: safra,
                  isActive: false,
                  onTap: () {
                    widget.onSafraChanged?.call(safra);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmEncerrar(BuildContext context, Safra safra) {
    final l10n = AgroLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.encerrarSafra),
        content: Text(l10n.safraEncerrarConfirm(safra.nome)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final newSafra =
                    await SafraService.instance.encerrarSafra(safra.id);
                if (context.mounted) {
                  widget.onSafraChanged?.call(newSafra);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text(l10n.novaSafraCriada(newSafra.nome)),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${l10n.errorPrefix}: $e'),
                    ),
                  );
                }
              }
              if (mounted) setState(() {});
            },
            child: Text(l10n.encerrarSafra),
          ),
        ],
      ),
    );
  }
}

/// Internal tile widget for displaying a single safra entry.
class _SafraTile extends StatelessWidget {
  final Safra safra;
  final bool isActive;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SafraTile({
    required this.safra,
    required this.isActive,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final startFormatted = _formatDate(safra.dataInicio);
    final endFormatted =
        safra.dataFim != null ? _formatDate(safra.dataFim!) : '...';

    return Card(
      elevation: isActive ? 2 : 0,
      color: isActive
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.agriculture : Icons.history,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safra.nome,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$startFormatted → $endFormatted',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
