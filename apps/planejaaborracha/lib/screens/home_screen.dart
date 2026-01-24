import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/user_profile_service.dart';
import '../services/entrega_service.dart';
import '../services/parceiro_service.dart';

/// Home dashboard screen with profile-based content.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final profile = UserProfileService.instance.currentProfile;
    // Produtor and Sangrador share similar interface (weighing, partners, deliveries)
    final isProdutor = profile?.isProdutor ?? true;
    final isSangrador = profile?.isSangrador ?? false;
    final showWeighingInterface = isProdutor || isSangrador;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
      ),
      drawer: AgroDrawer(
        appName: 'PlanejaBorracha',
        versionText: '1.0.0',
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
              );
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
            case 'settings':
              Navigator.pushNamed(context, '/settings');
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
                    appName: 'PlanejaBorracha',
                    version: '1.0.0',
                  ),
                ),
              );
              break;
          }
        },
        extraItems: [
          AgroDrawerItem(
              icon: Icons.scale, title: l10n.drawerPesagem, key: 'pesagem'),
          AgroDrawerItem(
              icon: Icons.people,
              title: l10n.drawerParceiros,
              key: 'parceiros'),
          AgroDrawerItem(
              icon: Icons.history, title: l10n.drawerEntregas, key: 'entregas'),
          AgroDrawerItem(
              icon: Icons.store, title: l10n.drawerMercado, key: 'mercado'),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
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

              // Quick Actions
              _buildQuickActionsSection(
                  context, l10n, theme, showWeighingInterface),
              const SizedBox(height: 24),

              // Monthly Summary (Produtor and Sangrador)
              if (showWeighingInterface) ...[
                _buildMonthlySummary(context, l10n, theme),
                const SizedBox(height: 24),
              ],

              // Recent Deliveries (Produtor/Sangrador) or My Offers (Comprador)
              if (showWeighingInterface)
                _buildRecentDeliveries(context, l10n, theme)
              else
                _buildMyOffers(context, l10n, theme),
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
            'ca-app-pub-3109803084293083/5660030835', // PlanejaBorracha Production Banner
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

  Widget _buildQuickActionsSection(BuildContext context,
      BorrachaLocalizations l10n, ThemeData theme, bool showWeighingInterface) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeQuickActions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (showWeighingInterface)
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.scale,
                  iconColor: Colors.green,
                  title: l10n.homeNewWeighing,
                  subtitle: l10n.homeNewWeighingDesc,
                  onTap: () => Navigator.pushNamed(context, '/pesagem'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.people,
                  iconColor: Colors.orange,
                  title: l10n.homeViewPartners,
                  subtitle: l10n.homeViewPartnersDesc,
                  onTap: () => Navigator.pushNamed(context, '/parceiros'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.post_add,
                  iconColor: Colors.blue,
                  title: l10n.homeCreateOffer,
                  subtitle: l10n.homeViewMarketDesc,
                  onTap: () => Navigator.pushNamed(context, '/criar-oferta'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.store,
                  iconColor: Colors.purple,
                  title: l10n.homeViewMarket,
                  subtitle: l10n.homeViewMarketDesc,
                  onTap: () => Navigator.pushNamed(context, '/mercado'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.history,
                iconColor: Colors.indigo,
                title: l10n.homeViewHistory,
                subtitle: l10n.homeViewHistoryDesc,
                onTap: () => Navigator.pushNamed(context, '/entregas'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.store,
                iconColor: Colors.teal,
                title: l10n.homeViewMarket,
                subtitle: l10n.homeViewMarketDesc,
                onTap: () => Navigator.pushNamed(context, '/mercado'),
              ),
            ),
          ],
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
        final recentEntregas = entregaService.entregas.take(3).toList();

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

/// Quick action card widget.
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
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
