import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import 'agro_drawer_item.dart';

/// Reusable drawer widget for all PlanejaSafra apps.
///
/// Provides standard menu items (Home, Settings, Privacy, About)
/// and allows apps to add custom items via [extraItems].
class AgroDrawer extends StatelessWidget {
  /// App name displayed in the drawer header.
  final String appName;

  /// Optional version text displayed below the app name.
  final String? versionText;

  /// Additional menu items specific to the app.
  /// These are rendered before "About".
  final List<AgroDrawerItem> extraItems;

  /// Callback when a menu item is selected.
  /// Receives the route key (e.g., 'home', 'settings', 'privacy', 'about').
  final void Function(String routeKey) onNavigate;

  const AgroDrawer({
    super.key,
    required this.appName,
    this.versionText,
    this.extraItems = const [],
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
              color: theme.colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.agriculture,
                  size: 48,
                  color: theme.colorScheme.onPrimary,
                ),
                const SizedBox(height: 12),
                Text(
                  appName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                if (versionText != null)
                  Text(
                    versionText!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
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
          // Settings
          _DrawerTile(
            icon: Icons.settings,
            title: l10n.drawerSettings,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.settings);
            },
          ),
          // Privacy
          _DrawerTile(
            icon: Icons.privacy_tip,
            title: l10n.drawerPrivacy,
            onTap: () {
              Navigator.pop(context);
              onNavigate(AgroRouteKeys.privacy);
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
