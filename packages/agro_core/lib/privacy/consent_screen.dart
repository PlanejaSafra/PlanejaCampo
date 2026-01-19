import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use_screen.dart';
import 'agro_privacy_keys.dart';
import 'agro_privacy_store.dart';

/// Screen 2: Optional consents.
/// User can accept all, decline all, or skip - all options lead to the app.
class ConsentScreen extends StatefulWidget {
  /// Callback when onboarding is completed (accept or decline).
  final VoidCallback? onCompleted;

  const ConsentScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _aggregateMetrics = false;
  bool _sharePartners = false;
  bool _adsPersonalization = false;

  /// Check if any consent is selected
  bool get _hasAnyConsent => _aggregateMetrics || _sharePartners || _adsPersonalization;

  /// Smart "Chameleon Button":
  /// - If NO checkboxes are marked: "Accept ALL and Continue" (accepts everything)
  /// - If ANY checkbox is marked: "Confirm My Selection" (respects user choices)
  Future<void> _handlePrimaryButton() async {
    if (!_hasAnyConsent) {
      // Scenario A: No checkboxes marked → Accept ALL
      await AgroPrivacyStore.acceptAllConsents();
    } else {
      // Scenario B: User made manual selections → Respect them
      await AgroPrivacyStore.setConsent(
        AgroPrivacyKeys.consentAggregateMetrics,
        _aggregateMetrics,
      );
      await AgroPrivacyStore.setConsent(
        AgroPrivacyKeys.consentSharePartners,
        _sharePartners,
      );
      await AgroPrivacyStore.setConsent(
        AgroPrivacyKeys.consentAdsPersonalization,
        _adsPersonalization,
      );
    }
    await AgroPrivacyStore.setOnboardingCompleted(true);
    widget.onCompleted?.call();
  }

  /// Returns dynamic button text based on user selection
  String _getPrimaryButtonText(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    if (!_hasAnyConsent) {
      return l10n.acceptAllButton;
    } else {
      return l10n.confirmSelectionButton;
    }
  }

  Future<void> _declineAll() async {
    await AgroPrivacyStore.rejectAllConsents();
    await AgroPrivacyStore.setOnboardingCompleted(true);
    widget.onCompleted?.call();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Icon(
                Icons.tune,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.consentTitle,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.consentIntro,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ConsentTile(
                        title: l10n.consentOption1Title,
                        subtitle: l10n.consentOption1Desc,
                        value: _aggregateMetrics,
                        onChanged: (v) => setState(() {
                          _aggregateMetrics = v ?? false;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _ConsentTile(
                        title: l10n.consentOption2Title,
                        subtitle: l10n.consentOption2Desc,
                        value: _sharePartners,
                        onChanged: (v) => setState(() {
                          _sharePartners = v ?? false;
                        }),
                      ),
                      const SizedBox(height: 8),
                      _ConsentTile(
                        title: l10n.consentOption3Title,
                        subtitle: l10n.consentOption3Desc,
                        value: _adsPersonalization,
                        onChanged: (v) => setState(() {
                          _adsPersonalization = v ?? false;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handlePrimaryButton,
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
              // Terms and Privacy links (like in IdentityScreen)
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
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
      ),
    );
  }
}

class _ConsentTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: CheckboxListTile(
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
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
      ),
    );
  }
}
