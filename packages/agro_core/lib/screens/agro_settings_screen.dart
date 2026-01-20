import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Settings screen with language, theme, privacy, and about options.
class AgroSettingsScreen extends StatelessWidget {
  /// Callback to navigate to the About screen.
  final VoidCallback? onNavigateToAbout;

  /// Callback to change app locale.
  final void Function(Locale?)? onChangeLocale;

  /// Current selected locale (null = auto).
  final Locale? currentLocale;

  /// Callback to change app theme mode.
  final void Function(ThemeMode)? onChangeThemeMode;

  /// Current theme mode.
  final ThemeMode currentThemeMode;

  /// Callback to navigate to privacy/consent management screen.
  final VoidCallback? onNavigateToPrivacy;

  /// Callback to export user data (LGPD compliance).
  final VoidCallback? onExportData;

  /// Callback to delete cloud data.
  final VoidCallback? onDeleteCloudData;

  /// Callback to toggle cloud sync.
  final void Function(bool)? onToggleCloudSync;

  /// Whether cloud sync is currently enabled.
  final bool cloudSyncEnabled;

  /// Callback to toggle notifications and set time.
  final void Function(bool enabled, TimeOfDay? time)? onReminderChanged;

  /// Whether daily reminder is enabled.
  final bool reminderEnabled;

  /// Time for the daily reminder.
  final TimeOfDay? reminderTime;

  const AgroSettingsScreen({
    super.key,
    this.onNavigateToAbout,
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
    this.onNavigateToPrivacy,
    this.onExportData,
    this.onDeleteCloudData,
    this.onToggleCloudSync,
    this.cloudSyncEnabled = true,
    this.onReminderChanged,
    this.reminderEnabled = false,
    this.reminderTime,
  });

  String _getLanguageLabel(BuildContext context, Locale? locale) {
    final l10n = AgroLocalizations.of(context)!;
    if (locale == null) return l10n.settingsLanguageAuto;
    if (locale.languageCode == 'pt') return 'Português (Brasil)';
    if (locale.languageCode == 'en') return 'English';
    return l10n.settingsLanguageAuto;
  }

  String _getThemeModeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro / Light';
      case ThemeMode.dark:
        return 'Escuro / Dark';
      case ThemeMode.system:
        return 'Automático / Auto';
    }
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

  Future<void> _showThemeDialog(BuildContext context) async {
    await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema / Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.AxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Automático / Auto'),
              subtitle: const Text('Segue o sistema / Follows system'),
              value: ThemeMode.system,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro / Light'),
              subtitle: const Text('☀️'),
              value: ThemeMode.light,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro / Dark'),
              subtitle: const Text('🌙'),
              value: ThemeMode.dark,
              groupValue: currentThemeMode,
              onChanged: (value) {
                if (value != null) onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final initialTime = reminderTime ?? const TimeOfDay(hour: 18, minute: 0);
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (selectedTime != null) {
      onReminderChanged?.call(true, selectedTime);
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
            onTap: onChangeLocale != null
                ? () => _showLanguageDialog(context)
                : null,
          ),
          const Divider(),
          // Theme option
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Tema / Theme'),
            subtitle: Text(_getThemeModeLabel(context, currentThemeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: onChangeThemeMode != null
                ? () => _showThemeDialog(context)
                : null,
          ),
          const Divider(),
          // Notifications Section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notificações / Notifications',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Lembrete Diário / Daily Reminder'),
            subtitle: Text(
              reminderEnabled
                  ? 'Diariamente às ${_formatTime(reminderTime)} / Daily at ${_formatTime(reminderTime)}'
                  : 'Desativado / Disabled',
            ),
            value: reminderEnabled,
            onChanged: (value) {
              if (value) {
                // If enabling, show time picker if no time set, or just enable
                // UX decision: Just enable with default/last time, let user click to edit
                final time =
                    reminderTime ?? const TimeOfDay(hour: 18, minute: 0);
                onReminderChanged?.call(true, time);
              } else {
                onReminderChanged?.call(false, null);
              }
            },
          ),
          if (reminderEnabled)
            ListTile(
              leading: const SizedBox(width: 24), // Indent
              title: const Text('Horário / Time'),
              subtitle: Text(_formatTime(reminderTime)),
              trailing: const Icon(Icons.edit),
              onTap: () => _showTimePicker(context),
            ),

          const Divider(),
          // Privacy & Data section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Privacidade e Dados / Privacy & Data',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          // Manage consents
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Gerenciar Consentimentos / Manage Consents'),
            trailing: const Icon(Icons.chevron_right),
            onTap: onNavigateToPrivacy,
          ),
          const Divider(),
          // Property & Talhão management (Phase 19)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.settingsManagement,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.landscape),
            title: Text(l10n.settingsPropertiesAndTalhoes),
            subtitle: Text(l10n.settingsPropertiesAndTalhoesDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pushNamed(context, '/properties');
            },
          ),
          // Cloud sync toggle
          SwitchListTile(
            secondary: const Icon(Icons.cloud_sync),
            title: const Text('Sincronizar com a Nuvem / Cloud Sync'),
            subtitle: const Text(
              'Backup automático de preferências / Auto backup preferences',
            ),
            value: cloudSyncEnabled,
            onChanged: onToggleCloudSync,
          ),
          // Export data (LGPD)
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Exportar Meus Dados / Export My Data'),
            subtitle: const Text('LGPD/GDPR - Portabilidade'),
            onTap: onExportData,
          ),
          // Delete cloud data
          ListTile(
            leading: Icon(Icons.delete_outline, color: Colors.red[700]),
            title: Text(
              'Deletar Dados da Nuvem / Delete Cloud Data',
              style: TextStyle(color: Colors.red[700]),
            ),
            subtitle: const Text('Mantém dados locais / Keeps local data'),
            onTap: onDeleteCloudData,
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
