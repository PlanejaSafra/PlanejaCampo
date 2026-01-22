import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../utils/location_helper.dart';
import 'package:geolocator/geolocator.dart';

import '../l10n/generated/app_localizations.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../services/property_service.dart';
import 'agro_privacy_keys.dart';
import 'agro_privacy_store.dart';
import '../services/notification_service.dart';

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
  // Option 1: Backup (Default: TRUE)
  bool _cloudBackup = true;
  // Option 2: Social (Default: FALSE)
  bool _socialNetwork = false;
  // Option 3: Intelligence (Default: FALSE)
  bool _aggregateMetrics = false;

  bool _isProcessing = false;

  /// Check if any consent is selected
  bool get _hasAnyConsent =>
      _cloudBackup || _socialNetwork || _aggregateMetrics;

  /// Smart "Chameleon Button":
  /// - If NO checkboxes are marked: "Accept ALL and Continue" (accepts everything)
  /// - If ANY checkbox is marked: "Confirm My Selection" (respects user choices)
  Future<void> _handlePrimaryButton() async {
    final l10n = AgroLocalizations.of(context)!;
    setState(() => _isProcessing = true);

    try {
      // 1. Save Consents FIRST
      if (!_hasAnyConsent) {
        // Scenario A: No checkboxes marked → Accept ALL
        await AgroPrivacyStore.acceptAllConsents();
      } else {
        // Scenario B: User made manual selections
        await AgroPrivacyStore.setConsent(
          AgroPrivacyKeys.consentCloudBackup,
          _cloudBackup,
        );
        await AgroPrivacyStore.setConsent(
          AgroPrivacyKeys.consentSocialNetwork,
          _socialNetwork,
        );
        await AgroPrivacyStore.setConsent(
          AgroPrivacyKeys.consentAggregateMetrics,
          _aggregateMetrics,
        );

        // Legacy/Implicit mapping
        // If social is active, we might imply partners/ads?
        // For compliance, let's keep legacy keys enabled if Social is enabled,
        // OR just keep them false if not explicitly asked.
        // Let's set legacy keys to match SocialNetwork for now, as that's the closest proxy.
        await AgroPrivacyStore.setConsent(
          AgroPrivacyKeys.consentSharePartners,
          _socialNetwork,
        );
        await AgroPrivacyStore.setConsent(
          AgroPrivacyKeys.consentAdsPersonalization,
          _socialNetwork, // Or _aggregateMetrics? User didn't specify. Safe bet: Social.
        );
      }

      // 2. Ensure Property Exists
      final property =
          await PropertyService().ensureDefaultProperty(l10n: l10n);

      // 3. Trigger Location Prompt (if consented)
      // We check the store directly since we just saved it.
      if (AgroPrivacyStore.consentAggregateMetrics) {
        if (mounted) {
          await LocationHelper.checkAndUpdateLocation(
            context: context,
            propertyId: property.id,
          );
        }
      }

      // 4. Request Notification Permissions (Core feature for rain alerts)
      // We ask here so the user is set up for alerts from the start.
      await AgroNotificationService().init();
      await AgroNotificationService().requestPermissions();

      await AgroPrivacyStore.setOnboardingCompleted(true);
      widget.onCompleted?.call();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // _requestAndSaveLocation removed as it is replaced by LocationHelper

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
    // Ensure a default property exists (even without location) so the app is usable
    final l10n = AgroLocalizations.of(context)!;
    await PropertyService().ensureDefaultProperty(l10n: l10n);

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
                      // Option 1: Cloud Backup
                      _ConsentTile(
                        title: l10n.consentOption1Title,
                        subtitle: l10n.consentOption1Desc,
                        legalText: l10n.consentOption1Legal,
                        value: _cloudBackup,
                        onChanged: (v) => setState(() {
                          _cloudBackup = v ?? false;
                        }),
                      ),
                      const SizedBox(height: 8),

                      // Option 2: Business Network
                      _ConsentTile(
                        title: l10n.consentOption2Title,
                        subtitle: l10n.consentOption2Desc,
                        legalText: l10n.consentOption2Legal,
                        value: _socialNetwork,
                        onChanged: (v) => setState(() {
                          _socialNetwork = v ?? false;
                        }),
                      ),
                      const SizedBox(height: 8),

                      // Option 3: Intelligence
                      _ConsentTile(
                        title: l10n.consentOption3Title,
                        subtitle: l10n.consentOption3Desc,
                        legalText: l10n.consentOption3Legal,
                        value: _aggregateMetrics,
                        onChanged: (v) => setState(() {
                          _aggregateMetrics = v ?? false;
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isProcessing ? null : _handlePrimaryButton,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
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
                    TextSpan(text: l10n.consentFooterPrefix),
                    TextSpan(
                      text: l10n.identityTermsLink,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showTermsOfUse,
                    ),
                    TextSpan(text: l10n.consentFooterConnector),
                    TextSpan(
                      text: l10n.identityPrivacyLink,
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w500,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = _showPrivacyPolicy,
                    ),
                    TextSpan(text: l10n.consentFooterSuffix),
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
  final String? legalText;
  final bool value;
  final ValueChanged<bool?> onChanged;

  const _ConsentTile({
    required this.title,
    required this.subtitle,
    this.legalText,
    required this.value,
    required this.onChanged,
  });

  void _showLegalInfo(BuildContext context) {
    if (legalText == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(legalText!),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AgroLocalizations.of(context)!.okButton),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: CheckboxListTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (legalText != null)
              IconButton(
                icon: const Icon(Icons.info_outline, size: 20),
                color: theme.colorScheme.primary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showLegalInfo(context),
              ),
          ],
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Padding(
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
