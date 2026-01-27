import 'dart:io';

import 'package:agro_core/agro_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/user_preferences.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';

/// App-specific settings screen that extends core settings with reminder options.
class ConfiguracoesScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAbout;
  final void Function(Locale?)? onChangeLocale;
  final Locale? currentLocale;
  final void Function(ThemeMode)? onChangeThemeMode;
  final ThemeMode currentThemeMode;
  final UserPreferences preferences;
  final void Function(bool, TimeOfDay?)? onReminderChanged;
  final VoidCallback? onRestoreComplete;

  const ConfiguracoesScreen({
    super.key,
    this.onNavigateToAbout,
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
    required this.preferences,
    this.onReminderChanged,
    this.onRestoreComplete,
  });

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late bool _reminderEnabled;
  late String _reminderTime;
  bool _rainAlertsEnabled = false;

  /// Whether the current user is the owner of the active farm.
  /// Controls visibility of backup/export/LGPD features in settings.
  bool get _isOwner {
    final farm = FarmService.instance.getDefaultFarm();
    final uid = AuthService.currentUser?.uid ?? '';
    if (farm == null || uid.isEmpty) return true; // Safe default
    return farm.isOwner(uid);
  }

  @override
  void initState() {
    super.initState();
    _reminderEnabled = widget.preferences.reminderEnabled;
    _reminderTime = widget.preferences.reminderTime ?? '18:00';
    _loadRainAlerts();
  }

  Future<void> _loadRainAlerts() async {
    final enabled = await BackgroundService().isRainAlertsEnabled();
    if (mounted) setState(() => _rainAlertsEnabled = enabled);
  }

  Future<void> _handleReminderChange(bool enabled, TimeOfDay? time) async {
    if (enabled) {
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

    // Determine time to save
    String timeString = _reminderTime;
    if (time != null) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      timeString = '$hour:$minute';
    }

    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = timeString;
    });

    if (widget.onReminderChanged != null) {
      widget.onReminderChanged!(enabled, time);
    } else {
      // Fallback: Save locally
      widget.preferences.reminderEnabled = enabled;
      widget.preferences.reminderTime = timeString;
      await widget.preferences.saveToBox();
      await NotificationService.updateFromPreferences(widget.preferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parse current time string to TimeOfDay for the widget
    final parts = _reminderTime.split(':');
    final timeOfDay = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final isOwner = _isOwner;

    return AgroSettingsScreen(
      isOwner: isOwner,
      onNavigateToAbout: widget.onNavigateToAbout,
      onChangeLocale: widget.onChangeLocale,
      currentLocale: widget.currentLocale,
      onChangeThemeMode: widget.onChangeThemeMode,
      currentThemeMode: widget.currentThemeMode,
      onNavigateToPrivacy: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgroPrivacyScreen(isOwner: isOwner),
          ),
        );
      },
      onToggleCloudSync: (value) async {
        await UserCloudService.instance.setSyncEnabled(value);
        setState(() {});
      },
      cloudSyncEnabled:
          UserCloudService.instance.getCurrentUserData()?.syncEnabled ?? false,

      // Cloud Backup callbacks
      onSignInWithGoogle: () async {
        final l10n = AgroLocalizations.of(context)!;
        try {
          await AuthService.signInWithGoogle();
          if (mounted) setState(() {});
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.errorLogin}: $e')),
            );
          }
        }
      },
      onExportLocalBackup: () async {
        final l10n = AgroLocalizations.of(context)!;
        try {
          await BackupService.exportar();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.backupLocalExportSuccess)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.errorExport}: $e')),
            );
          }
        }
      },
      onImportLocalBackup: () async {
        final l10n = AgroLocalizations.of(context)!;
        try {
          // Pick JSON file
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['json'],
          );

          if (result == null || result.files.isEmpty) return;

          final filePath = result.files.single.path;
          if (filePath == null) return;

          // Read file content
          final file = File(filePath);
          final jsonString = await file.readAsString();

          // Parse and import
          final registros = BackupService.parseBackup(jsonString);
          final importResult = await BackupService.importar(registros);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.backupImportResult(
                      importResult.imported, importResult.duplicates),
                ),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${l10n.errorImport}: $e')),
            );
          }
        }
      },

      // Reminders
      reminderEnabled: _reminderEnabled,
      reminderTime: timeOfDay,

      onReminderChanged: _handleReminderChange,

      // Rain Alerts
      rainAlertsEnabled: _rainAlertsEnabled,
      onToggleRainAlerts: (value) async {
        setState(() => _rainAlertsEnabled = value);
        if (value) {
          await BackgroundService().enableRainAlerts();
        } else {
          await BackgroundService().disableRainAlerts();
        }
      },

      // Restore complete callback
      onRestoreComplete: widget.onRestoreComplete,

      // Branding
      appLogoLightPath: 'assets/images/rurarain-icon.png',
      appLogoDarkPath: 'assets/images/rurarain-icon.png',
    );
  }
}
