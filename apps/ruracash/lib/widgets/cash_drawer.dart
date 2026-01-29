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
        icon: Icons.attach_money,
        title: l10n.drawerReceitas,
        key: 'receitas',
      ),
      AgroDrawerItem(
        icon: Icons.account_balance,
        title: l10n.drawerContas,
        key: 'contas',
      ),
      AgroDrawerItem(
        icon: Icons.receipt_long,
        title: l10n.drawerContasPagar,
        key: 'contas_pagar',
      ),
      AgroDrawerItem(
        icon: Icons.pie_chart,
        title: l10n.drawerOrcamentos,
        key: 'orcamentos',
      ),
      AgroDrawerItem(
        icon: Icons.assessment,
        title: l10n.drawerDre,
        key: 'dre',
      ),
      AgroDrawerItem(
        icon: Icons.balance,
        title: l10n.drawerBalanco,
        key: 'balanco',
      ),
      AgroDrawerItem(
        icon: Icons.show_chart,
        title: l10n.drawerFluxo,
        key: 'fluxo',
      ),
      AgroDrawerItem(
        icon: Icons.compare_arrows,
        title: l10n.drawerReconciliacao,
        key: 'reconciliacao',
      ),
      AgroDrawerItem(
        icon: Icons.category,
        title: l10n.drawerCategorias,
        key: 'categorias',
      ),
      AgroDrawerItem(
        icon: Icons.account_tree,
        title: l10n.drawerCentros,
        key: 'centros',
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
        case 'receitas':
          Navigator.pushReplacementNamed(context, '/receitas');
          break;
        case 'contas':
          Navigator.pushReplacementNamed(context, '/contas');
          break;
        case 'contas_pagar':
          Navigator.pushReplacementNamed(context, '/contas_pagar');
          break;
        case 'orcamentos':
          Navigator.pushReplacementNamed(context, '/orcamentos');
          break;
        case 'centros':
          Navigator.pushReplacementNamed(context, '/centros');
          break;
        case 'dre':
          Navigator.pushReplacementNamed(context, '/dre');
          break;
        case 'balanco':
          Navigator.pushReplacementNamed(context, '/relatorios/balanco');
          break;
        case 'fluxo':
          Navigator.pushReplacementNamed(context, '/relatorios/fluxo');
          break;
        case 'reconciliacao':
          Navigator.pushReplacementNamed(context, '/reconciliacao');
          break;
        case 'categorias':
          Navigator.pushReplacementNamed(context, '/categorias');
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
