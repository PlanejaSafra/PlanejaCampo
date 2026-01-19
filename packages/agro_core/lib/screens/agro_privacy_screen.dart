import 'package:flutter/gestures.dart';
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

  Future<void> _acceptAll() async {
    if (!_hasAnyConsent) {
      // Scenario A: No checkboxes marked → Accept ALL
      await AgroPrivacyStore.acceptAllConsents();
      setState(() {
        _shareAggregated = true;
        _receiveMetrics = true;
        _personalizedAds = true;
      });
    } else {
      // Scenario B: User made manual selections → Just save them
      // (already saved by individual switches via _saveConsent)
      // Just need to ensure all are properly persisted
      await AgroPrivacyStore.setConsent(
        'consent_aggregate_metrics',
        _shareAggregated,
      );
      await AgroPrivacyStore.setConsent(
        'consent_share_partners',
        _receiveMetrics,
      );
      await AgroPrivacyStore.setConsent(
        'consent_ads_personalization',
        _personalizedAds,
      );
    }

    if (mounted) {
      final l10n = AgroLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.privacySaved),
          duration: const Duration(seconds: 1),
        ),
      );
      // Close the screen after saving
      Navigator.pop(context);
    }
  }

  Future<void> _declineAll() async {
    await AgroPrivacyStore.rejectAllConsents();
    setState(() {
      _shareAggregated = false;
      _receiveMetrics = false;
      _personalizedAds = false;
    });

    if (mounted) {
      final l10n = AgroLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.privacySaved),
          duration: const Duration(seconds: 1),
        ),
      );
      // Close the screen after saving
      Navigator.pop(context);
    }
  }

  void _showTermsOfUse() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const TermsOfUseScreen(),
      ),
    );
  }

  void _showPrivacyPolicy() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  /// Check if any consent is selected
  bool get _hasAnyConsent => _shareAggregated || _receiveMetrics || _personalizedAds;

  /// Returns dynamic button text based on user selection
  String _getPrimaryButtonText(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    if (!_hasAnyConsent) {
      return l10n.acceptAllButton;
    } else {
      return l10n.confirmSelectionButton;
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
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    // Consents section header
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
              ),
            ),
            const SizedBox(height: 16),
            // Fixed buttons at bottom
            ElevatedButton(
              onPressed: _acceptAll,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _getPrimaryButtonText(context),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _declineAll,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(l10n.declineLabel),
            ),
            const SizedBox(height: 24),
            // Terms and Privacy links
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                children: [
                  const TextSpan(text: 'Você pode revisar nossos '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _showTermsOfUse,
                  ),
                  const TextSpan(text: ' e '),
                  TextSpan(
                    text: 'Políticas de Privacidade',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = _showPrivacyPolicy,
                  ),
                  const TextSpan(text: ' a qualquer momento.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
    final theme = Theme.of(context);

    return Card(
      child: SwitchListTile(
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            style: theme.textTheme.bodySmall,
          ),
        ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}
