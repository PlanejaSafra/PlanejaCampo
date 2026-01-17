import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Settings screen with language and about options.
class AgroSettingsScreen extends StatelessWidget {
  /// Callback to navigate to the About screen.
  final VoidCallback? onNavigateToAbout;

  const AgroSettingsScreen({
    super.key,
    this.onNavigateToAbout,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // Language option (placeholder for now)
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(l10n.settingsLanguageAuto),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement language selection
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.settingsLanguage}: Auto / PT-BR / EN'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          const Divider(),
          // About the app
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutApp),
            trailing: const Icon(Icons.chevron_right),
            onTap: onNavigateToAbout,
          ),
        ],
      ),
    );
  }
}
