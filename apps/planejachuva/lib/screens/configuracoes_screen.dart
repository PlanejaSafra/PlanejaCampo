import 'package:agro_core/agro_core.dart';
import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../services/notification_service.dart';

/// App-specific settings screen that extends core settings with reminder options.
class ConfiguracoesScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAbout;
  final void Function(Locale?)? onChangeLocale;
  final Locale? currentLocale;
  final void Function(ThemeMode)? onChangeThemeMode;
  final ThemeMode currentThemeMode;
  final UserPreferences preferences;

  const ConfiguracoesScreen({
    super.key,
    this.onNavigateToAbout,
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
    required this.preferences,
  });

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late bool _reminderEnabled;
  late String _reminderTime;

  @override
  void initState() {
    super.initState();
    _reminderEnabled = widget.preferences.reminderEnabled;
    _reminderTime = widget.preferences.reminderTime ?? '18:00';
  }

  String _getLanguageLabel(Locale? locale) {
    final l10n = AgroLocalizations.of(context)!;
    if (locale == null) return l10n.settingsLanguageAuto;
    if (locale.languageCode == 'pt') return 'Português (Brasil)';
    if (locale.languageCode == 'en') return 'English';
    return l10n.settingsLanguageAuto;
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Claro / Light';
      case ThemeMode.dark:
        return 'Escuro / Dark';
      case ThemeMode.system:
        return 'Automático / Auto';
    }
  }

  Future<void> _showLanguageDialog() async {
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
              groupValue: widget.currentLocale,
              onChanged: (value) {
                widget.onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: const Text('Português (Brasil)'),
              subtitle: const Text('🇧🇷'),
              value: const Locale('pt', 'BR'),
              groupValue: widget.currentLocale,
              onChanged: (value) {
                widget.onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: const Text('English'),
              subtitle: const Text('🇺🇸'),
              value: const Locale('en'),
              groupValue: widget.currentLocale,
              onChanged: (value) {
                widget.onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showThemeDialog() async {
    await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tema / Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Automático / Auto'),
              subtitle: const Text('Segue o sistema / Follows system'),
              value: ThemeMode.system,
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) widget.onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Claro / Light'),
              subtitle: const Text('☀️'),
              value: ThemeMode.light,
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) widget.onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Escuro / Dark'),
              subtitle: const Text('🌙'),
              value: ThemeMode.dark,
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) widget.onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleReminder(bool value) async {
    if (value) {
      // Request permission first
      final granted = await NotificationService.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Localizations.localeOf(context).toString().startsWith('pt')
                    ? 'Permissão de notificações negada'
                    : 'Notification permission denied',
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() => _reminderEnabled = value);

    // Save to preferences
    widget.preferences.reminderEnabled = value;
    widget.preferences.reminderTime = _reminderTime;
    await widget.preferences.saveToBox();

    // Update notifications
    await NotificationService.updateFromPreferences(widget.preferences);
  }

  Future<void> _selectTime() async {
    final parts = _reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final newTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() => _reminderTime = newTime);

      // Save to preferences
      widget.preferences.reminderTime = newTime;
      await widget.preferences.saveToBox();

      // Update notifications if enabled
      if (_reminderEnabled) {
        await NotificationService.updateFromPreferences(widget.preferences);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

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
            subtitle: Text(_getLanguageLabel(widget.currentLocale)),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onChangeLocale != null ? _showLanguageDialog : null,
          ),
          const Divider(),
          // Theme option
          ListTile(
            leading: const Icon(Icons.brightness_6),
            title: const Text('Tema / Theme'),
            subtitle: Text(_getThemeModeLabel(widget.currentThemeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onChangeThemeMode != null ? _showThemeDialog : null,
          ),
          const Divider(),
          // Reminder section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              locale.startsWith('pt') ? 'Lembretes' : 'Reminders',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // Enable reminder toggle
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active),
            title: Text(
              locale.startsWith('pt')
                  ? 'Lembrete Diário'
                  : 'Daily Reminder',
            ),
            subtitle: Text(
              locale.startsWith('pt')
                  ? 'Notificação para registrar chuva'
                  : 'Notification to log rainfall',
            ),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
          // Time picker (only visible when enabled)
          if (_reminderEnabled)
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                locale.startsWith('pt') ? 'Horário' : 'Time',
              ),
              subtitle: Text(_reminderTime),
              trailing: const Icon(Icons.chevron_right),
              onTap: _selectTime,
            ),
          const Divider(),
          // About the app
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAboutApp),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onNavigateToAbout,
          ),
        ],
      ),
    );
  }
}
