import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';
import '../widgets/comparacao_anual_card.dart';
import '../widgets/comparacao_anual_chart.dart';
import '../widgets/visualizacao_barras.dart';
import '../widgets/balanco_hidrico_chart.dart';

/// Screen displaying rainfall statistics.
class EstatisticasScreen extends StatefulWidget {
  const EstatisticasScreen({super.key});

  @override
  State<EstatisticasScreen> createState() => _EstatisticasScreenState();
}

class _EstatisticasScreenState extends State<EstatisticasScreen>
    with SingleTickerProviderStateMixin {
  late List<RegistroChuva> _registros;
  late double _totalAno;
  late double _mediaRegistro;
  late double _maiorRegistro;
  late int _totalRegistros;
  late double _totalMesAtual;
  late double _totalMesAnterior;
  late Map<String, double> _monthlyData;
  late TabController _tabController;

  String? _propertyId;
  String? _selectedTalhaoId;
  double? _propertyLat;
  double? _propertyLng;
  bool _isLoadingProperty = true;
  final _propertyService = PropertyService();
  final _talhaoService = TalhaoService();
  final _chuvaService = ChuvaService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProperty();
  }

  Future<void> _loadProperty() async {
    final property = await _propertyService.getDefaultProperty();
    if (mounted) {
      setState(() {
        _propertyId = property?.id;
        _propertyLat = property?.latitude;
        _propertyLng = property?.longitude;
        _isLoadingProperty = false;
        _calcularEstatisticas();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Returns a formatted number respecting locale (comma or dot).
  String _formatNumber(double value) {
    final locale = Localizations.localeOf(context).toString();
    return NumberFormat('#0.0', locale).format(value);
  }

  void _calcularEstatisticas() {
    if (_propertyId == null) {
      _registros = [];
      // If no property, we might fallback to all records or empty
      // sticking to empty for safety to avoid mixing properties
    } else {
      if (_selectedTalhaoId == null) {
        // Aggregate: All records for the property
        _registros = _chuvaService.listarTodos(propertyId: _propertyId);
      } else {
        // Specific Talhão
        _registros =
            _chuvaService.listarPorTalhao(_propertyId!, _selectedTalhaoId!);
      }
    }

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
    _totalMesAtual = _chuvaService.totalDoMes(mesAtual);
    _totalMesAnterior = _chuvaService.totalDoMes(mesAnterior);

    // Build monthly data for visualizations
    _monthlyData = {};
    for (final registro in _registros) {
      final key =
          '${registro.data.year}-${registro.data.month.toString().padLeft(2, '0')}';
      _monthlyData[key] = (_monthlyData[key] ?? 0.0) + registro.milimetros;
    }
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
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chuvaEstatisticasTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: l10n.chuvaStatsTabOverview,
              icon: const Icon(Icons.dashboard),
            ),
            Tab(
              text: l10n.chuvaStatsTabBars,
              icon: const Icon(Icons.bar_chart),
            ),
            Tab(
              text: l10n.chuvaStatsTabCompare,
              icon: const Icon(Icons.compare),
            ),
          ],
        ),
      ),
      body: _isLoadingProperty
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_propertyId != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: TalhaoSelector(
                      propertyId: _propertyId!,
                      selectedTalhaoId: _selectedTalhaoId,
                      talhaoService: _talhaoService,
                      onChanged: (id) {
                        setState(() {
                          _selectedTalhaoId = id;
                          _calcularEstatisticas();
                        });
                      },
                      // Disable "Create New" in statistics filter
                      onCreateNew: null,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Overview (existing statistics)
                      _buildOverviewTab(l10n, theme),
                      // Tab 2: Bar chart visualization
                      _buildBarsTab(locale),
                      // Tab 3: Year comparison
                      _buildComparisonTab(locale),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  Widget _buildOverviewTab(AgroLocalizations l10n, ThemeData theme) {
    return RefreshIndicator(
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
                        _formatNumber(_totalMesAtual),
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
          // Water Balance Chart (CORE-68)
          if (_propertyId != null &&
              _propertyLat != null &&
              _propertyLng != null)
            BalancoHidricoChart(
              propertyId: _propertyId!,
              talhaoId: _selectedTalhaoId,
              latitude: _propertyLat!,
              longitude: _propertyLng!,
            ),
          const SizedBox(height: 16),
          // Year total
          _buildStatCard(
            title: l10n.chuvaTotalAno,
            value: _formatNumber(_totalAno),
            unit: l10n.chuvaMm,
            icon: Icons.calendar_today,
          ),
          const SizedBox(height: 8),
          // Previous month
          _buildStatCard(
            title: l10n.chuvaMesAnterior,
            value: _formatNumber(_totalMesAnterior),
            unit: l10n.chuvaMm,
            icon: Icons.history,
          ),
          const SizedBox(height: 8),
          // Average per rain
          _buildStatCard(
            title: l10n.chuvaMediaPorChuva,
            value: _formatNumber(_mediaRegistro),
            unit: l10n.chuvaMm,
            icon: Icons.analytics,
          ),
          const SizedBox(height: 8),
          // Highest record
          _buildStatCard(
            title: l10n.chuvaMaiorRegistro,
            value: _formatNumber(_maiorRegistro),
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
    );
  }

  Widget _buildBarsTab(String locale) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _calcularEstatisticas());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          VisualizacaoBarrasWidget(
            monthlyData: _monthlyData,
            locale: locale,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab(String locale) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _calcularEstatisticas());
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ComparacaoAnualChart(
            monthlyData: _monthlyData,
            locale: locale,
          ),
          const SizedBox(height: 16),
          ComparacaoAnualCard(
            monthlyData: _monthlyData,
            locale: locale,
          ),
        ],
      ),
    );
  }
}
