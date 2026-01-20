import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/cloud_backup_service.dart';

/// Settings screen with language, theme, privacy, backup, and about options.
class AgroSettingsScreen extends StatefulWidget {
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

  /// App specific route handler for properties management
  final VoidCallback? onNavigateToProperties;

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
    this.onNavigateToProperties,
  });

  @override
  State<AgroSettingsScreen> createState() => _AgroSettingsScreenState();
}

class _AgroSettingsScreenState extends State<AgroSettingsScreen> {
  bool _isBackingUp = false;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _loadLastBackupInfo();
  }

  Future<void> _loadLastBackupInfo() async {
    final metadata = await CloudBackupService.instance.getLastBackupMetadata();
    if (metadata != null && metadata.updated != null && mounted) {
      setState(() {
        _lastBackupDate = DateFormat.yMd().add_Hm().format(metadata.updated!);
      });
    }
  }

  Future<void> _handleBackup() async {
    setState(() => _isBackingUp = true);
    final scaffold = ScaffoldMessenger.of(context);
    final l10n =
        AgroLocalizations.of(context); // Assuming keys exist or using fallback

    try {
      await CloudBackupService.instance.backupAll();
      await _loadLastBackupInfo();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Backup realizado com sucesso!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Erro no backup: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isBackingUp = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await CloudBackupService.instance.restoreAll();
      scaffold.showSnackBar(
        const SnackBar(content: Text('Dados restaurados com sucesso!')),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('Erro na restauração: $e')),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

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

  Future<void> _showThemeDialog(BuildContext context) async {
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

  Future<void> _showTimePicker(BuildContext context) async {
    final initialTime =
        widget.reminderTime ?? const TimeOfDay(hour: 18, minute: 0);
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
      widget.onReminderChanged?.call(true, selectedTime);
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              // Language option
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.settingsLanguage),
                subtitle:
                    Text(_getLanguageLabel(context, widget.currentLocale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onChangeLocale != null
                    ? () => _showLanguageDialog(context)
                    : null,
              ),
              const Divider(),
              // Theme option
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Tema / Theme'),
                subtitle:
                    Text(_getThemeModeLabel(context, widget.currentThemeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onChangeThemeMode != null
                    ? () => _showThemeDialog(context)
                    : null,
              ),
              const Divider(),
              // Notifications Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Notificações / Notifications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active_outlined),
                title: const Text('Lembrete Diário / Daily Reminder'),
                subtitle: Text(
                  widget.reminderEnabled
                      ? 'Diariamente às ${_formatTime(widget.reminderTime)} / Daily at ${_formatTime(widget.reminderTime)}'
                      : 'Desativado / Disabled',
                ),
                value: widget.reminderEnabled,
                onChanged: (value) {
                  if (value) {
                    final time = widget.reminderTime ??
                        const TimeOfDay(hour: 18, minute: 0);
                    widget.onReminderChanged?.call(true, time);
                  } else {
                    widget.onReminderChanged?.call(false, null);
                  }
                },
              ),
              if (widget.reminderEnabled)
                ListTile(
                  leading: const SizedBox(width: 24), // Indent
                  title: const Text('Horário / Time'),
                  subtitle: Text(_formatTime(widget.reminderTime)),
                  trailing: const Icon(Icons.edit),
                  onTap: () => _showTimePicker(context),
                ),

              const Divider(),

              // Cloud Backup Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Backup em Nuvem / Cloud Backup',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('Fazer Backup Agora'),
                subtitle: Text(_lastBackupDate != null
                    ? 'Último: $_lastBackupDate'
                    : 'Nunca realizado'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleBackup,
              ),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('Restaurar Backup'),
                subtitle: const Text('Substitui dados locais'),
                trailing: const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange),
                onTap: _handleRestore,
              ),

              const Divider(),

              // Privacy & Data section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Privacidade e Dados / Privacy & Data',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Manage consents
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Gerenciar Consentimentos / Manage Consents'),
                trailing: const Icon(Icons.chevron_right),
                onTap: widget.onNavigateToPrivacy,
              ),
              const Divider(),
              // Property & Talhão management (Phase 19)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.settingsManagement,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.landscape),
                title: Text(l10n.settingsPropertiesAndTalhoes),
                subtitle: Text(l10n.settingsPropertiesAndTalhoesDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (widget.onNavigateToProperties != null) {
                    widget.onNavigateToProperties!();
                  } else {
                    Navigator.pushNamed(context, '/properties');
                  }
                },
              ),
              // Cloud sync toggle (Existing preference)
              SwitchListTile(
                secondary: const Icon(Icons.cloud_sync),
                title: const Text('Sincronizar Preferências / Sync Prefs'),
                subtitle: const Text(
                  'Tema e configurações básicas',
                ),
                value: widget.cloudSyncEnabled,
                onChanged: widget.onToggleCloudSync,
              ),
              // Export data (LGPD)
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Exportar Meus Dados / Export My Data'),
                subtitle: const Text('LGPD/GDPR - Portabilidade'),
                onTap: widget.onExportData,
              ),
              // Delete cloud data
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[700]),
                title: Text(
                  'Deletar Dados da Nuvem / Delete Cloud Data',
                  style: TextStyle(color: Colors.red[700]),
                ),
                subtitle: const Text('Mantém dados locais / Keeps local data'),
                onTap: widget.onDeleteCloudData,
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
          if (_isBackingUp)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
