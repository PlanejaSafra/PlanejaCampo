import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/cloud_backup_service.dart';
import '../services/data_export_service.dart';
import '../services/user_cloud_service.dart';
import 'agro_privacy_screen.dart';
import 'agro_about_screen.dart';

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

  /// Callback to sign in with Google (for cloud backup)
  final VoidCallback? onSignInWithGoogle;

  /// Callback to export local backup file
  final VoidCallback? onExportLocalBackup;

  /// Callback to import local backup file
  final VoidCallback? onImportLocalBackup;

  /// Callback to toggle rain alerts
  final void Function(bool)? onToggleRainAlerts;

  /// Whether rain alerts are enabled
  final bool rainAlertsEnabled;

  /// Callback to reset/switch user profile
  final VoidCallback? onResetProfile;

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
    this.onSignInWithGoogle,
    this.onExportLocalBackup,
    this.onImportLocalBackup,
    this.onToggleRainAlerts,
    this.rainAlertsEnabled = false,
    this.onResetProfile,
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

  bool get _isLoggedIn {
    final user = AuthService.currentUser;
    return user != null && !user.isAnonymous;
  }

  bool get _isAnonymous {
    final user = AuthService.currentUser;
    return user != null && user.isAnonymous;
  }

  bool get _cloudSyncEnabled {
    // Use widget value if explicitly set/tracked by app, otherwise fetch from service
    return UserCloudService.instance.getCurrentUserData()?.syncEnabled ?? false;
  }

  Future<void> _loadLastBackupInfo() async {
    if (!_isLoggedIn) return;

    final metadata = await CloudBackupService.instance.getLastBackupMetadata();
    if (metadata?.updated != null && mounted) {
      setState(() {
        _lastBackupDate = DateFormat.yMd().add_Hm().format(metadata!.updated!);
      });
    }
  }

  Future<void> _handleSignInWithGoogle() async {
    final l10n = AgroLocalizations.of(context)!;
    final scaffold = ScaffoldMessenger.of(context);
    try {
      await AuthService.signInWithGoogle();
      if (mounted) setState(() {});
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text('${l10n.errorLogin}: $e')),
      );
    }
  }

  void _handleNavigateToPrivacy() {
    if (widget.onNavigateToPrivacy != null) {
      widget.onNavigateToPrivacy!.call();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AgroPrivacyScreen()),
      );
    }
  }

  void _handleNavigateToAbout() {
    if (widget.onNavigateToAbout != null) {
      widget.onNavigateToAbout!.call();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AgroAboutScreen(
            appName: 'PlanejaCampo',
            version: '1.0.0',
          ),
        ),
      );
    }
  }

  Future<void> _handleExportData() async {
    if (widget.onExportData != null) {
      widget.onExportData!.call();
      return;
    }

    final l10n = AgroLocalizations.of(context)!;
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await DataExportService.instance.shareExport(asCsv: false);
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportDataSuccess)),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('${l10n.exportDataError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleDeleteCloudData() async {
    if (widget.onDeleteCloudData != null) {
      widget.onDeleteCloudData!.call();
      return;
    }

    final l10n = AgroLocalizations.of(context)!;
    final scaffold = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCloudDataTitle),
        content: Text(l10n.deleteCloudDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await UserCloudService.instance.deleteCloudData();
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.deleteCloudDataSuccess)),
      );
    }
  }

  Future<void> _handleToggleCloudSync(bool value) async {
    if (widget.onToggleCloudSync != null) {
      widget.onToggleCloudSync!.call(value);
    } else {
      await UserCloudService.instance.setSyncEnabled(value);
      if (mounted) setState(() {});
    }
  }

  Future<void> _handleBackup() async {
    final l10n = AgroLocalizations.of(context)!;

    if (!_isLoggedIn) {
      // Prompt to sign in
      if (widget.onSignInWithGoogle != null) {
        widget.onSignInWithGoogle!.call();
      } else {
        await _handleSignInWithGoogle();
      }
      return;
    }

    setState(() => _isBackingUp = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await CloudBackupService.instance.backupAll();
      await _loadLastBackupInfo();
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.backupCloudSuccess)),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.backupCloudError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _handleRestore() async {
    final l10n = AgroLocalizations.of(context)!;

    if (!_isLoggedIn) {
      if (widget.onSignInWithGoogle != null) {
        widget.onSignInWithGoogle!.call();
      } else {
        await _handleSignInWithGoogle();
      }
      return;
    }

    setState(() => _isBackingUp = true);
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await CloudBackupService.instance.restoreAll();
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.backupCloudRestoreSuccess)),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.backupCloudRestoreError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  String _getLanguageLabel(BuildContext context, Locale? locale) {
    final l10n = AgroLocalizations.of(context)!;
    if (locale == null) return l10n.settingsLanguageAuto;
    if (locale.languageCode == 'pt') return l10n.languagePortuguese;
    if (locale.languageCode == 'en') return l10n.languageEnglish;
    return l10n.settingsLanguageAuto;
  }

  String _getThemeModeLabel(BuildContext context, ThemeMode mode) {
    final l10n = AgroLocalizations.of(context)!;
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeAuto;
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
              title: Text(l10n.languagePortuguese),
              subtitle: const Text('🇧🇷'),
              value: const Locale('pt', 'BR'),
              groupValue: widget.currentLocale,
              onChanged: (value) {
                widget.onChangeLocale?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<Locale?>(
              title: Text(l10n.languageEnglish),
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
    final l10n = AgroLocalizations.of(context)!;

    await showDialog<ThemeMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsTheme),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: Text(l10n.settingsThemeAuto),
              subtitle: Text(l10n.settingsThemeFollowsSystem),
              value: ThemeMode.system,
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) widget.onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.settingsThemeLight),
              subtitle: const Text('☀️'),
              value: ThemeMode.light,
              groupValue: widget.currentThemeMode,
              onChanged: (value) {
                if (value != null) widget.onChangeThemeMode?.call(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: Text(l10n.settingsThemeDark),
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
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.settingsLanguage),
                subtitle:
                    Text(_getLanguageLabel(context, widget.currentLocale)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageDialog(context),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: Text(l10n.settingsTheme),
                subtitle:
                    Text(_getThemeModeLabel(context, widget.currentThemeMode)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showThemeDialog(context),
              ),
              const Divider(),

              // Notifications Section (only show if app provides reminder callback)
              if (widget.onReminderChanged != null ||
                  widget.onToggleRainAlerts != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.settingsNotifications,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (widget.onReminderChanged != null)
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: Text(l10n.settingsDailyReminder),
                    subtitle: Text(
                      widget.reminderEnabled
                          ? l10n.settingsReminderDailyAt(
                              _formatTime(widget.reminderTime))
                          : l10n.settingsReminderDisabled,
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
                if (widget.onReminderChanged != null && widget.reminderEnabled)
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: Text(l10n.settingsReminderTime),
                    subtitle: Text(_formatTime(widget.reminderTime)),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showTimePicker(context),
                  ),
                if (widget.onToggleRainAlerts != null)
                  SwitchListTile(
                    secondary: const Icon(Icons.water_drop_outlined,
                        color: Colors.blue),
                    title: Text(l10n.settingsRainAlerts),
                    subtitle: Text(l10n.settingsRainAlertsDesc),
                    value: widget.rainAlertsEnabled,
                    onChanged: widget.onToggleRainAlerts,
                  ),
                const Divider(),
              ],

              // =============================================
              // CLOUD BACKUP SECTION (Prominent)
              // =============================================
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.cloud, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.backupCloudSection,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Cloud Backup Card
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(
                          l10n.backupCloudDescription,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Not logged in state
                        if (!_isLoggedIn) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isAnonymous
                                        ? l10n.backupCloudAnonymousWarning
                                        : l10n.backupCloudSignInRequired,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _handleSignInWithGoogle,
                              icon: const Icon(Icons.login),
                              label: Text(l10n.backupCloudSignInButton),
                            ),
                          ),
                        ],

                        // Logged in state
                        if (_isLoggedIn) ...[
                          // Last backup info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _lastBackupDate != null
                                      ? l10n.backupCloudLastBackup(
                                          _lastBackupDate!)
                                      : l10n.backupCloudNeverDone,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Backup and Restore buttons
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed:
                                      _isBackingUp ? null : _handleBackup,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: Text(l10n.backupCloudNow),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _isBackingUp ? null : _handleRestore,
                                  icon: const Icon(Icons.cloud_download),
                                  label: Text(l10n.backupCloudRestore),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              // =============================================
              // LOCAL BACKUP SECTION (only show if app provides callbacks)
              // =============================================
              if (widget.onExportLocalBackup != null ||
                  widget.onImportLocalBackup != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    l10n.backupLocalSection,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                if (widget.onExportLocalBackup != null)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.save_alt, size: 20),
                    title: Text(l10n.backupLocalExport),
                    subtitle: Text(l10n.backupLocalExportDesc),
                    onTap: widget.onExportLocalBackup,
                  ),
                if (widget.onImportLocalBackup != null)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.file_upload_outlined, size: 20),
                    title: Text(l10n.backupLocalImport),
                    subtitle: Text(l10n.backupLocalImportDesc),
                    onTap: widget.onImportLocalBackup,
                  ),
                const Divider(),
              ],

              // Privacy & Data section header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.settingsPrivacyData,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Manage consents
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(l10n.settingsManageConsents),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleNavigateToPrivacy,
              ),

              const Divider(),

              // Property & Talhão management
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  l10n.settingsManagement,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              // Cloud sync toggle
              SwitchListTile(
                secondary: const Icon(Icons.cloud_sync),
                title: Text(l10n.settingsSyncPrefs),
                subtitle: Text(l10n.settingsSyncPrefsDesc),
                value: _cloudSyncEnabled,
                onChanged: _handleToggleCloudSync,
              ),

              // Switch Profile
              if (widget.onResetProfile != null)
                ListTile(
                  leading: const Icon(Icons.switch_account),
                  title: Text(l10n.settingsResetProfile),
                  subtitle: Text(l10n.settingsResetProfileDesc),
                  onTap: widget.onResetProfile,
                ),

              // Export data (LGPD)
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: Text(l10n.settingsExportMyData),
                subtitle: Text(l10n.settingsExportMyDataDesc),
                onTap: _handleExportData,
              ),

              // Delete cloud data
              ListTile(
                leading: Icon(Icons.delete_outline, color: Colors.red[700]),
                title: Text(
                  l10n.settingsDeleteCloudData,
                  style: TextStyle(color: Colors.red[700]),
                ),
                subtitle: Text(l10n.settingsDeleteCloudDataDesc),
                onTap: _handleDeleteCloudData,
              ),

              const Divider(),

              // About the app
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.settingsAboutApp),
                trailing: const Icon(Icons.chevron_right),
                onTap: _handleNavigateToAbout,
              ),

              const SizedBox(height: 24),
            ],
          ),

          // Loading overlay
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
