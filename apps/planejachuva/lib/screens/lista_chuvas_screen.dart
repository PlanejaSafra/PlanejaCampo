import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/registro_chuva.dart';
import '../services/chuva_service.dart';
import '../widgets/estado_vazio.dart';
import '../widgets/registro_chuva_tile.dart';
import '../widgets/resumo_mensal_card.dart';
import 'adicionar_chuva_screen.dart';
import 'backup_screen.dart';
import 'editar_chuva_screen.dart';
import 'estatisticas_screen.dart';

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

  const ListaChuvasScreen({
    super.key,
    this.version = '1.0.0',
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
  });

  @override
  State<ListaChuvasScreen> createState() => _ListaChuvasScreenState();
}

class _ListaChuvasScreenState extends State<ListaChuvasScreen> {
  List<RegistroChuva> _registros = [];
  double _totalMesAtual = 0;
  double _totalMesAnterior = 0;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() {
    final service = ChuvaService();
    final now = DateTime.now();
    final mesAtual = DateTime(now.year, now.month, 1);
    final mesAnterior = DateTime(now.year, now.month - 1, 1);

    setState(() {
      _registros = service.listarTodos();
      _totalMesAtual = service.totalDoMes(mesAtual);
      _totalMesAnterior = service.totalDoMes(mesAnterior);
    });
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
            builder: (_) => AgroSettingsScreen(
              onChangeLocale: widget.onChangeLocale,
              currentLocale: widget.currentLocale,
              onChangeThemeMode: widget.onChangeThemeMode,
              currentThemeMode: widget.currentThemeMode,
              onNavigateToAbout: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgroAboutScreen(
                      appName: 'Planeja Chuva',
                      version: widget.version,
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
              appName: 'Planeja Chuva',
              version: widget.version,
            ),
          ),
        );
        break;
      case 'estatisticas':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EstatisticasScreen()),
        ).then((_) => _carregarDados());
        break;
      case 'backup':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BackupScreen()),
        ).then((_) => _carregarDados());
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

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.chuvaAppTitle),
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
            key: 'backup',
            icon: Icons.backup,
            title: l10n.chuvaBackup,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregarDados(),
        child: _registros.isEmpty
            ? const EstadoVazio()
            : CustomScrollView(
                slivers: [
                  // Monthly summary card
                  SliverToBoxAdapter(
                    child: ResumoMensalCard(
                      totalMesAtual: _totalMesAtual,
                      totalMesAnterior: _totalMesAnterior,
                      onTap: () => _navigateTo('estatisticas'),
                    ),
                  ),
                  // Records list with month separators
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
        icon: const Icon(Icons.add),
        label: Text(l10n.chuvaAdicionarTitle),
      ),
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
              );
            },
            childCount: entry.value.length,
          ),
        ),
      );
    }

    return slivers;
  }
}
