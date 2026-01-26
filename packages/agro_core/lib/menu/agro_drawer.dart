import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'agro_drawer_item.dart';

/// Reusable drawer widget for all PlanejaCampo apps.
///
/// Provides standard menu items (Home, Properties, Settings, About)
/// and allows apps to add custom items via [extraItems].
class AgroDrawer extends StatelessWidget {
  /// App name displayed in the drawer header.
  final String appName;

  /// Optional version text displayed below the app name.
  final String? versionText;

  /// Optional profile name displayed as a chip below the version.
  /// Use this for simple text-based profile display (e.g., "Produtor", "Sangrador").
  final String? profileName;

  /// Optional custom widget for profile display.
  /// If provided, this takes precedence over [profileName].
  /// Use this for complex profile indicators (e.g., colored chips, icons).
  final Widget? profileWidget;

  /// Additional menu items specific to the app.
  /// These are rendered before Settings.
  final List<AgroDrawerItem> extraItems;

  /// Additional menu items rendered after Settings (before Privacy/About).
  final List<AgroDrawerItem> afterSettingsItems;

  /// Path to the app logo for light mode (displayed in drawer header).
  final String? appLogoLightPath;

  /// Path to the app logo for dark mode (displayed in drawer header).
  final String? appLogoDarkPath;

  /// Callback when a menu item is selected.
  /// Receives the route key (e.g., 'home', 'settings', 'privacy', 'about').
  final void Function(String routeKey) onNavigate;

  const AgroDrawer({
    super.key,
    required this.appName,
    this.versionText,
    this.profileName,
    this.profileWidget,
    this.extraItems = const [],
    this.afterSettingsItems = const [],
    this.appLogoLightPath,
    this.appLogoDarkPath,
    required this.onNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark
                  ? const Color(
                      0xFF334B40) // Lighter Dark Green (Previous Body Color)
                  : const Color(0xFF2E7D32), // Primary Green for Light Mode Top
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (appLogoLightPath != null || appLogoDarkPath != null)
                  Image.asset(
                    theme.brightness == Brightness.dark
                        ? (appLogoDarkPath ?? appLogoLightPath!)
                        : (appLogoLightPath ?? appLogoDarkPath!),
                    height: 76,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(
                    Icons.agriculture,
                    size: 48,
                    color: theme.colorScheme.onPrimary,
                  ),
                const SizedBox(height: 8),
                Text(
                  appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.brightness == Brightness.dark
                        ? Colors.white
                        : theme.colorScheme.onPrimary,
                  ),
                ),
                if (versionText != null)
                  Text(
                    versionText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.8)
                          : theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                    ),
                  ),
                // Profile display (chip or custom widget)
                if (profileWidget != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: profileWidget!,
                  )
                else if (profileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Chip(
                      label: Text(
                        profileName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : theme.colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.25),
                      side: BorderSide.none,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
          ),
          // Home
          _DrawerTile(
            icon: Icons.home,
            title: l10n.drawerHome,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.home);
            },
          ),
          // Properties
          _DrawerTile(
            icon: Icons.agriculture,
            title: l10n.drawerProperties,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.properties);
            },
          ),

          // Extra items (app-specific)
          ...extraItems.map((item) => _DrawerTile(
                icon: item.icon,
                title: item.title,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate(item.key);
                },
              )),

          // Settings (Moved below Extra Items)
          _DrawerTile(
            icon: Icons.settings,
            title: l10n.drawerSettings,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.settings);
            },
          ),

          // Items after Settings (e.g., Backup)
          ...afterSettingsItems.map((item) => _DrawerTile(
                icon: item.icon,
                title: item.title,
                onTap: () {
                  Navigator.pop(context);
                  onNavigate(item.key);
                },
              )),

          const Divider(),
          // About
          _DrawerTile(
            icon: Icons.info,
            title: l10n.drawerAbout,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.about);
            },
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }
}
