import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// Full Privacy Policy screen with complete legal text.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicyScreenTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.privacyPolicyTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyPolicyLastUpdate,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
              context, l10n.privacySection1Title, l10n.privacySection1Body),
          _buildSection(
              context, l10n.privacySection2Title, l10n.privacySection2Body),
          _buildSection(
              context, l10n.privacySection3Title, l10n.privacySection3Body),
          _buildSection(
              context, l10n.privacySection4Title, l10n.privacySection4Body),
          _buildSection(
              context, l10n.privacySection5Title, l10n.privacySection5Body),
          _buildSection(
              context, l10n.privacySection6Title, l10n.privacySection6Body),
          _buildSection(
              context, l10n.privacySection7Title, l10n.privacySection7Body),
          _buildSection(
              context, l10n.privacySection8Title, l10n.privacySection8Body),
          _buildSection(
              context, l10n.privacySection9Title, l10n.privacySection9Body),
          _buildSection(
              context, l10n.privacySection10Title, l10n.privacySection10Body),
          _buildSection(
              context, l10n.privacySection11Title, l10n.privacySection11Body),
          _buildSection(
              context, l10n.privacySection12Title, l10n.privacySection12Body),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.privacyPolicyFooter,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
