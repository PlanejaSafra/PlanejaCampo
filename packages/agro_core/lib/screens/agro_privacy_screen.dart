import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../privacy/agro_privacy_store.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_use_screen.dart';

/// Privacy and consents management screen.
/// Allows users to view terms summary and manage consent preferences.
class AgroPrivacyScreen extends StatefulWidget {
  const AgroPrivacyScreen({super.key});

  @override
  State<AgroPrivacyScreen> createState() => _AgroPrivacyScreenState();
}

class _AgroPrivacyScreenState extends State<AgroPrivacyScreen> {
  late bool _shareAggregated;
  late bool _receiveMetrics;
  late bool _personalizedAds;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  void _loadConsents() {
    _shareAggregated = AgroPrivacyStore.consentAggregateMetrics;
    _receiveMetrics = AgroPrivacyStore.consentSharePartners;
    _personalizedAds = AgroPrivacyStore.consentAdsPersonalization;
  }

  Future<void> _saveConsent(String key, bool value) async {
    final box = await AgroPrivacyStore.getBox();
    await box.put(key, value);

    if (mounted) {
      final l10n = AgroLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.privacySaved),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Terms section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.privacyTermsSection,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.privacyTermsSummary,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const TermsOfUseScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.article_outlined, size: 18),
                          label: const Text('Termos de Uso'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PrivacyPolicyScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                          label: const Text('Privacidade'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Consents section
          Text(
            l10n.privacyConsentsSection,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.privacyConsentsDescription,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          // Share aggregated data
          _ConsentSwitch(
            title: l10n.consentShareAggregated,
            subtitle: l10n.consentShareAggregatedDesc,
            value: _shareAggregated,
            onChanged: (value) {
              setState(() => _shareAggregated = value);
              _saveConsent('consent_aggregate_metrics', value);
            },
          ),
          // Receive regional metrics
          _ConsentSwitch(
            title: l10n.consentReceiveRegionalMetrics,
            subtitle: l10n.consentReceiveRegionalMetricsDesc,
            value: _receiveMetrics,
            onChanged: (value) {
              setState(() => _receiveMetrics = value);
              _saveConsent('consent_share_partners', value);
            },
          ),
          // Personalized ads
          _ConsentSwitch(
            title: l10n.consentPersonalizedAds,
            subtitle: l10n.consentPersonalizedAdsDesc,
            value: _personalizedAds,
            onChanged: (value) {
              setState(() => _personalizedAds = value);
              _saveConsent('consent_ads_personalization', value);
            },
          ),
        ],
      ),
    );
  }
}

class _ConsentSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
