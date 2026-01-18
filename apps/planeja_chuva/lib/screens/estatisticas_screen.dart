import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';

/// Screen displaying rainfall statistics.
class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen> {
  late List<RegistroChuva> _registros;
  late double _totalAno;
  late double _mediaRegistro;
  late double _maiorRegistro;
  late int _totalRegistros;
  late double _totalMesAtual;
  late double _totalMesAnterior;

  @override
  void initState() {
    super.initState();
    _calcularEstatisticas();
  }

  void _calcularEstatisticas() {
    final service = ChuvaService();
    _registros = service.listarTodos();

    final now = DateTime.now();
    final inicioAno = DateTime(now.year, 1, 1);
    final mesAtual = DateTime(now.year, now.month, 1);
    final mesAnterior = DateTime(now.year, now.month - 1, 1);

    // Filter by current year
    final registrosAno = _registros.where(
      (r) => r.data.isAfter(inicioAno) || r.data.isAtSameMomentAs(inicioAno),
    );

    _totalAno = registrosAno.fold(0.0, (sum, r) => sum + r.milimetros);
    _totalRegistros = _registros.length;
    _mediaRegistro =
        _totalRegistros > 0 ? _totalAno / registrosAno.length : 0.0;
    _maiorRegistro = _registros.isEmpty
        ? 0.0
        : _registros.map((r) => r.milimetros).reduce((a, b) => a > b ? a : b);
    _totalMesAtual = service.totalDoMes(mesAtual);
    _totalMesAnterior = service.totalDoMes(mesAnterior);
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: valueColor ?? theme.colorScheme.primary,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 2),
                        child: Text(
                          unit,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chuvaEstatisticasTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _calcularEstatisticas());
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current month summary
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      l10n.chuvaTotalDoMes,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _totalMesAtual.toStringAsFixed(1),
                          style: theme.textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            l10n.chuvaMm,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Comparison with previous month
                    if (_totalMesAnterior > 0 || _totalMesAtual > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _totalMesAtual >= _totalMesAnterior
                              ? l10n.chuvaComparacaoMesAcima
                              : l10n.chuvaComparacaoMesAbaixo,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Year total
            _buildStatCard(
              title: l10n.chuvaTotalAno,
              value: _totalAno.toStringAsFixed(1),
              unit: l10n.chuvaMm,
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 8),
            // Previous month
            _buildStatCard(
              title: l10n.chuvaMesAnterior,
              value: _totalMesAnterior.toStringAsFixed(1),
              unit: l10n.chuvaMm,
              icon: Icons.history,
            ),
            const SizedBox(height: 8),
            // Average per rain
            _buildStatCard(
              title: l10n.chuvaMediaPorChuva,
              value: _mediaRegistro.toStringAsFixed(1),
              unit: l10n.chuvaMm,
              icon: Icons.analytics,
            ),
            const SizedBox(height: 8),
            // Highest record
            _buildStatCard(
              title: l10n.chuvaMaiorRegistro,
              value: _maiorRegistro.toStringAsFixed(1),
              unit: l10n.chuvaMm,
              icon: Icons.arrow_upward,
              valueColor: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            // Total records
            _buildStatCard(
              title: l10n.chuvaTotalRegistros,
              value: _totalRegistros.toString(),
              unit: '',
              icon: Icons.list,
            ),
          ],
        ),
      ),
    );
  }
}
