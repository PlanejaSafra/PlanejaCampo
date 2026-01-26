import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/entrega.dart';
import '../services/analytics_service.dart';
import '../services/entrega_service.dart';
import '../services/parceiro_service.dart';
import '../widgets/period_selector.dart';
import '../widgets/production_bar_chart.dart';

/// Partner "Raio-X" (X-Ray) analytics detail screen (RUBBER-21.4).
///
/// Displays production analytics for a single partner within the
/// active safra, including:
/// - Summary card with season total and biweekly average
/// - Above/below farm average status chip
/// - Period selector (biweekly, monthly, season)
/// - Production bar chart with optional farm average phantom line
/// - Button to view financial statement
class ParceiroDetailScreen extends StatefulWidget {
  const ParceiroDetailScreen({
    super.key,
    required this.parceiroId,
  });

  final String parceiroId;

  @override
  State<ParceiroDetailScreen> createState() => _ParceiroDetailScreenState();
}

class _ParceiroDetailScreenState extends State<ParceiroDetailScreen> {
  Safra? _activeSafra;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.biweekly;

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

    return Consumer2<EntregaService, ParceiroService>(
      builder: (context, entregaService, parceiroService, _) {
        final parceiro = parceiroService.getParceiro(widget.parceiroId);
        final parceiroName = parceiro?.nome ?? l10n.unknownPartner;

        return Scaffold(
          appBar: AppBar(
            title: Text(parceiroName),
            actions: [
              if (farmId.isNotEmpty)
                SafraChip(
                  farmId: farmId,
                  onSafraChanged: _onSafraChanged,
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: _activeSafra == null
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(context, l10n, entregaService),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    BorrachaLocalizations l10n,
    EntregaService entregaService,
  ) {
    final safra = _activeSafra!;
    final entregas = entregaService.entregas;

    // Compute analytics data
    final seasonTotal = AnalyticsService.getPartnerSeasonTotal(
      widget.parceiroId,
      safra,
      entregas,
    );

    final biweeklyData = AnalyticsService.getBiweeklyData(
      widget.parceiroId,
      safra,
      entregas,
    );

    final biweeklyAvg = biweeklyData.isNotEmpty
        ? biweeklyData.values.reduce((a, b) => a + b) / biweeklyData.length
        : 0.0;

    // Farm average per partner per period (for comparison)
    final activePartners =
        AnalyticsService.getActivePartnerCount(safra, entregas);
    final daysWithData = AnalyticsService.getDaysWithData(safra, entregas);
    final showPhantom =
        AnalyticsService.shouldShowPhantomLine(activePartners, daysWithData);

    // Get data for the selected period
    final chartData = _getChartData(entregas, safra);
    final periodCount = chartData.length;

    final farmAvgPerPartner = AnalyticsService.getFarmAveragePerPartner(
      safra,
      entregas,
      periodCount > 0 ? periodCount : 1,
    );

    // Above or below average
    final isAboveAverage = biweeklyAvg >= farmAvgPerPartner;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary Card ──
          _SummaryCard(
            seasonTotal: seasonTotal,
            biweeklyAvg: biweeklyAvg,
            isAboveAverage: isAboveAverage,
            showComparison: showPhantom,
            l10n: l10n,
          ),

          const SizedBox(height: 24),

          // ── Section: Production ──
          Text(
            l10n.producaoLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // ── Period Selector ──
          Center(
            child: PeriodSelector(
              selectedPeriod: _selectedPeriod,
              onChanged: (period) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── Bar Chart ──
          ProductionBarChart(
            data: chartData,
            phantomLineValue: showPhantom ? farmAvgPerPartner : null,
          ),

          const SizedBox(height: 32),

          // ── Financial Statement Button ──
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed('/contas-pagar');
            },
            icon: const Icon(Icons.receipt_long),
            label: Text(l10n.verExtratoFinanceiro),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Returns the chart data map based on the selected period.
  Map<String, double> _getChartData(
    List<Entrega> entregas,
    Safra safra,
  ) {
    switch (_selectedPeriod) {
      case AnalyticsPeriod.biweekly:
        return AnalyticsService.getBiweeklyData(
          widget.parceiroId,
          safra,
          entregas,
        );
      case AnalyticsPeriod.monthly:
        return AnalyticsService.getMonthlyData(
          widget.parceiroId,
          safra,
          entregas,
        );
      case AnalyticsPeriod.season:
        final farmId = FarmService.instance.defaultFarmId ?? '';
        final allSafras = SafraService.instance.getAllSafras(farmId);
        return AnalyticsService.getSeasonData(
          widget.parceiroId,
          allSafras,
          entregas,
        );
    }
  }
}

/// Summary card showing season total, biweekly average, and status chip.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.seasonTotal,
    required this.biweeklyAvg,
    required this.isAboveAverage,
    required this.showComparison,
    required this.l10n,
  });

  final double seasonTotal;
  final double biweeklyAvg;
  final bool isAboveAverage;
  final bool showComparison;
  final BorrachaLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              l10n.raioXParceiro,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),

            // Stats row
            Row(
              children: [
                // Season Total
                Expanded(
                  child: _StatColumn(
                    label: l10n.totalSafra,
                    value: '${seasonTotal.toStringAsFixed(1)} kg',
                    theme: theme,
                  ),
                ),
                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: theme.colorScheme.outlineVariant,
                ),
                // Biweekly Average
                Expanded(
                  child: _StatColumn(
                    label: l10n.mediaQuinzenal,
                    value: '${biweeklyAvg.toStringAsFixed(1)} kg',
                    theme: theme,
                  ),
                ),
              ],
            ),

            // Status chip
            if (showComparison) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Chip(
                  avatar: Icon(
                    isAboveAverage
                        ? Icons.trending_up
                        : Icons.trending_down,
                    size: 18,
                    color: isAboveAverage
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                  label: Text(
                    isAboveAverage
                        ? l10n.acimaDaMedia
                        : l10n.abaixoDaMedia,
                    style: TextStyle(
                      fontSize: 12,
                      color: isAboveAverage
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                  backgroundColor: isAboveAverage
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small stat column (label + value).
class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
