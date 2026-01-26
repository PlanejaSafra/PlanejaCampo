import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/user_profile_service.dart';
import '../services/entrega_service.dart';
import '../services/parceiro_service.dart';

/// Home dashboard screen with profile-based content.
/// Refactored in Phase 11 to prioritize Weather context and simplify role-based access.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // State for Weather Widget context
  Property? _defaultProperty;
  late PropertyService _propertyService;
  bool _isLoadingProperty = true;

  @override
  void initState() {
    super.initState();
    _propertyService = PropertyService();
    _carregarPropriedadePadrao();
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

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = UserProfileService.instance.currentProfile;

    // Produtor: Full access (Weighing, Partners, Deliveries)
    // Sangrador: Limited access (Weighing, Deliveries - NO Partners)
    final isProdutor = profile?.isProdutor ?? true;
    final isSangrador = profile?.isSangrador ?? false;

    // Common interface for both acting roles
    final showWeighingInterface = isProdutor || isSangrador;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
      ),
      drawer: AgroDrawer(
        appName: 'RuraRubber',
        versionText: '1.0.0', // TODO: Get from package info
        appLogoLightPath: 'assets/images/rurarubber-icon.png',
        appLogoDarkPath: 'assets/images/rurarubber-icon.png',
        onNavigate: (route) {
          switch (route) {
            case 'home':
              Navigator.pop(context); // Already on home
              break;
            case 'properties':
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PropertyListScreen(),
                ),
              ).then((_) => _carregarPropriedadePadrao()); // Refresh on return
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
            case 'settings':
              Navigator.pushNamed(context, '/settings').then((_) {
                // Refresh in case property changed in settings
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
          // Common items
          AgroDrawerItem(
              icon: Icons.scale, title: l10n.drawerPesagem, key: 'pesagem'),

          // Role-based items
          if (!isSangrador) // Sangrador does NOT manage partners
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _carregarPropriedadePadrao();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Message
              _buildWelcomeSection(context, l10n, theme),
              const SizedBox(height: 24),

              // WEATHER WIDGET (Replaces Quick Actions)
              // Provides context for "Minha Propriedade / Seringal"
              if (_defaultProperty != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Optional header if needed, but WeatherCard has title
                    WeatherCard(
                      propertyId: _defaultProperty!.id,
                      latitude: _defaultProperty!.latitude ?? 0.0,
                      longitude: _defaultProperty!.longitude ?? 0.0,
                      promptMessageOverride: isSangrador
                          ? AgroLocalizations.of(context)!
                              .weatherActivateForecastSeringalMessage
                          : null,
                      titleOverride: (isSangrador && !isProdutor) &&
                              _defaultProperty!.name == 'Minha Propriedade'
                          ? 'Seringal'
                          : _defaultProperty!.name,
                      onLocationUpdated: () {
                        // Reload default property to get new coordinates and refresh UI
                        _carregarPropriedadePadrao();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                )
              else if (!_isLoadingProperty)
                // Fallback if no property set (should ideally prompt to set one)
                // For now, minimal empty space or prompt
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

              // Monthly Summary (Produtor and Sangrador)
              // Only if we are in a Production context
              if (showWeighingInterface) ...[
                _buildMonthlySummary(context, l10n, theme),
                const SizedBox(height: 24),
              ],

              // Recent Deliveries (Produtor/Sangrador) or My Offers (Comprador)
              if (showWeighingInterface)
                _buildRecentDeliveries(context, l10n, theme)
              else
                _buildMyOffers(context, l10n, theme),

              // Bottom padding for FAB
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
        adUnitId:
            'ca-app-pub-3109803084293083/5660030835', // RuraRubber Production Banner
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
          (sum, e) => sum + e.itens.fold<double>(0, (s, i) => s + i.valorTotal),
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
                      // Navigate to entrega details
                      // Navigator.pushNamed(context, '/entregas', arguments: entrega.id);
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
    // For buyers - show their published offers
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

/// Summary item widget.
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
