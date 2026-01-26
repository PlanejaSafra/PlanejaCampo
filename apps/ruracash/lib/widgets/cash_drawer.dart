import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Creates a standardized AgroDrawer for all RuraCash screens.
AgroDrawer buildCashDrawer({
  required BuildContext context,
  required CashLocalizations l10n,
}) {
  return AgroDrawer(
    appName: 'RuraCash',
    versionText: '1.0.0',
    extraItems: [
      AgroDrawerItem(
        icon: Icons.calculate,
        title: l10n.drawerCalculator,
        key: 'calculator',
      ),
      AgroDrawerItem(
        icon: Icons.account_tree,
        title: l10n.drawerCentros,
        key: 'centros',
      ),
      AgroDrawerItem(
        icon: Icons.assessment,
        title: l10n.drawerDre,
        key: 'dre',
      ),
    ],
    onNavigate: (route) {
      Navigator.pop(context); // Close drawer first
      switch (route) {
        case 'home':
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 'calculator':
          Navigator.pushReplacementNamed(context, '/calculator');
          break;
        case 'centros':
          Navigator.pushReplacementNamed(context, '/centros');
          break;
        case 'dre':
          Navigator.pushReplacementNamed(context, '/dre');
          break;
        case 'properties':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyListScreen()),
          );
          break;
        case 'settings':
          Navigator.pushNamed(context, '/settings');
          break;
        case 'about':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AgroAboutScreen(
                appName: 'RuraCash',
                version: '1.0.0',
              ),
            ),
          );
          break;
      }
    },
  );
}
