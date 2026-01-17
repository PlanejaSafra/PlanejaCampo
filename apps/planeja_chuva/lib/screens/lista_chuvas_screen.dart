import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';

/// Main screen for Planeja Chuva - displays rainfall records.
class ListaChuvasScreen extends StatelessWidget {
  /// App version for display in drawer and about screen.
  final String version;

  const ListaChuvasScreen({
    super.key,
    this.version = '1.0.0',
  });

  void _handleNavigation(BuildContext context, String routeKey) {
    switch (routeKey) {
      case AgroRouteKeys.home:
        // Already on home, do nothing
        break;
      case AgroRouteKeys.settings:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgroSettingsScreen(
              onNavigateToAbout: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AgroAboutScreen(
                      appName: 'Planeja Chuva',
                      version: version,
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
              version: version,
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planeja Chuva'),
      ),
      drawer: AgroDrawer(
        appName: 'Planeja Chuva',
        versionText: 'v$version',
        onNavigate: (routeKey) => _handleNavigation(context, routeKey),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.water_drop,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              l10n?.appName ?? 'Planeja Chuva',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Registros de chuva aparecerão aqui',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add rainfall record
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adicionar registro de chuva'),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
