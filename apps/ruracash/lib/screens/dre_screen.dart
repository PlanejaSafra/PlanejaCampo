import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../services/lancamento_service.dart';
import '../services/centro_custo_service.dart';
import '../widgets/cash_drawer.dart';

/// DRE (Income Statement) screen - Farm-wide financial overview.
class DreScreen extends StatefulWidget {
  const DreScreen({super.key});

  @override
  State<DreScreen> createState() => _DreScreenState();
}

class _DreScreenState extends State<DreScreen> {
  int _selectedPeriod = 0; // 0=Month, 1=Quarter, 2=Season, 3=Year

  DateTime get _periodStart {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // Month
        return DateTime(now.year, now.month, 1);
      case 1: // Quarter
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
        return DateTime(now.year, quarterMonth, 1);
      case 2: // Season (Sep-Aug)
        if (now.month >= 9) {
          return DateTime(now.year, 9, 1);
        } else {
          return DateTime(now.year - 1, 9, 1);
        }
      case 3: // Year
        return DateTime(now.year, 1, 1);
      default:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime get _periodEnd {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case 0: // Month
        return DateTime(now.year, now.month + 1, 0);
      case 1: // Quarter
        final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 3;
        return DateTime(now.year, quarterMonth + 1, 0);
      case 2: // Season (Sep-Aug)
        if (now.month >= 9) {
          return DateTime(now.year + 1, 8, 31);
        } else {
          return DateTime(now.year, 8, 31);
        }
      case 3: // Year
        return DateTime(now.year, 12, 31);
      default:
        return DateTime(now.year, now.month + 1, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: l10n.currencySymbol,
      decimalDigits: 2,
    );

    final periodLabels = [
      l10n.drePeriodoMes,
      l10n.drePeriodoTrimestre,
      l10n.drePeriodoSafra,
      l10n.drePeriodoAno,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dreTitle),
      ),
      drawer: buildCashDrawer(context: context, l10n: l10n),
      body: Consumer2<LancamentoService, CentroCustoService>(
        builder: (context, lancamentoService, centroCustoService, _) {
          final lancamentos = lancamentoService.getLancamentosPorPeriodo(
            _periodStart,
            _periodEnd,
          );
          final totalDespesas =
              lancamentos.fold(0.0, (sum, l) => sum + l.valor);
          final totalPorCategoria = lancamentoService.totalPorCategoria(
            _periodStart,
            _periodEnd,
          );
          final totalPorCentro = lancamentoService.totalPorCentroCusto(
            _periodStart,
            _periodEnd,
          );

          // For now, revenue = 0 (will come from cross-app integration CASH-03)
          const totalReceitas = 0.0;
          final resultado = totalReceitas - totalDespesas;
          final margem = totalReceitas > 0
              ? (resultado / totalReceitas * 100)
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Period Selector
                SegmentedButton<int>(
                  segments: List.generate(
                    periodLabels.length,
                    (i) => ButtonSegment(
                      value: i,
                      label: Text(
                        periodLabels[i],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  selected: {_selectedPeriod},
                  onSelectionChanged: (Set<int> selected) {
                    setState(() {
                      _selectedPeriod = selected.first;
                    });
                  },
                ),
                const SizedBox(height: 24),

                if (lancamentos.isEmpty) ...[
                  const SizedBox(height: 48),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.assessment_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.dreSemDados,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Revenue Section
                  _buildSectionHeader(
                    l10n.dreReceitas,
                    Colors.green,
                  ),
                  _buildLineItem(
                    l10n.dreReceitaBorracha,
                    0.0,
                    currencyFormat,
                    Colors.green,
                  ),
                  _buildLineItem(
                    l10n.dreReceitaGado,
                    0.0,
                    currencyFormat,
                    Colors.green,
                  ),
                  _buildTotalLine(
                    '${l10n.dreReceitas} Total',
                    totalReceitas,
                    currencyFormat,
                    Colors.green,
                  ),
                  const Divider(height: 32),

                  // Expenses Section
                  _buildSectionHeader(
                    l10n.dreDespesas,
                    Colors.red,
                  ),
                  // By Cost Center
                  ...totalPorCentro.entries.map((entry) {
                    final centro = centroCustoService.getCentroCusto(entry.key);
                    final nome = centro?.nome ?? entry.key;
                    return _buildLineItem(
                      nome,
                      entry.value,
                      currencyFormat,
                      Colors.red,
                    );
                  }),
                  _buildTotalLine(
                    '${l10n.dreDespesas} Total',
                    totalDespesas,
                    currencyFormat,
                    Colors.red,
                  ),
                  const Divider(height: 32),

                  // Result
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: resultado >= 0
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: resultado >= 0 ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          l10n.dreResultado,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(resultado),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                resultado >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                        if (totalReceitas > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${l10n.dreMargem}: ${margem.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Category Breakdown
                  _buildSectionHeader(
                    l10n.filterCategory,
                    Colors.blueGrey,
                  ),
                  ...totalPorCategoria.entries.map((entry) {
                    final percent = totalDespesas > 0
                        ? (entry.value / totalDespesas * 100)
                        : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            entry.key.icon,
                            color: entry.key.color,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(entry.key.localizedName(l10n)),
                          ),
                          Text(
                            currencyFormat.format(entry.value),
                            style: const TextStyle(
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 50,
                            child: Text(
                              '${percent.toStringAsFixed(0)}%',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildLineItem(
    String label,
    double value,
    NumberFormat format,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 16),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            format.format(value),
            style: TextStyle(color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalLine(
    String label,
    double value,
    NumberFormat format,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            format.format(value),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
