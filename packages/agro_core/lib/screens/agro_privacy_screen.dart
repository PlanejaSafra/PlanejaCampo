import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../l10n/generated/app_localizations.dart';
import '../privacy/agro_privacy_store.dart';
import '../services/data_deletion_service.dart';
import '../services/data_export_service.dart';
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
    debugPrint('[AgroPrivacyScreen] _loadConsents - aggregate=$_shareAggregated, partners=$_receiveMetrics, ads=$_personalizedAds');
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

  // ===================== LGPD FEATURES =====================

  /// Show export data bottom sheet (CORE-37)
  void _showExportSheet() {
    final l10n = AgroLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.exportDataTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.exportDataDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.code),
                title: Text(l10n.exportDataJson),
                subtitle: Text(l10n.exportJsonSubtitle),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleExport(asCsv: false);
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: Text(l10n.exportDataCsv),
                subtitle: Text(l10n.exportCsvSubtitle),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleExport(asCsv: true);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleExport({required bool asCsv}) async {
    final l10n = AgroLocalizations.of(context)!;
    final scaffold = ScaffoldMessenger.of(context);

    try {
      await DataExportService.instance.shareExport(asCsv: asCsv);
      scaffold.showSnackBar(
        SnackBar(content: Text(l10n.exportDataSuccess)),
      );
    } catch (e) {
      scaffold.showSnackBar(
        SnackBar(
          content: Text('${l10n.exportDataError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show delete data confirmation dialog (CORE-36)
  void _showDeleteDialog() {
    final l10n = AgroLocalizations.of(context)!;
    bool confirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.deleteDataTitle)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.deleteDataWarning,
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: confirmed,
                onChanged: (value) {
                  setDialogState(() => confirmed = value ?? false);
                },
                title: Text(
                  l10n.deleteDataConfirmCheckbox,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.deleteDataCancel),
            ),
            ElevatedButton(
              onPressed: confirmed
                  ? () async {
                      Navigator.pop(context);
                      await _handleDeleteData();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.deleteDataConfirm),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteData() async {
    final l10n = AgroLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    final scaffold = ScaffoldMessenger.of(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(l10n.deletingData),
          ],
        ),
      ),
    );

    try {
      final success = await DataDeletionService.instance.deleteAllUserData();

      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      if (success) {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.deleteDataSuccess),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to initial route (login)
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.deleteDataError),
            backgroundColor: Colors.red,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      if (e.code == 'requires-recent-login') {
        scaffold.showSnackBar(
          SnackBar(
            content: Text(l10n.deleteDataReauthRequired),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        scaffold.showSnackBar(
          SnackBar(
            content: Text('${l10n.deleteDataError}: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      navigator.pop(); // Close loading dialog

      scaffold.showSnackBar(
        SnackBar(
          content: Text('${l10n.deleteDataError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Revoke all consents and sign out (CORE-35)
  Future<void> _revokeAllAndSignOut() async {
    final l10n = AgroLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeAllTitle),
        content: Text(l10n.revokeAllMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.deleteDataCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.revokeAllButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await AgroPrivacyStore.rejectAllConsents();
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      }
    }
  }

  // ===========================================================

  /// Check if any consent is selected
  bool get _hasAnyConsent =>
      _shareAggregated || _receiveMetrics || _personalizedAds;

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
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Share aggregated data
                    _ConsentSwitch(
                      icon: Icons.analytics_outlined,
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
                      icon: Icons.share_location_outlined,
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
                      icon: Icons.campaign_outlined,
                      title: l10n.consentPersonalizedAds,
                      subtitle: l10n.consentPersonalizedAdsDesc,
                      value: _personalizedAds,
                      onChanged: (value) {
                        setState(() => _personalizedAds = value);
                        _saveConsent('consent_ads_personalization', value);
                      },
                    ),

                    // LGPD Data Rights Section
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      l10n.lgpdRightsTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.lgpdRightsDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Export data button
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.download_outlined),
                        title: Text(l10n.exportDataButton),
                        subtitle: Text(l10n.exportJsonOrCsv),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showExportSheet,
                      ),
                    ),
                    // Delete data button
                    Card(
                      color: Colors.red[50],
                      child: ListTile(
                        leading: Icon(Icons.delete_forever_outlined,
                            color: Colors.red[700]),
                        title: Text(
                          l10n.deleteDataButton,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                        subtitle: Text(
                          l10n.deleteDataSubtitle,
                          style: TextStyle(color: Colors.red[400]),
                        ),
                        trailing:
                            Icon(Icons.chevron_right, color: Colors.red[700]),
                        onTap: _showDeleteDialog,
                      ),
                    ),
                    // Revoke all and sign out
                    const SizedBox(height: 8),
                    Card(
                      color: Colors.orange[50],
                      child: ListTile(
                        leading: Icon(Icons.logout, color: Colors.orange[700]),
                        title: Text(
                          l10n.revokeAllButton,
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                        subtitle: Text(
                          l10n.revokeConsentsSubtitle,
                          style: TextStyle(color: Colors.orange[400]),
                        ),
                        trailing: Icon(Icons.chevron_right,
                            color: Colors.orange[700]),
                        onTap: _revokeAllAndSignOut,
                      ),
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
                  TextSpan(text: l10n.consentFooterPrefix),
                  TextSpan(
                    text: l10n.identityTermsLink,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.w500,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _showTermsOfUse,
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Text(
          'v1.0.0', // Could be dynamic
          textAlign: TextAlign.center,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

class _ConsentSwitch extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ConsentSwitch({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: SwitchListTile(
        secondary:
            icon != null ? Icon(icon, color: theme.colorScheme.primary) : null,
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }
}
