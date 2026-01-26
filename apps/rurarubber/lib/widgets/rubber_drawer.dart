import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Creates a standardized AgroDrawer for all RuraRubber screens.
///
/// Includes:
/// - Profile display in drawer header (RUBBER-12.1)
/// - Consistent extraItems across all screens (RUBBER-12.3)
/// - Proper app logo paths for About screen (RUBBER-12.5)
AgroDrawer buildRubberDrawer({
  required BuildContext context,
  required BorrachaLocalizations l10n,
}) {
  final profileService = UserProfileService.instance;
  final isSangrador = profileService.isSangrador;

  String? profileLabel;
  if (profileService.hasProfile) {
    switch (profileService.currentProfile!.profileType) {
      case UserProfileType.produtor:
        profileLabel = l10n.profileLabelProdutor;
        break;
      case UserProfileType.comprador:
        profileLabel = l10n.profileLabelComprador;
        break;
      case UserProfileType.sangrador:
        profileLabel = l10n.profileLabelSangrador;
        break;
    }
  }

  return AgroDrawer(
    appName: 'RuraRubber',
    versionText: '1.0.0',
    profileName: profileLabel,
    appLogoLightPath: 'assets/images/rurarubber-icon.png',
    appLogoDarkPath: 'assets/images/rurarubber-icon.png',
    extraItems: [
      AgroDrawerItem(
        icon: Icons.scale,
        title: l10n.drawerPesagem,
        key: 'pesagem',
      ),
      if (!isSangrador)
        AgroDrawerItem(
          icon: Icons.people,
          title: l10n.drawerParceiros,
          key: 'parceiros',
        ),
      AgroDrawerItem(
        icon: Icons.history,
        title: l10n.drawerEntregas,
        key: 'entregas',
      ),
      AgroDrawerItem(
        icon: Icons.store,
        title: l10n.drawerMercado,
        key: 'mercado',
      ),
      AgroDrawerItem(
        icon: Icons.work_outline,
        title: l10n.jobsTitle,
        key: 'jobs',
      ),
      if (!isSangrador)
        AgroDrawerItem(
          icon: Icons.account_balance_wallet,
          title: l10n.recebiveisTitle,
          key: 'recebiveis',
        ),
      if (!isSangrador)
        AgroDrawerItem(
          icon: Icons.receipt_long,
          title: l10n.contasPagarTitle,
          key: 'contas-pagar',
        ),
      if (!isSangrador)
        AgroDrawerItem(
          icon: Icons.analytics,
          title: l10n.breakEvenTitle,
          key: 'break-even',
        ),
    ],
    onNavigate: (route) {
      Navigator.pop(context); // Close drawer first
      switch (route) {
        case 'home':
          Navigator.pushReplacementNamed(context, '/home');
          break;
        case 'properties':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PropertyListScreen()),
          );
          break;
        case 'pesagem':
          Navigator.pushReplacementNamed(context, '/pesagem');
          break;
        case 'parceiros':
          Navigator.pushReplacementNamed(context, '/parceiros');
          break;
        case 'entregas':
          Navigator.pushReplacementNamed(context, '/entregas');
          break;
        case 'mercado':
          Navigator.pushReplacementNamed(context, '/mercado');
          break;
        case 'jobs':
          Navigator.pushReplacementNamed(context, '/jobs');
          break;
        case 'recebiveis':
          Navigator.pushReplacementNamed(context, '/recebiveis');
          break;
        case 'contas-pagar':
          Navigator.pushReplacementNamed(context, '/contas-pagar');
          break;
        case 'break-even':
          Navigator.pushReplacementNamed(context, '/break-even');
          break;
        case 'settings':
          Navigator.pushNamed(context, '/settings');
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
              ),
            ),
          );
          break;
      }
    },
  );
}
