import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../utils/exit_dialog_helper.dart';
import 'agro_privacy_store.dart';

/// Screen 1: Identity (Google Login or Anonymous).
/// User must choose identity method to enter app.
/// By proceeding, user implicitly accepts Terms & Privacy Policy (shown in footer).
class IdentityScreen extends StatefulWidget {
  /// Callback when identity is established and user can proceed.
  final VoidCallback? onCompleted;

  const IdentityScreen({
    super.key,
    this.onCompleted,
  });

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.signInWithGoogle();

      if (user == null) {
        // User canceled
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(
              AgroLocalizations.of(context)!.identityErrorGoogleCanceled);
        }
        return;
      }

      // Success - mark terms accepted and complete onboarding
      await AgroPrivacyStore.setAcceptedTerms(true);
      if (mounted) {
        widget.onCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(AgroLocalizations.of(context)!.identityErrorGoogleFailed);
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() => _isLoading = true);

    try {
      final user = await AuthService.signInAnonymous();

      if (user == null) {
        // Should not happen, but handle gracefully
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(
              AgroLocalizations.of(context)!.identityErrorAnonymousFailed);
        }
        return;
      }

      // Success - mark terms accepted and complete onboarding
      await AgroPrivacyStore.setAcceptedTerms(true);
      if (mounted) {
        widget.onCompleted?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Check if error is due to no internet
        if (e.toString().contains('network') ||
            e.toString().contains('internet') ||
            e.toString().contains('connection')) {
          _showNoInternetDialog();
        } else {
          _showError(
              AgroLocalizations.of(context)!.identityErrorAnonymousFailed);
        }
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
      ),
    );
  }

  void _showNoInternetDialog() {
    final l10n = AgroLocalizations.of(context)!;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.identityNoInternetTitle),
        content: Text(l10n.identityNoInternetMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleAnonymousSignIn(); // Retry
            },
            child: Text(l10n.identityTryAgain),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) return;
          ExitDialogHelper.showExitConfirmationDialog(context);
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),

                // App Logo (placeholder - replace with actual logo)
                Icon(
                  Icons.agriculture,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  l10n.identityTitle,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Slogan
                Text(
                  l10n.identitySlogan,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Button 1: Google Sign-In (Recommended)
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.login),
                  label: Text(l10n.identityGoogleButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Button 2: Anonymous (Guest)
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleAnonymousSignIn,
                  icon: const Icon(Icons.person_outline),
                  label: Text(l10n.identityAnonymousButton),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),

                const Spacer(flex: 2),

                // Footer: Legal disclaimer
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    children: [
                      TextSpan(text: l10n.identityFooterLegal),
                      // TODO: Add clickable links to Terms and Privacy when needed
                      // For now, these are accessible via Settings → Privacy
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
