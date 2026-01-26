import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/despesa.dart';
import '../services/despesa_service.dart';
import '../services/entrega_service.dart';
import '../widgets/rubber_drawer.dart';

/// Break-even cost analysis dashboard (RUBBER-20).
///
/// Shows:
/// - Cost per Kg (total expenses / total production)
/// - Profit margin % (average sale price - cost per kg) / average sale price
/// - Average sale price (total value / total weight)
/// - Category breakdown with colored bars
/// - Add expense FAB with bottom sheet form
/// - Empty state when no data
class BreakEvenScreen extends StatefulWidget {
  const BreakEvenScreen({super.key});

  @override
  State<BreakEvenScreen> createState() => _BreakEvenScreenState();
}

class _BreakEvenScreenState extends State<BreakEvenScreen> {
  Safra? _activeSafra;

  @override
  void initState() {
    super.initState();
    _ensureSafra();
  }

  Future<void> _ensureSafra() async {
    final farmId = FarmService.instance.defaultFarmId;
    if (farmId == null || farmId.isEmpty) return;
    try {
      final safra =
          await SafraService.instance.ensureAtivaSafra(farmId: farmId);
      if (mounted) {
        setState(() {
          _activeSafra = safra;
        });
      }
    } catch (e) {
      debugPrint('Error ensuring safra: $e');
    }
  }

  void _onSafraChanged(Safra safra) {
    setState(() {
      _activeSafra = safra;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final farmId = FarmService.instance.defaultFarmId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.breakEvenTitle),
        actions: [
          if (farmId.isNotEmpty)
            SafraChip(
              farmId: farmId,
              onSafraChanged: _onSafraChanged,
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: _activeSafra == null
          ? Center(
              child: Text(l10n.breakEvenSemDados),
            )
          : Consumer2<DespesaService, EntregaService>(
              builder: (context, despesaService, entregaService, child) {
                return _buildDashboard(
                  context,
                  l10n,
                  despesaService,
                  entregaService,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDespesaSheet(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.despesaAddButton),
      ),
      bottomNavigationBar: const AgroBannerWidget(
        adUnitId: 'ca-app-pub-3109803084293083/5660030835',
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    BorrachaLocalizations l10n,
    DespesaService despesaService,
    EntregaService entregaService,
  ) {
    final safra = _activeSafra!;
    final theme = Theme.of(context);
    final nfCurrency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final nfDecimal = NumberFormat('#,##0.00', 'pt_BR');
    final nfWeight = NumberFormat('#,##0.0', 'pt_BR');

    final totalDespesas = despesaService.totalPorSafra(safra);
    final totalPesoKg = entregaService.totalPesoSafra(safra);
    final totalValor = entregaService.totalValorSafra(safra);

    final custoKg = totalPesoKg > 0 ? totalDespesas / totalPesoKg : 0.0;
    final precoMedioVenda = totalPesoKg > 0 ? totalValor / totalPesoKg : 0.0;
    final margemLucro = precoMedioVenda > 0
        ? ((precoMedioVenda - custoKg) / precoMedioVenda) * 100
        : 0.0;

    final hasData = totalDespesas > 0 || totalPesoKg > 0;

    if (!hasData) {
      return _buildEmptyState(context, l10n, theme);
    }

    final categoriaBreakdown = despesaService.totalPorCategoria(safra);
    final despesasSafra = despesaService.despesasPorSafra(safra);

    return RefreshIndicator(
      onRefresh: () async {
        await _ensureSafra();
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── KPI Cards ──
            _buildKpiCards(
              context,
              l10n,
              theme,
              custoKg: custoKg,
              margemLucro: margemLucro,
              precoMedioVenda: precoMedioVenda,
              nfCurrency: nfCurrency,
              nfDecimal: nfDecimal,
            ),
            const SizedBox(height: 24),

            // ── Cost Trend Warning ──
            _buildCostTrendWarning(
              context,
              l10n,
              theme,
              despesaService: despesaService,
              safra: safra,
            ),

            // ── Totals Summary ──
            _buildTotalsSummary(
              context,
              l10n,
              theme,
              totalDespesas: totalDespesas,
              totalPesoKg: totalPesoKg,
              nfCurrency: nfCurrency,
              nfWeight: nfWeight,
            ),
            const SizedBox(height: 24),

            // ── Category Breakdown ──
            if (categoriaBreakdown.isNotEmpty) ...[
              _buildCategoryBreakdown(
                context,
                l10n,
                theme,
                categoriaBreakdown: categoriaBreakdown,
                totalDespesas: totalDespesas,
                nfCurrency: nfCurrency,
              ),
              const SizedBox(height: 24),
            ],

            // ── Recent Expenses List ──
            if (despesasSafra.isNotEmpty) ...[
              _buildRecentExpenses(
                context,
                l10n,
                theme,
                despesas: despesasSafra,
                nfCurrency: nfCurrency,
              ),
            ],

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // KPI Cards
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildKpiCards(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme, {
    required double custoKg,
    required double margemLucro,
    required double precoMedioVenda,
    required NumberFormat nfCurrency,
    required NumberFormat nfDecimal,
  }) {
    final margemColor = margemLucro > 0 ? Colors.green : Colors.red;

    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: l10n.custoKg,
            value: nfCurrency.format(custoKg),
            icon: Icons.trending_down,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            label: l10n.margemLucro,
            value: '${nfDecimal.format(margemLucro)}%',
            icon: margemLucro >= 0
                ? Icons.trending_up
                : Icons.trending_down,
            color: margemColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _KpiCard(
            label: l10n.precoMedioVenda,
            value: nfCurrency.format(precoMedioVenda),
            icon: Icons.sell,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Cost Trend Warning
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCostTrendWarning(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme, {
    required DespesaService despesaService,
    required Safra safra,
  }) {
    final monthlyData = despesaService.totalMensalSafra(safra);
    if (monthlyData.length < 2) return const SizedBox.shrink();

    final currentMonth = monthlyData.last.value;
    final previousMonth = monthlyData[monthlyData.length - 2].value;

    if (previousMonth <= 0) return const SizedBox.shrink();

    final percentIncrease =
        ((currentMonth - previousMonth) / previousMonth) * 100;

    if (percentIncrease <= 20) return const SizedBox.shrink();

    final percentStr = percentIncrease.toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Card(
        color: Colors.amber.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.amber.shade300),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.breakEvenAlerta(percentStr),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Totals Summary
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTotalsSummary(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme, {
    required double totalDespesas,
    required double totalPesoKg,
    required NumberFormat nfCurrency,
    required NumberFormat nfWeight,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.receipt_long,
                      color: Colors.red.shade400, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    nfCurrency.format(totalDespesas),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.totalDespesas,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: theme.dividerColor,
            ),
            Expanded(
              child: Column(
                children: [
                  Icon(Icons.scale, color: Colors.green.shade400, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '${nfWeight.format(totalPesoKg)} kg',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.totalProducao,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Category Breakdown
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategoryBreakdown(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme, {
    required Map<CategoriaDespesa, double> categoriaBreakdown,
    required double totalDespesas,
    required NumberFormat nfCurrency,
  }) {
    final sorted = categoriaBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.despesaSafraTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...sorted.map((entry) {
              final pct = totalDespesas > 0
                  ? (entry.value / totalDespesas)
                  : 0.0;
              final color = _getCategoryColor(entry.key);
              final label = _getCategoryLabel(l10n, entry.key);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(label,
                                style: theme.textTheme.bodyMedium),
                          ],
                        ),
                        Text(
                          '${nfCurrency.format(entry.value)} (${(pct * 100).toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Recent Expenses
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildRecentExpenses(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme, {
    required List<Despesa> despesas,
    required NumberFormat nfCurrency,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.despesaSafraTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...despesas.map((despesa) {
          final color = _getCategoryColor(despesa.categoria);
          final label = _getCategoryLabel(l10n, despesa.categoria);

          return Dismissible(
            key: Key(despesa.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (_) async {
              return await _confirmDelete(context, l10n);
            },
            onDismissed: (_) {
              DespesaService.instance.deleteDespesa(despesa.id);
            },
            child: Card(
              margin: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                onTap: () => _showEditDespesaSheet(context, despesa),
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.2),
                  child: Icon(
                    _getCategoryIcon(despesa.categoria),
                    color: color,
                    size: 20,
                  ),
                ),
                title: Text(label),
                subtitle: Text(
                  despesa.descricao != null && despesa.descricao!.isNotEmpty
                      ? '${dateFormat.format(despesa.data)} - ${despesa.descricao}'
                      : dateFormat.format(despesa.data),
                ),
                trailing: Text(
                  nfCurrency.format(despesa.valor),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Empty State
  // ═══════════════════════════════════════════════════════════════════════════

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
              Icons.analytics_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.breakEvenSemDados,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showAddDespesaSheet(context),
              icon: const Icon(Icons.add),
              label: Text(l10n.despesaAddButton),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Add Expense Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════════════

  void _showAddDespesaSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: const _AddDespesaForm(),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Edit Expense Bottom Sheet
  // ═══════════════════════════════════════════════════════════════════════════

  void _showEditDespesaSheet(BuildContext context, Despesa despesa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: _EditDespesaForm(despesa: despesa),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Confirm Delete
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> _confirmDelete(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.despesaDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
                MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
                MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════════════════════════════════════════

  static Color _getCategoryColor(CategoriaDespesa cat) {
    switch (cat) {
      case CategoriaDespesa.maoDeObra:
        return Colors.blue;
      case CategoriaDespesa.adubo:
        return Colors.green;
      case CategoriaDespesa.defensivos:
        return Colors.purple;
      case CategoriaDespesa.combustivel:
        return Colors.orange;
      case CategoriaDespesa.manutencao:
        return Colors.grey;
      case CategoriaDespesa.outros:
        return Colors.brown;
    }
  }

  static IconData _getCategoryIcon(CategoriaDespesa cat) {
    switch (cat) {
      case CategoriaDespesa.maoDeObra:
        return Icons.people;
      case CategoriaDespesa.adubo:
        return Icons.eco;
      case CategoriaDespesa.defensivos:
        return Icons.shield;
      case CategoriaDespesa.combustivel:
        return Icons.local_gas_station;
      case CategoriaDespesa.manutencao:
        return Icons.build;
      case CategoriaDespesa.outros:
        return Icons.more_horiz;
    }
  }

  static String _getCategoryLabel(
    BorrachaLocalizations l10n,
    CategoriaDespesa cat,
  ) {
    switch (cat) {
      case CategoriaDespesa.maoDeObra:
        return l10n.despesaCatMaoDeObra;
      case CategoriaDespesa.adubo:
        return l10n.despesaCatAdubo;
      case CategoriaDespesa.defensivos:
        return l10n.despesaCatDefensivos;
      case CategoriaDespesa.combustivel:
        return l10n.despesaCatCombustivel;
      case CategoriaDespesa.manutencao:
        return l10n.despesaCatManutencao;
      case CategoriaDespesa.outros:
        return l10n.despesaCatOutros;
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Add Expense Form (StatefulWidget inside BottomSheet)
// ═════════════════════════════════════════════════════════════════════════════

class _AddDespesaForm extends StatefulWidget {
  const _AddDespesaForm();

  @override
  State<_AddDespesaForm> createState() => _AddDespesaFormState();
}

class _AddDespesaFormState extends State<_AddDespesaForm> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _descricaoController = TextEditingController();
  CategoriaDespesa _selectedCategoria = CategoriaDespesa.maoDeObra;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    if (valor == null || valor <= 0) return;

    await DespesaService.instance.adicionarDespesa(
      valor: valor,
      categoria: _selectedCategoria,
      data: _selectedDate,
      descricao: _descricaoController.text.isNotEmpty
          ? _descricaoController.text
          : null,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                l10n.despesaAddButton,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Valor field
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.despesaValor,
                  prefixText: 'R\$ ',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.despesaValor;
                  }
                  final parsed =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return l10n.despesaValor;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Categoria dropdown
              DropdownButtonFormField<CategoriaDespesa>(
                value: _selectedCategoria,
                decoration: InputDecoration(
                  labelText: l10n.despesaCategoria,
                  border: const OutlineInputBorder(),
                ),
                items: CategoriaDespesa.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          _BreakEvenScreenState._getCategoryIcon(cat),
                          color:
                              _BreakEvenScreenState._getCategoryColor(cat),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_BreakEvenScreenState._getCategoryLabel(
                            l10n, cat)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategoria = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.despesaData,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),

              // Description field (optional)
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.despesaSafraTitle} (${MaterialLocalizations.of(context).modalBarrierDismissLabel})',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Save button
              FilledButton(
                onPressed: _save,
                child: Text(l10n.despesaSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Edit Expense Form (StatefulWidget inside BottomSheet)
// ═════════════════════════════════════════════════════════════════════════════

class _EditDespesaForm extends StatefulWidget {
  final Despesa despesa;

  const _EditDespesaForm({required this.despesa});

  @override
  State<_EditDespesaForm> createState() => _EditDespesaFormState();
}

class _EditDespesaFormState extends State<_EditDespesaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late final TextEditingController _descricaoController;
  late CategoriaDespesa _selectedCategoria;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(
      text: widget.despesa.valor.toStringAsFixed(2).replaceAll('.', ','),
    );
    _descricaoController = TextEditingController(
      text: widget.despesa.descricao ?? '',
    );
    _selectedCategoria = widget.despesa.categoria;
    _selectedDate = widget.despesa.data;
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    if (valor == null || valor <= 0) return;

    await DespesaService.instance.updateDespesa(
      id: widget.despesa.id,
      valor: valor,
      categoria: _selectedCategoria,
      data: _selectedDate,
      descricao: _descricaoController.text.isNotEmpty
          ? _descricaoController.text
          : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(BorrachaLocalizations.of(context)!.despesaUpdated),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                l10n.despesaEditTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Valor field
              TextFormField(
                controller: _valorController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l10n.despesaValor,
                  prefixText: 'R\$ ',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.despesaValor;
                  }
                  final parsed =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (parsed == null || parsed <= 0) {
                    return l10n.despesaValor;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Categoria dropdown
              DropdownButtonFormField<CategoriaDespesa>(
                value: _selectedCategoria,
                decoration: InputDecoration(
                  labelText: l10n.despesaCategoria,
                  border: const OutlineInputBorder(),
                ),
                items: CategoriaDespesa.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      children: [
                        Icon(
                          _BreakEvenScreenState._getCategoryIcon(cat),
                          color:
                              _BreakEvenScreenState._getCategoryColor(cat),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(_BreakEvenScreenState._getCategoryLabel(
                            l10n, cat)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategoria = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),

              // Date picker
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.despesaData,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.calendar_today),
                  ),
                  child: Text(dateFormat.format(_selectedDate)),
                ),
              ),
              const SizedBox(height: 12),

              // Description field (optional)
              TextFormField(
                controller: _descricaoController,
                decoration: InputDecoration(
                  labelText:
                      '${l10n.despesaSafraTitle} (${MaterialLocalizations.of(context).modalBarrierDismissLabel})',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Save button
              FilledButton(
                onPressed: _save,
                child: Text(l10n.despesaSaveButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KPI Card Widget
// ═════════════════════════════════════════════════════════════════════════════

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
