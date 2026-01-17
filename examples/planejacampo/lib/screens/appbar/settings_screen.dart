import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/settings_options.dart';
import 'package:planejacampo/widgets/object_template.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isChangingOfflineMode = false;

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);
    final theme = Theme.of(context);

    // Get the current producer ID
    final String? produtorId = appStateManager.activeProdutorId;

    // Check if user can change offline mode
    final bool canChangeOfflineMode = appStateManager.canChangeOfflineFirstMode();

    // Get current offline mode state
    final bool isOfflineFirstEnabled = appStateManager.isOfflineFirstEnabled;

    // Check if device is online
    final bool isOnline = appStateManager.isOnline;

    // Determine if offline mode toggle should be disabled
    final bool offlineModeDisabled = _isChangingOfflineMode || !canChangeOfflineMode || !isOnline;

    // Obtenha os itens do dropdown para idioma
    final localizedLanguages = SettingsOptions.getLocalizedLanguages(context);
    final dropdownItems = ObjectTemplate.getDropdownMenuItems(
      context,
      localizedLanguages.values.toList(),
    );

    // Use o locale atual do AppStateManager
    final currentLocale = appStateManager.appLocale ?? const Locale('pt', 'BR');
    final currentLocaleString = SettingsOptions.getStringFromLocale(currentLocale);

    // Ajuste o valor para corresponder ao formato dos itens
    String? initialSelectedLocale = localizedLanguages[currentLocaleString];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).settings),
          ),
          body: ListView(
            children: [
              // Dark mode toggle
              SwitchListTile(
                title: Text(
                  S.of(context).dark_mode,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                ),
                value: appStateManager.isDarkMode,
                onChanged: offlineModeDisabled && !isOnline
                    ? null
                    : (value) {
                  appStateManager.toggleDarkMode();
                },
                activeColor: theme.colorScheme.primary,
                activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
                inactiveThumbColor: theme.colorScheme.onSurface,
                inactiveTrackColor: theme.colorScheme.onSurface.withOpacity(0.5),
              ),

              // Language dropdown
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DropdownButtonFormField<String>(
                  decoration: ObjectTemplate.getInputDecoration(context, S.of(context).language),
                  value: initialSelectedLocale,
                  onChanged: offlineModeDisabled && !isOnline
                      ? null
                      : (String? newValue) {
                    if (newValue != null) {
                      final newLocaleString = localizedLanguages.entries
                          .firstWhere((entry) => entry.value == newValue)
                          .key;
                      final newLocale = SettingsOptions.getLocaleFromString(newLocaleString);
                      appStateManager.setLocale(newLocale, true);
                    }
                  },
                  items: dropdownItems,
                  style: Theme.of(context).textTheme.bodyMedium,
                  dropdownColor: Theme.of(context).cardColor,
                ),
              ),

              // Offline-first mode toggle (only shows if user has an active producer)
              if (produtorId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SwitchListTile(
                    title: Text(
                      S.of(context).offline_first_mode,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    ),
                    subtitle: _buildOfflineModeSubtitle(
                        context,
                        theme,
                        isOnline,
                        canChangeOfflineMode,
                        _isChangingOfflineMode
                    ),
                    value: isOfflineFirstEnabled,
                    onChanged: offlineModeDisabled
                        ? null
                        : (value) async {
                      // Verificação adicional de segurança antes de processar a alteração
                      if (!appStateManager.isOnline) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).device_offline_cant_change_mode))
                        );
                        return;
                      }

                      setState(() {
                        _isChangingOfflineMode = true;
                      });

                      try {
                        final success = await appStateManager.setOfflineFirstMode(produtorId, value);

                        if (mounted) {
                          if (!success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(S.of(context).failed_to_change_setting))
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(
                                    value
                                        ? S.of(context).offline_first_enabled_success
                                        : S.of(context).offline_first_disabled_success
                                ))
                            );
                          }
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isChangingOfflineMode = false;
                          });
                        }
                      }
                    },
                    activeColor: theme.colorScheme.primary,
                    activeTrackColor: theme.colorScheme.primary.withOpacity(0.5),
                    inactiveThumbColor: offlineModeDisabled
                        ? theme.colorScheme.onSurface.withOpacity(0.3)
                        : theme.colorScheme.onSurface,
                    inactiveTrackColor: offlineModeDisabled
                        ? theme.colorScheme.onSurface.withOpacity(0.1)
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),

              // Add info icon with tooltip about offline-first mode
              if (produtorId != null)
                _buildOfflineModeInfo(context, theme, appStateManager),
            ],
          ),
        ),

        // Full screen loading indicator
        if (_isChangingOfflineMode)
          _buildLoadingOverlay(context, theme),
      ],
    );
  }

  // Widget para o subtítulo do modo offline-first
  Widget _buildOfflineModeSubtitle(
      BuildContext context,
      ThemeData theme,
      bool isOnline,
      bool canChangeOfflineMode,
      bool isChangingOfflineMode,
      ) {
    if (isChangingOfflineMode) {
      return Text(
        S.of(context).processing_please_wait,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
      );
    } else if (!isOnline) {
      return Text(
        S.of(context).device_offline_mode_unavailable,
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
      );
    } else if (!canChangeOfflineMode) {
      return Text(
        S.of(context).offline_first_mode_locked_description,
        style: theme.textTheme.bodySmall,
      );
    } else {
      return Text(
        S.of(context).offline_first_mode_description,
        style: theme.textTheme.bodySmall,
      );
    }
  }

  // Widget para informações do modo offline-first
  Widget _buildOfflineModeInfo(BuildContext context, ThemeData theme, AppStateManager appStateManager) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              appStateManager.isOfflineFirstEnabled
                  ? S.of(context).offline_first_enabled_info
                  : S.of(context).offline_first_disabled_info,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  // Widget do overlay de carregamento
  Widget _buildLoadingOverlay(BuildContext context, ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 24),
                  Text(
                    S.of(context).synchronizing_data,
                    style: theme.textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Text(
                    S.of(context).this_may_take_a_minute,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}