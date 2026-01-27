import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';

class ConfiguracoesScreen extends StatelessWidget {
  const ConfiguracoesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine if user is owner (usually true for single-user offline app)
    final isOwner = true;

    return AgroSettingsScreen(
      isOwner: isOwner,
      onNavigateToAbout: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AgroAboutScreen(
                    appName: 'RuraCash',
                    version: '1.0.0',
                    // appLogoLightPath: ...
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
