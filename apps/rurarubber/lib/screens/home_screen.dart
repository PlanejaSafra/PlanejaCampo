import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';
import '../services/entrega_service.dart';
import '../services/parceiro_service.dart';

/// Home dashboard screen with profile-based content and safra integration.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Property? _defaultProperty;
  late PropertyService _propertyService;
  bool _isLoadingProperty = true;

  Safra? _activeSafra;

  @override
  void initState() {
    super.initState();
    _propertyService = PropertyService();
    _carregarPropriedadePadrao();
    _ensureSafra();
  }

  Future<void> _carregarPropriedadePadrao() async {
    final property = _propertyService.getDefaultProperty();
    if (mounted) {
      setState(() {
        _defaultProperty = property;
        _isLoadingProperty = false;
      });
    }
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

  String? _profileLabel(BorrachaLocalizations l10n) {
    final profile = UserProfileService.instance.currentProfile;
    if (profile == null) return null;
    switch (profile.profileType) {
      case UserProfileType.produtor:
        return l10n.profileLabelProdutor;
      case UserProfileType.comprador:
        return l10n.profileLabelComprador;
      case UserProfileType.sangrador:
        return l10n.profileLabelSangrador;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = UserProfileService.instance.currentProfile;

    final isProdutor = profile?.isProdutor ?? true;
    final isSangrador = profile?.isSangrador ?? false;
    final showWeighingInterface = isProdutor || isSangrador;
    final farmId = FarmService.instance.defaultFarmId ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
        actions: [
          if (farmId.isNotEmpty)
            SafraChip(
              farmId: farmId,
              onSafraChanged: _onSafraChanged,
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: AgroDrawer(
        appName: 'RuraRubber',
        versionText: '1.0.0',
        profileName: _profileLabel(l10n),
        appLogoLightPath: 'assets/images/rurarubber-icon.png',
        appLogoDarkPath: 'assets/images/rurarubber-icon.png',
        onNavigate: (route) {
          switch (route) {
            case 'home':
              Navigator.pop(context);
              break;
            case 'properties':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PropertyListScreen(),
                ),
              ).then((_) => _carregarPropriedadePadrao());
              break;
            case 'parceiros':
              Navigator.pushNamed(context, '/parceiros');
              break;
            case 'pesagem':
              Navigator.pushNamed(context, '/pesagem');
              break;
            case 'mercado':
              Navigator.pushNamed(context, '/mercado');
              break;
            case 'entregas':
              Navigator.pushNamed(context, '/entregas');
              break;
            case 'jobs':
              Navigator.pushNamed(context, '/jobs');
              break;
            case 'recebiveis':
              Navigator.pushNamed(context, '/recebiveis');
              break;
            case 'contas-pagar':
              Navigator.pushNamed(context, '/contas-pagar');
              break;
            case 'break-even':
              Navigator.pushNamed(context, '/break-even');
              break;
            case 'settings':
              Navigator.pushNamed(context, '/settings').then((_) {
                _carregarPropriedadePadrao();
              });
              break;
            case 'privacy':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgroPrivacyScreen(),
                ),
              );
              break;
            case 'about':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AgroAboutScreen(
                    appName: 'RuraRubber',
                    version: '1.0.0',
                    appLogoLightPath: 'assets/images/rurarubber-icon.png',
                    appLogoDarkPath: 'assets/images/rurarubber-icon.png',
                    suiteLogoLightPath:
                        'packages/agro_core/assets/images/ruracamp-icon.png',
                    suiteLogoDarkPath:
                        'packages/agro_core/assets/images/ruracamp-icon.png',
                  ),
                ),
              );
              break;
          }
        },
        extraItems: [
          AgroDrawerItem(
              icon: Icons.scale, title: l10n.drawerPesagem, key: 'pesagem'),
          if (!isSangrador)
            AgroDrawerItem(
                icon: Icons.people,
                title: l10n.drawerParceiros,
                key: 'parceiros'),
          AgroDrawerItem(
              icon: Icons.history, title: l10n.drawerEntregas, key: 'entregas'),
          AgroDrawerItem(
              icon: Icons.store, title: l10n.drawerMercado, key: 'mercado'),
          AgroDrawerItem(
              icon: Icons.work_outline, title: l10n.jobsTitle, key: 'jobs'),
          if (!isSangrador)
            AgroDrawerItem(
                icon: Icons.account_balance_wallet,
                title: l10n.recebiveisTitle,
                key: 'recebiveis'),
          if (!isSangrador)
            AgroDrawerItem(
                icon: Icons.receipt_long,
                title: l10n.contasPagarTitle,
                key: 'contas-pagar'),
          if (!isSangrador)
            AgroDrawerItem(
                icon: Icons.analytics,
                title: l10n.breakEvenTitle,
                key: 'break-even'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _carregarPropriedadePadrao();
          await _ensureSafra();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context, l10n, theme),
              const SizedBox(height: 24),

              // Weather Widget
              if (_defaultProperty != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WeatherCard(
                      propertyId: _defaultProperty!.id,
                      latitude: _defaultProperty!.latitude ?? 0.0,
                      longitude: _defaultProperty!.longitude ?? 0.0,
                      promptMessageOverride: isSangrador
                          ? AgroLocalizations.of(context)!
                              .weatherActivateForecastSeringalMessage
                          : null,
                      titleOverride: (isSangrador && !isProdutor) &&
                              _defaultProperty!.name ==
                                  AgroLocalizations.of(context)!.propertyDefaultName
                          ? AgroLocalizations.of(context)!.rubberPlantationTitle
                          : _defaultProperty!.name,
                      onLocationUpdated: () {
                        _carregarPropriedadePadrao();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              else if (!_isLoadingProperty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isSangrador
                              ? l10n.homeConfigureSeringal
                              : l10n.homeConfigureProperty,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PropertyListScreen(),
                            ),
                          ).then((_) => _carregarPropriedadePadrao());
                        },
                        child: Text(isSangrador
                            ? l10n.homeBtnConfigureSeringal
                            : l10n.homeBtnConfigure),
                      ),
                    ],
                  ),
                ),

              if (!_isLoadingProperty && _defaultProperty == null)
                const SizedBox(height: 24),

              // Safra Summary (Hierarchical: Farm Total + Parceiros)
              if (showWeighingInterface && _activeSafra != null) ...[
                _buildSafraSummary(context, l10n, theme),
                const SizedBox(height: 16),
                _buildParceiroRanking(context, l10n, theme),
                const SizedBox(height: 24),
              ] else if (showWeighingInterface) ...[
                _buildMonthlySummary(context, l10n, theme),
                const SizedBox(height: 24),
              ],

              // Recent Deliveries or My Offers
              if (showWeighingInterface)
                _buildRecentDeliveries(context, l10n, theme)
              else
                _buildMyOffers(context, l10n, theme),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (showWeighingInterface) {
            Navigator.pushNamed(context, '/pesagem');
          } else {
            Navigator.pushNamed(context, '/criar-oferta');
          }
        },
        icon: Icon(showWeighingInterface ? Icons.add : Icons.post_add),
        label: Text(showWeighingInterface
            ? l10n.homeNewWeighing
            : l10n.homeCreateOffer),
      ),
      bottomNavigationBar: const AgroBannerWidget(
        adUnitId: 'ca-app-pub-3109803084293083/5660030835',
      ),
    );
  }

  Widget _buildWelcomeSection(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    final user = AuthService.currentUser;
    final displayName = user?.displayName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName != null
              ? l10n.homeWelcome(displayName)
              : l10n.homeWelcomeGeneric,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Safra-based summary card: Total Fazenda stats.
  Widget _buildSafraSummary(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    final safra = _activeSafra!;
    return Consumer<EntregaService>(
      builder: (context, entregaService, child) {
        final totalPeso = entregaService.totalPesoSafra(safra);
        final totalValor = entregaService.totalValorSafra(safra);
        final countEntregas = entregaService.countEntregasSafra(safra);
        final monthlyData = entregaService.totalMensalSafra(safra);
        final monthCount = monthlyData.length;
        final mediaMensal = monthCount > 0 ? totalPeso / monthCount : 0.0;
        final nf = NumberFormat('#,##0.0', 'pt_BR');

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.agriculture, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.totalFazenda,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      safra.nome,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (countEntregas == 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.homeSummaryNoData,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.homeSummaryDeliveries,
                          value: '$countEntregas',
                          icon: Icons.local_shipping,
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.homeSummaryTotalWeight,
                          value: '${nf.format(totalPeso)} kg',
                          icon: Icons.scale,
                          color: Colors.green,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.mediaMensal,
                          value: '${nf.format(mediaMensal)} kg',
                          icon: Icons.trending_up,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                if (totalValor > 0) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      '${l10n.homeSummaryTotalValue}: R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(totalValor)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Parceiro ranking within the active safra.
  Widget _buildParceiroRanking(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    final safra = _activeSafra!;
    return Consumer2<EntregaService, ParceiroService>(
      builder: (context, entregaService, parceiroService, child) {
        final pesoPorParceiro = entregaService.pesoPorParceiroSafra(safra);
        if (pesoPorParceiro.isEmpty) return const SizedBox.shrink();

        final totalGeral =
            pesoPorParceiro.values.fold<double>(0, (s, v) => s + v);
        final sorted = pesoPorParceiro.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final nf = NumberFormat('#,##0.0', 'pt_BR');

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.drawerParceiros,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...sorted.map((entry) {
              final parceiro = parceiroService.getParceiro(entry.key);
              final nome = parceiro?.nome ?? l10n.unknownPartner;
              final peso = entry.value;
              final pct = totalGeral > 0 ? (peso / totalGeral) * 100 : 0.0;

              return Card(
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      nome.isNotEmpty ? nome[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(nome),
                  subtitle: LinearProgressIndicator(
                    value: totalGeral > 0 ? peso / totalGeral : 0,
                    backgroundColor:
                        theme.colorScheme.surfaceContainerHighest,
                    color: theme.colorScheme.primary,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${nf.format(peso)} kg',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}% ${l10n.doTotal}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, '/parceiro-detail',
                        arguments: entry.key);
                  },
                ),
              );
            }),
          ],
        );
      },
    );
  }

  /// Fallback monthly summary (when no safra available).
  Widget _buildMonthlySummary(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    return Consumer<EntregaService>(
      builder: (context, entregaService, child) {
        final now = DateTime.now();
        final entregas = entregaService.entregas.where((e) {
          return e.data.year == now.year && e.data.month == now.month;
        }).toList();

        final totalWeight = entregas.fold<double>(
          0,
          (sum, e) => sum + e.itens.fold<double>(0, (s, i) => s + i.pesoTotal),
        );

        final totalValue = entregas.fold<double>(
          0,
          (sum, e) =>
              sum + e.itens.fold<double>(0, (s, i) => s + i.valorTotal),
        );

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.calendar_month,
                        color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.homeSummaryTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (entregas.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        l10n.homeSummaryNoData,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.homeSummaryDeliveries,
                          value: '${entregas.length}',
                          icon: Icons.local_shipping,
                          color: Colors.blue,
                        ),
                      ),
                      Expanded(
                        child: _SummaryItem(
                          label: l10n.homeSummaryTotalWeight,
                          value: '${totalWeight.toStringAsFixed(1)} kg',
                          icon: Icons.scale,
                          color: Colors.green,
                        ),
                      ),
                      if (totalValue > 0)
                        Expanded(
                          child: _SummaryItem(
                            label: l10n.homeSummaryTotalValue,
                            value: 'R\$ ${totalValue.toStringAsFixed(2)}',
                            icon: Icons.attach_money,
                            color: Colors.orange,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentDeliveries(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    return Consumer2<EntregaService, ParceiroService>(
      builder: (context, entregaService, parceiroService, child) {
        final recentEntregas =
            entregaService.entregas.reversed.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeRecentDeliveries,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (recentEntregas.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/entregas'),
                    child: Text(l10n.homeViewAllDeliveries),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentEntregas.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.homeNoRecentDeliveries,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ...recentEntregas.map((entrega) {
                final totalWeight = entrega.itens
                    .fold<double>(0, (sum, i) => sum + i.pesoTotal);
                final partnerCount = entrega.itens.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(entrega.status),
                      child: const Icon(Icons.local_shipping,
                          color: Colors.white, size: 20),
                    ),
                    title: Text(
                      '${entrega.data.day}/${entrega.data.month}/${entrega.data.year}',
                    ),
                    subtitle: Text(
                      '$partnerCount ${l10n.partnersAttended} • ${totalWeight.toStringAsFixed(1)} kg',
                    ),
                    trailing: Chip(
                      label: Text(
                        _getStatusLabel(entrega.status, l10n),
                        style: TextStyle(
                          color: _getStatusColor(entrega.status),
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: _getStatusColor(entrega.status)
                          .withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/entregas');
                    },
                  ),
                );
              }),
          ],
        );
      },
    );
  }

  Widget _buildMyOffers(
      BuildContext context, BorrachaLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeMyOffers,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.post_add,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.homeNoMyOffers,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/criar-oferta'),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.homeCreateOffer),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'fechado':
        return Colors.blue;
      case 'pago':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status, BorrachaLocalizations l10n) {
    switch (status) {
      case 'fechado':
        return l10n.listaEntregasStatusClosed;
      case 'pago':
        return l10n.listaEntregasStatusPaid;
      default:
        return l10n.listaEntregasStatusOpen;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
