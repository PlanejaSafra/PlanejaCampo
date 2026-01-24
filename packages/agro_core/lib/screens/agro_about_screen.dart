import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// About screen showing app information.
class AgroAboutScreen extends StatelessWidget {
  /// App name to display.
  final String appName;

  /// Version string to display.
  final String? version;

  /// Paths to the app-specific logo assets for light and dark modes.
  final String? appLogoLightPath;
  final String? appLogoDarkPath;

  /// Paths to the suite logo assets for light and dark modes.
  final String? suiteLogoLightPath;
  final String? suiteLogoDarkPath;

  const AgroAboutScreen({
    super.key,
    required this.appName,
    this.version,
    this.appLogoLightPath,
    this.appLogoDarkPath,
    this.suiteLogoLightPath,
    this.suiteLogoDarkPath,
    @Deprecated('Use appLogoLightPath and appLogoDarkPath') String? appLogoPath,
    @Deprecated('Use suiteLogoLightPath and suiteLogoDarkPath')
    String? suiteLogoPath,
  })  : _appLogoPath = appLogoPath,
        _suiteLogoPath = suiteLogoPath;

  final String? _appLogoPath;
  final String? _suiteLogoPath;

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            _buildLogo(
              context,
              lightPath: appLogoLightPath,
              darkPath: appLogoDarkPath,
              legacyPath: _appLogoPath,
              height: 120,
              placeholderIcon: Icons.agriculture,
            ),
            const SizedBox(height: 16),
            Text(
              appName,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            if (version != null) ...[
              const SizedBox(height: 8),
              Text(
                '${l10n.aboutVersion}: $version',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      l10n.aboutDescription,
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.offline_bolt,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.aboutOfflineFirst,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.aboutSuite,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (suiteLogoLightPath != null ||
                suiteLogoDarkPath != null ||
                _suiteLogoPath != null) ...[
              const SizedBox(height: 16),
              _buildLogo(
                context,
                lightPath: suiteLogoLightPath,
                darkPath: suiteLogoDarkPath,
                legacyPath: _suiteLogoPath,
                height: 80,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(
    BuildContext context, {
    String? lightPath,
    String? darkPath,
    String? legacyPath,
    required double height,
    IconData? placeholderIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = isDark ? (darkPath ?? lightPath) : (lightPath ?? darkPath);
    final finalPath = path ?? legacyPath;

    if (finalPath != null) {
      return Image.asset(
        finalPath,
        height: height,
        fit: BoxFit.contain,
      );
    }

    if (placeholderIcon != null) {
      return Icon(
        placeholderIcon,
        size: height * 0.66,
        color: Theme.of(context).colorScheme.primary,
      );
    }

    return const SizedBox.shrink();
  }
}
