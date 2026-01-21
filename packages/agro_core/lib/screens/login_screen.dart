import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../privacy/agro_privacy_store.dart';
import '../screens/privacy_policy_screen.dart';
import '../screens/terms_of_use_screen.dart';
import '../services/auth_service.dart';
import '../services/property_service.dart';

/// Login screen with Google Sign-In (official button design).
/// Follows Google Sign-In Branding Guidelines:
/// https://developers.google.com/identity/branding-guidelines
///
/// This screen is reusable across all PlanejaCampo apps (PlanejaChuva, PlanejaBorracha, etc).
/// Each app can customize the icon, name, and description.
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String appName;
  final String appDescription;
  final IconData appIcon;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.appName,
    required this.appDescription,
    required this.appIcon,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = AuthService.currentUser;

      // 1. Check if we need to link (Migration: Anonymous -> Google)
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final user = await AuthService.linkAnonymousToGoogle();
          if (user != null && mounted) {
            await AgroPrivacyStore.setAcceptedTerms(true);
            widget.onLoginSuccess();
          }
          return; // Success
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use') {
            // Conflict: Account already exists.
            // We must sign into the existing account and MIGRATE local data.
            await _handleMergeConflict(currentUser.uid);
            return;
          }
          // Other errors: Rethrow to be caught below
          rethrow;
        }
      }

      // 2. Normal Sign In (No anonymous user or simple login)
      final user = await AuthService.signInWithGoogle();

      if (user != null && mounted) {
        await AgroPrivacyStore.setAcceptedTerms(true);
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleMergeConflict(String oldUserId) async {
    // User has an existing Google account.
    // 1. Sign in to that account (switches auth user)
    // We catch errors here separately to provide better context
    final user = await AuthService.signInWithGoogle();

    if (user != null && mounted) {
      // 2. Migrate/Transfer local data from Old UID to New UID
      // This ensures the anonymous data (e.g. properties) is not "lost"
      // but instead merged into the Google account.
      try {
        await PropertyService().transferData(oldUserId, user.uid);

        await AgroPrivacyStore.setAcceptedTerms(true);
        widget.onLoginSuccess();
      } catch (e) {
        // Migration failed? User is logged in, but data might be split.
        // We log it and let them proceed, or show warning?
        // Ideally we shouldn't block login if migration fails, but data integrity...
        // For now, proceed.
        debugPrint('Migration Error: $e');
        widget.onLoginSuccess();
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInAnonymous();

      if (user != null && mounted) {
        // Mark terms as accepted (user clicked button agreeing to terms)
        await AgroPrivacyStore.setAcceptedTerms(true);
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('network')) {
      return 'Erro de conexão. Verifique sua internet.';
    } else if (error.contains('canceled')) {
      return 'Login cancelado.';
    } else {
      return 'Erro ao fazer login. Tente novamente.';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Icon (specific to each app)
                Icon(
                  widget.appIcon,
                  size: 80,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 24),

                // App Name (specific to each app)
                Text(
                  widget.appName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // App Description (specific to each app)
                Text(
                  widget.appDescription,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Google Sign-In Button (Official Design)
                // Follows Google Branding Guidelines
                Center(
                  child: _GoogleSignInButton(
                    // Removed SizedBox wrap
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                // Divider
                Center(
                  child: SizedBox(
                    width: 240,
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Anonymous Sign-In Button
                Center(
                  child: SizedBox(
                    height: 48, // Increased height for premium feel
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleAnonymousSignIn,
                      icon: const Icon(Icons.person_outline,
                          size: 22), // Slightly larger icon
                      label: const Text(
                        'Continuar sem login',
                        style: TextStyle(
                          fontSize: 20, // Increased to 20px
                          fontWeight: FontWeight.w400, // Removed Bold (Normal)
                          fontFamily: 'Roboto',
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12), // 12px padding explicitly
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Loading Indicator
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  ),

                const SizedBox(height: 16),

                // Info Text with Clickable Links
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    children: [
                      const TextSpan(
                          text: 'Ao continuar, você concorda com nossos '),
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
                        text: 'Política de Privacidade',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _showPrivacyPolicy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits
                _buildBenefitItem(
                  context,
                  Icons.cloud_sync,
                  'Sincronize seus dados entre dispositivos',
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  context,
                  Icons.backup,
                  'Backup automático na nuvem',
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  context,
                  Icons.lock_outline,
                  'Seus dados protegidos e privados',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

/// Official Google Sign-In Button using sign_in_button package
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDarkMode;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Rigid implementation: Always White Background, Dark Text
    // This makes it pop on both Light and Dark themes (Standard Google Style)
    return Container(
      height: 48, // Increased height for premium feel
      // width removed to match child's intrinsic width
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFF747775),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12), // 12px padding left/right
            child: Row(
              mainAxisSize: MainAxisSize.min, // Wrap content width
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.string(
                    '''<svg version="1.1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"></path><path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"></path><path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"></path><path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"></path><path fill="none" d="M0 0h48v48H0z"></path></svg>''',
                  ),
                ),

                const SizedBox(width: 10), // 10px gap between icon and text

                const Flexible(
                  // Use Flexible to prevent overflow if max width hits
                  child: Text(
                    'Entrar com o Google',
                    style: TextStyle(
                      fontSize: 20, // Increased to 20px
                      fontWeight: FontWeight.w400, // Removed Bold (Normal)
                      fontFamily: 'Roboto',
                      color: Color(0xFF1F1F1F),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
