import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  bool _computeIsOwner() {
    final farm = FarmService.instance.getDefaultFarm();
    if (farm == null) return true;
    final uid = AuthService.currentUser?.uid;
    if (uid == null) return true;
    return farm.isOwner(uid);
  }

  @override
  Widget build(BuildContext context) {
    final isOwner = _computeIsOwner();

    return AgroSettingsScreen(
      isOwner: isOwner,
      onNavigateToAbout: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AgroAboutScreen(
                    appName: 'RuraCash',
                    version: '1.0.0',
                  )),
        );
      },
      onNavigateToPrivacy: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AgroPrivacyScreen(isOwner: isOwner)),
        );
      },
    );
  }
}
