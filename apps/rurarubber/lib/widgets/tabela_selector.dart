import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/tabela_sangria.dart';
import '../services/tabela_service.dart';

/// A compact widget for selecting a tapping table during weighing.
///
/// Displays a horizontal row of [ChoiceChip]s with table numbers
/// (1, 2, 3, 4, etc.) plus a "Don't use tables" option.
///
/// Features:
/// - Highlights the suggested table (star icon)
/// - Shows warning icon on enforcada tables (tapped yesterday)
/// - Returns selected [TabelaSangria] or null via [onSelected] callback
///
/// Usage:
/// ```dart
/// TabelaSelector(
///   parceiroId: parceiro.id,
///   selectedTabelaId: _selectedTabelaId,
///   onSelected: (tabela) {
///     setState(() => _selectedTabelaId = tabela?.id);
///   },
/// )
/// ```
///
/// See RUBBER-23 for architecture.
class TabelaSelector extends StatelessWidget {
  /// The partner whose tables to show.
  final String parceiroId;

  /// The currently selected table ID (null means "no table selected").
  final String? selectedTabelaId;

  /// Callback when a table is selected or deselected.
  /// Passes null when "Don't use tables" is selected.
  final ValueChanged<TabelaSangria?> onSelected;

  const TabelaSelector({
    super.key,
    required this.parceiroId,
    this.selectedTabelaId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Consumer<TabelaService>(
      builder: (context, service, _) {
        final tabelas = service.getTabelasForParceiro(parceiroId);

        // Don't render anything if no tables are configured
        if (tabelas.isEmpty) return const SizedBox.shrink();

        final suggestedId = service.getSuggestedTable(parceiroId)?.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Table chips row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // "Don't use tables" chip
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(
                        l10n.naoUsarTabelas,
                        style: theme.textTheme.bodySmall,
                      ),
                      selected: selectedTabelaId == null,
                      onSelected: (_) => onSelected(null),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),

                  // Table number chips
                  ...tabelas.map((tabela) {
                    final isSelected = tabela.id == selectedTabelaId;
                    final isSuggested = tabela.id == suggestedId;
                    final isEnforcada = service.isEnforcada(tabela.id);

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Warning icon for enforcada
                            if (isEnforcada) ...[
                              Icon(
                                Icons.warning_amber_rounded,
                                size: 14,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.error,
                              ),
                              const SizedBox(width: 4),
                            ],

                            // Table number
                            Text(
                              '${tabela.numero}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSuggested
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),

                            // Star icon for suggested
                            if (isSuggested && !isEnforcada) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star_rounded,
                                size: 14,
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (_) => onSelected(tabela),
                        visualDensity: VisualDensity.compact,
                        side: isEnforcada && !isSelected
                            ? BorderSide(
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.5,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Enforcada warning message
            if (selectedTabelaId != null &&
                service.isEnforcada(selectedTabelaId!)) ...[
              const SizedBox(height: 4),
              _buildEnforcadaWarning(context, l10n, theme, service),
            ],
          ],
        );
      },
    );
  }

  /// Build the enforcada warning message below the chips.
  Widget _buildEnforcadaWarning(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    TabelaService service,
  ) {
    final tabela = service.getTabelaById(selectedTabelaId!);
    if (tabela == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.alertaEnforcada(tabela.numero),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
