import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Settings screen with language and about options.
class AgroSettingsScreen extends StatelessWidget {
  /// Callback to navigate to the About screen.
  final VoidCallback? onNavigateToAbout;

  /// Callback to change app locale.
  final void Function(Locale?)? onChangeLocale;

  /// Current selected locale (null = auto).
  final Locale? currentLocale;

  const AgroSettingsScreen({
    super.key,
    this.onNavigateToAbout,
    this.onChangeLocale,
    this.currentLocale,
  });

  String _getLanguageLabel(BuildContext context, Locale? locale) {
    final l10n = AgroLocalizations.of(context)!;
    if (locale == null) return l10n.settingsLanguageAuto;
    if (locale.languageCode == 'pt') return 'Português (Brasil)';
    if (locale.languageCode == 'en') return 'English';
    return l10n.settingsLanguageAuto;
  }

  Future<void> _showLanguageDialog(BuildContext context) async {
    final l10n = AgroLocalizations.of(context)!;

    await showDialog<Locale?>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<Locale?>(
              title: Text(l10n.settingsLanguageAuto),
              subtitle: const Text('🌐'),
              value: null,
              groupValue: currentLocale,
              onChanged: (value) {
                onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: const Text('Português (Brasil)'),
              subtitle: const Text('🇧🇷'),
              value: const Locale('pt', 'BR'),
              groupValue: currentLocale,
              onChanged: (value) {
                onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: const Text('English'),
              subtitle: const Text('🇺🇸'),
              value: const Locale('en'),
              groupValue: currentLocale,
              onChanged: (value) {
                onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          // Language option
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.settingsLanguage),
            subtitle: Text(_getLanguageLabel(context, currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangeLocale != null ? () => _showLanguageDialog(context) : null,
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
