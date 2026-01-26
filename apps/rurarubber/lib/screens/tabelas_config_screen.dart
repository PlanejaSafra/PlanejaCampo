import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/tabela_sangria.dart';
import '../services/tabela_service.dart';

/// Screen to configure tapping tables (D3/D4 system) for a specific partner.
///
/// Features:
/// - List of current tables with numero, arvoresEstimadas, lastTappedDate
/// - "Add Tables" bottom sheet with table count selector (3, 4, 5)
/// - Optional trees-per-table input
/// - Delete all tables button
/// - Simple productivity comparison bar
///
/// See RUBBER-23 for architecture.
class TabelasConfigScreen extends StatefulWidget {
  /// The partner ID to configure tables for.
  final String parceiroId;

  /// Optional partner name for the AppBar title.
  final String? parceiroNome;

  const TabelasConfigScreen({
    super.key,
    required this.parceiroId,
    this.parceiroNome,
  });

  @override
  State<TabelasConfigScreen> createState() => _TabelasConfigScreenState();
}

class _TabelasConfigScreenState extends State<TabelasConfigScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabelasConfigTitle),
      ),
      body: Consumer<TabelaService>(
        builder: (context, service, _) {
          final tabelas = service.getTabelasForParceiro(widget.parceiroId);

          if (tabelas.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          return _buildTableList(context, l10n, theme, tabelas, service);
        },
      ),
      floatingActionButton: Consumer<TabelaService>(
        builder: (context, service, _) {
          final hasTabelas = service.hasTabelas(widget.parceiroId);
          if (hasTabelas) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () => _showAddTablesSheet(context, l10n),
            icon: const Icon(Icons.add),
            label: Text(l10n.quantasTabelas),
          );
        },
      ),
    );
  }

  /// Build the empty state when no tables are configured.
  Widget _buildEmptyState(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.grid_view_rounded,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              l10n.tabelasEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.usarTabelas,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showAddTablesSheet(context, l10n),
              icon: const Icon(Icons.add),
              label: Text(l10n.quantasTabelas),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the list of configured tables.
  Widget _buildTableList(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    List<TabelaSangria> tabelas,
    TabelaService service,
  ) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        // Table cards
        ...tabelas.map(
          (tabela) => _buildTableCard(context, l10n, theme, tabela, service),
        ),

        const SizedBox(height: 24),

        // Productivity section
        _buildProductivitySection(context, l10n, theme, tabelas, service),

        const SizedBox(height: 24),

        // Delete all button
        _buildDeleteAllButton(context, l10n, theme, service),
      ],
    );
  }

  /// Build a card for a single table.
  Widget _buildTableCard(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    TabelaSangria tabela,
    TabelaService service,
  ) {
    final isEnforcada = service.isEnforcada(tabela.id);
    final isSuggested =
        service.getSuggestedTable(widget.parceiroId)?.id == tabela.id;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Table number chip
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSuggested
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${tabela.numero}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isSuggested
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Table name and info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.tabelaSelecionada(tabela.numero),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (tabela.arvoresEstimadas != null)
                        Text(
                          '${tabela.arvoresEstimadas} ${l10n.arvoresPorTabela}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                // Warning icon for enforcada
                if (isEnforcada)
                  Tooltip(
                    message: l10n.alertaEnforcada(tabela.numero),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),

                // Suggested indicator
                if (isSuggested && !isEnforcada)
                  Icon(
                    Icons.star_rounded,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),

            // Last tapped date
            if (tabela.lastTappedDate != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatDate(tabela.lastTappedDate!),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],

            // Editable trees field
            const SizedBox(height: 8),
            _buildTreesInput(context, l10n, theme, tabela, service),
          ],
        ),
      ),
    );
  }

  /// Build the trees-per-table input field.
  Widget _buildTreesInput(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    TabelaSangria tabela,
    TabelaService service,
  ) {
    final controller = TextEditingController(
      text: tabela.arvoresEstimadas?.toString() ?? '',
    );

    return Row(
      children: [
        Icon(
          Icons.park_outlined,
          size: 18,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.arvoresPorTabela,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onFieldSubmitted: (value) {
              final parsed = int.tryParse(value);
              service.updateArvores(tabela.id, parsed);
            },
          ),
        ),
      ],
    );
  }

  /// Build the productivity comparison section.
  Widget _buildProductivitySection(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    List<TabelaSangria> tabelas,
    TabelaService service,
  ) {
    // Get productivity data
    final farmId = FarmService.instance.defaultFarmId ?? '';
    final activeSafra = SafraService.instance.getAtiva(farmId);
    if (activeSafra == null) return const SizedBox.shrink();

    final productivity =
        service.getProductivityByTable(widget.parceiroId, activeSafra);
    final maxKg =
        productivity.values.fold<double>(0, (max, v) => v > max ? v : max);

    if (maxKg <= 0) return const SizedBox.shrink();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.produtividadeTabela,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ...productivity.entries.map((entry) {
              final ratio = maxKg > 0 ? entry.value / maxKg : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        l10n.tabelaSelecionada(entry.key),
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 16,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${entry.value.toStringAsFixed(1)} kg',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              );
            }),

            // g/arvore section
            if (tabelas.any((t) => t.arvoresEstimadas != null)) ...[
              const Divider(height: 24),
              ...tabelas
                  .where((t) => t.arvoresEstimadas != null)
                  .map((tabela) {
                final kg = productivity[tabela.numero] ?? 0.0;
                final gPerTree =
                    service.calcGramasArvore(kg, tabela.arvoresEstimadas!);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.tabelaSelecionada(tabela.numero),
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        '${gPerTree.toStringAsFixed(1)} ${l10n.gramasArvore}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  /// Build the delete all tables button.
  Widget _buildDeleteAllButton(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    TabelaService service,
  ) {
    return Center(
      child: TextButton.icon(
        onPressed: () => _confirmDeleteAll(context, l10n, service),
        icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
        label: Text(
          l10n.naoUsarTabelas,
          style: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }

  /// Show the bottom sheet to add tables.
  void _showAddTablesSheet(BuildContext context, BorrachaLocalizations l10n) {
    int selectedCount = 4;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (innerContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(innerContext).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.quantasTabelas,
                    style: Theme.of(innerContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),

                  // Count selector chips
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [3, 4, 5].map((count) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Text('$count'),
                          selected: selectedCount == count,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedCount = count);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(innerContext);
                        _createTables(selectedCount);
                      },
                      child: Text(l10n.salvarButton),
                    ),
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Create tables for the partner.
  Future<void> _createTables(int count) async {
    final service = context.read<TabelaService>();
    await service.criarTabelas(widget.parceiroId, count);
  }

  /// Confirm and delete all tables for the partner.
  Future<void> _confirmDeleteAll(
    BuildContext context,
    BorrachaLocalizations l10n,
    TabelaService service,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.naoUsarTabelas),
        content: Text(l10n.tabelasEmpty),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.parceiroDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              l10n.parceiroDeleteConfirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.deleteTabelas(widget.parceiroId);
    }
  }

  /// Format a date for display.
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}
