import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

/// Full Terms of Use screen with complete legal text.
class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n = AgroLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.termsTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jan/2026',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
              context, l10n.termsSection1Title, l10n.termsSection1Body),
          _buildSection(
              context, l10n.termsSection2Title, l10n.termsSection2Body),
          _buildSection(
              context, l10n.termsSection3Title, l10n.termsSection3Body),
          _buildSection(
              context, l10n.termsSection4Title, l10n.termsSection4Body),
          _buildSection(
              context, l10n.termsSection5Title, l10n.termsSection5Body),
          _buildSection(
              context, l10n.termsSection6Title, l10n.termsSection6Body),
          _buildSection(
              context, l10n.termsSection7Title, l10n.termsSection7Body),
          _buildSection(
              context, l10n.termsSection8Title, l10n.termsSection8Body),
          _buildSection(
              context, l10n.termsSection9Title, l10n.termsSection9Body),
          _buildSection(
              context, l10n.termsSection10Title, l10n.termsSection10Body),
          _buildSection(
              context, l10n.termsSection11Title, l10n.termsSection11Body),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Center(
            child: Text(
              '© 2026 PlanejaCampo. Todos os direitos reservados.',
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
