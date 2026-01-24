import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// About screen showing app information.
class AgroAboutScreen extends StatelessWidget {
  /// App name to display.
  final String appName;

  /// Version string to display.
  final String? version;

  /// Path to the app-specific logo asset.
  final String? appLogoPath;

  /// Path to the suite logo asset.
  final String? suiteLogoPath;

  const AgroAboutScreen({
    super.key,
    required this.appName,
    this.version,
    this.appLogoPath,
    this.suiteLogoPath,
  });

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
            if (appLogoPath != null)
              Image.asset(
                appLogoPath!,
                height: 120,
                fit: BoxFit.contain,
              )
            else
              Icon(
                Icons.agriculture,
                size: 80,
                color: theme.colorScheme.primary,
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
            if (suiteLogoPath != null) ...[
              const SizedBox(height: 16),
              Image.asset(
                suiteLogoPath!,
                height: 80,
                fit: BoxFit.contain,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
