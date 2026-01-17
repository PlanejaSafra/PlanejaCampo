import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/generated/app_localizations.dart';
import 'agro_privacy_store.dart';

/// Screen 1: Terms of Use and Privacy Policy.
/// User must accept to continue to the app.
class TermsPrivacyScreen extends StatelessWidget {
  /// Callback when user accepts terms.
  final VoidCallback? onAccepted;

  const TermsPrivacyScreen({
    super.key,
    this.onAccepted,
  });

  Future<void> _acceptTerms(BuildContext context) async {
    await AgroPrivacyStore.setAcceptedTerms(true);
    onAccepted?.call();
  }

  void _declineAndExit() {
    SystemNavigator.pop();
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
              const Spacer(flex: 1),
              Icon(
                Icons.shield_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.termsTitle,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.termsBodyIntro,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.termsSummaryTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _BulletPoint(text: l10n.termsSummaryItem1),
                      _BulletPoint(text: l10n.termsSummaryItem2),
                      _BulletPoint(text: l10n.termsSummaryItem3),
                      _BulletPoint(text: l10n.termsSummaryItem4),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.termsFooter,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              ElevatedButton(
                onPressed: () => _acceptTerms(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.acceptAndContinueLabel),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _declineAndExit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.declineAndExitLabel),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
