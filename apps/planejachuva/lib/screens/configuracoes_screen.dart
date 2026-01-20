import 'package:agro_core/agro_core.dart';
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

  const ConfiguracoesScreen({
    super.key,
    this.onNavigateToAbout,
    this.onChangeLocale,
    this.currentLocale,
    this.onChangeThemeMode,
    this.currentThemeMode = ThemeMode.system,
    required this.preferences,
    this.onReminderChanged,
  });

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  late bool _reminderEnabled;
  late String _reminderTime;
  bool _rainAlertsEnabled = false;

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

    return AgroSettingsScreen(
      onNavigateToAbout: widget.onNavigateToAbout,
      onChangeLocale: widget.onChangeLocale,
      currentLocale: widget.currentLocale,
      onChangeThemeMode: widget.onChangeThemeMode,
      currentThemeMode: widget.currentThemeMode,
      onNavigateToPrivacy: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AgroPrivacyScreen(),
          ),
        );
      },
      onExportData: () async {
        try {
          await BackupService.exportar();
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao exportar: $e')),
            );
          }
        }
      },
      onDeleteCloudData: () async {
        await UserCloudService.instance.deleteCloudData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dados da nuvem excluídos.')),
          );
        }
      },
      onToggleCloudSync: (value) async {
        await UserCloudService.instance.setSyncEnabled(value);
        setState(() {});
      },
      cloudSyncEnabled:
          UserCloudService.instance.getCurrentUserData()?.syncEnabled ?? false,

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
    );
  }
}
