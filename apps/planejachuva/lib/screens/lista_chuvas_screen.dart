import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';
import '../services/validation_service.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/registro_chuva_tile.dart';
import '../widgets/resumo_mensal_card.dart';
import '../models/user_preferences.dart';
import 'adicionar_chuva_screen.dart';
import 'configuracoes_screen.dart';
import 'editar_chuva_screen.dart';
import 'estatisticas_screen.dart';
import 'regional_stats_screen.dart';

/// Main screen for Planeja Chuva - displays rainfall records.
class ListaChuvasScreen extends StatefulWidget {
  /// App version for display in drawer and about screen.
  final String version;

  /// Callback to change app locale.
  final void Function(Locale?)? onChangeLocale;

  /// Current selected locale (null = auto).
  final Locale? currentLocale;

  /// Callback to change app theme mode.
  final void Function(ThemeMode)? onChangeThemeMode;

  /// Current theme mode.
  final ThemeMode currentThemeMode;

  /// User preferences for reminder settings.
  final UserPreferences preferences;

  /// Callback when reminder settings change.
  final void Function(bool, TimeOfDay?)? onReminderChanged;

  const ListaChuvasScreen({
    super.key,
    this.version = '1.0.0',
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
    required this.preferences,
    this.onReminderChanged,
  });

  @override
  State<ListaChuvasScreen> createState() => _ListaChuvasScreenState();
}

class _ListaChuvasScreenState extends State<ListaChuvasScreen> {
  List<RegistroChuva> _registros = [];
  double _totalMesAtual = 0;
  double _totalMesAnterior = 0;
  Property? _defaultProperty;
  String? _selectedTalhaoId;
  late PropertyService _propertyService;

  @override
  void initState() {
    super.initState();
    _propertyService = PropertyService();
    _carregarPropriedadePadrao().then((_) => _carregarDados());
  }

  Future<void> _carregarPropriedadePadrao() async {
    final property = _propertyService.getDefaultProperty();
    if (mounted) {
      setState(() {
        _defaultProperty = property;
      });
    }
  }

  void _carregarDados() {
    final service = ChuvaService();
    final now = DateTime.now();
    final mesAtual = DateTime(now.year, now.month, 1);
    final mesAnterior = DateTime(now.year, now.month - 1, 1);

    if (_defaultProperty == null) {
      if (mounted) {
        setState(() {
          _registros = [];
          _totalMesAtual = 0;
          _totalMesAnterior = 0;
        });
      }
      return;
    }

    final propertyId = _defaultProperty!.id;
    List<RegistroChuva> registros;

    if (_selectedTalhaoId == null) {
      // Aggregate: All records for the property
      registros = service.listarTodos(propertyId: propertyId);
    } else {
      // Specific Talhão
      registros = service.listarPorTalhao(propertyId, _selectedTalhaoId!);
    }

    // Calculate totals respecting the filter
    final totalAtual = service.totalDoMesByTalhao(
      mesAtual,
      propertyId,
      talhaoId: _selectedTalhaoId,
    );
    final totalAnterior = service.totalDoMesByTalhao(
      mesAnterior,
      propertyId,
      talhaoId: _selectedTalhaoId,
    );

    if (mounted) {
      setState(() {
        _registros = registros;
        _totalMesAtual = totalAtual;
        _totalMesAnterior = totalAnterior;
      });
    }
  }

  void _handleDrawerNavigation(String routeKey) {
    // AgroDrawer already closes itself before calling onNavigate
    _navigateTo(routeKey);
  }

  void _navigateTo(String routeKey) {
    switch (routeKey) {
      case AgroRouteKeys.home:
        // Already on home, do nothing
        break;
      case AgroRouteKeys.settings:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfiguracoesScreen(
              onChangeLocale: widget.onChangeLocale,
              currentLocale: widget.currentLocale,
              onChangeThemeMode: widget.onChangeThemeMode,
              currentThemeMode: widget.currentThemeMode,
              preferences: widget.preferences,
              onReminderChanged: widget.onReminderChanged,
              onRestoreComplete: () {
                // Refresh data after restore
                _carregarPropriedadePadrao().then((_) => _carregarDados());
              },
              onNavigateToAbout: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgroAboutScreen(
                      appName: 'PlanejaChuva',
                      version: widget.version,
                      appLogoPath:
                          'assets/images/planejachuva_logo_transparent.png',
                      suiteLogoPath:
                          'packages/agro_core/assets/images/planejacampo_light.png',
                    ),
                  ),
                );
              },
            ),
          ),
        );
        break;
      case AgroRouteKeys.privacy:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AgroPrivacyScreen(),
          ),
        );
        break;
      case AgroRouteKeys.about:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgroAboutScreen(
              appName: 'PlanejaChuva',
              version: widget.version,
              appLogoPath: 'assets/images/planejachuva_logo_transparent.png',
              suiteLogoPath:
                  'packages/agro_core/assets/images/planejacampo_light.png',
            ),
          ),
        );
        break;
      case AgroRouteKeys.properties:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PropertyListScreen(),
          ),
        ).then((_) => _carregarDados());
        break;
      case 'estatisticas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstatisticasScreen()),
        ).then((_) => _carregarDados());
        break;
      case 'regional_stats':
        if (_defaultProperty != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegionalStatsScreen(
                propertyId: _defaultProperty!.id,
                latitude: _defaultProperty!.latitude,
                longitude: _defaultProperty!.longitude,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Configure uma propriedade com localização primeiro'),
            ),
          );
        }
        break;
      case AgroRouteKeys.heatmap:
        if (_defaultProperty != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WeatherMapScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Configure uma propriedade com localização primeiro'),
            ),
          );
        }
        break;
    }
  }

  Future<void> _adicionarChuva() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AdicionarChuvaScreen()),
    );
    if (result == true) {
      _carregarDados();
    }
  }

  Future<void> _editarChuva(RegistroChuva registro) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditarChuvaScreen(registro: registro),
      ),
    );
    if (result == true) {
      _carregarDados();
    }
  }

  Future<void> _excluirChuva(RegistroChuva registro) async {
    final l10n = AgroLocalizations.of(context)!;

    await ChuvaService().excluir(registro.id);
    _carregarDados();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chuvaExcluida),
          action: SnackBarAction(
            label: l10n.chuvaDesfazer,
            onPressed: () async {
              await ChuvaService().adicionar(registro);
              _carregarDados();
            },
          ),
        ),
      );
    }
  }

  /// Groups records by month for display with separators.
  Map<String, List<RegistroChuva>> _agruparPorMes() {
    final agrupados = <String, List<RegistroChuva>>{};
    final locale = Localizations.localeOf(context).toString();

    for (final registro in _registros) {
      final key = DateFormat.yMMMM(locale).format(registro.data);
      agrupados.putIfAbsent(key, () => []).add(registro);
    }

    return agrupados;
  }

  /// Build drought warning banner if applicable.
  List<Widget> _buildDroughtWarning() {
    final validator = ValidationService();
    final days = validator.daysSinceLastRain();

    if (days == null || !validator.hasDroughtWarning()) {
      return [];
    }

    final locale = Localizations.localeOf(context).toString();
    final message = validator.getDroughtWarningMessage(days, locale);

    return [
      SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border.all(color: Colors.orange.shade700, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber,
                  color: Colors.orange.shade900, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final propService = PropertyService();

    // Determine conditional visibility
    final propCount = propService.getPropertyCount();
    final showPropertyName = propCount > 1 && _defaultProperty != null;

    // Check talhão count for the current property (used in tile generation)
    // final talhaoCount = _defaultProperty != null
    //    ? talhaoService.countByProperty(_defaultProperty!.id)
    //    : 0;
    // final showTalhaoName = talhaoCount > 1;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chuvaAppTitle),
            if (showPropertyName)
              Text(
                _defaultProperty!.name,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () => _navigateTo('estatisticas'),
            tooltip: l10n.chuvaEstatisticas,
          ),
        ],
      ),
      drawer: AgroDrawer(
        appName: 'Planeja Chuva',
        versionText: 'v${widget.version}',
        onNavigate: _handleDrawerNavigation,
        extraItems: [
          AgroDrawerItem(
            key: 'estatisticas',
            icon: Icons.bar_chart,
            title: l10n.chuvaEstatisticas,
          ),
          AgroDrawerItem(
            key: 'regional_stats',
            icon: Icons.public,
            title: 'Estatísticas Regionais',
          ),
          AgroDrawerItem(
            key: AgroRouteKeys.heatmap,
            icon: Icons.map_outlined,
            title: l10n.drawerHeatmap,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregarDados(),
        child: CustomScrollView(
          slivers: [
            // Drought warning (if applicable)
            ..._buildDroughtWarning(),
            // Weather forecast card
            if (_defaultProperty != null)
              SliverToBoxAdapter(
                child: WeatherCard(
                  propertyId: _defaultProperty!.id,
                  latitude: _defaultProperty!.latitude ?? 0.0,
                  longitude: _defaultProperty!.longitude ?? 0.0,
                  onLocationUpdated: () {
                    // Reload default property to get new coordinates and refresh UI
                    _carregarPropriedadePadrao().then((_) => _carregarDados());
                  },
                ),
              ),
            // Monthly summary card (only if not empty OR if we want to show 0s?
            // Usually summary of 0 is fine, but empty state looks better if truly empty).
            // Let's show summary card if we have data OR if we want to show "0mm this month".
            // If empty list, maybe skip summary card and just show Empty State?
            // User request implies "Weather Forecast" was missing.
            // Let's keep Summary Card only if records exist, to match "Empty State" feel below headers.
            if (_registros.isNotEmpty)
              SliverToBoxAdapter(
                child: ResumoMensalCard(
                  totalMesAtual: _totalMesAtual,
                  totalMesAnterior: _totalMesAnterior,
                  onTap: () => _navigateTo('estatisticas'),
                ),
              ),

            // Registers List OR Empty State
            if (_registros.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EstadoVazio(),
              )
            else
              ..._buildRecordsList(),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarChuva,
        icon: const Icon(Icons.add,
            size: 28), // Larger icon for better visibility
        label: Text(
          l10n.chuvaAdicionarTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  List<Widget> _buildRecordsList() {
    final agrupados = _agruparPorMes();
    final slivers = <Widget>[];
    final theme = Theme.of(context);

    for (final entry in agrupados.entries) {
      // Month separator header
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              entry.key.toUpperCase(),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      );

      // Records for this month
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final registro = entry.value[index];
              return RegistroChuvasTile(
                registro: registro,
                onTap: () => _editarChuva(registro),
                onDelete: () => _excluirChuva(registro),
                showTalhaoName: _shouldShowTalhaoName(),
              );
            },
            childCount: entry.value.length,
          ),
        ),
      );
    }

    return slivers;
  }

  bool _shouldShowTalhaoName() {
    if (_defaultProperty == null) return false;
    final count = TalhaoService().countByProperty(_defaultProperty!.id);
    return count > 1;
  }
}
