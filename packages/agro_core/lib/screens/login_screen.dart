import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../screens/agro_privacy_screen.dart';
import '../services/auth_service.dart';

/// Login screen with Google Sign-In (official button design).
/// Follows Google Sign-In Branding Guidelines:
/// https://developers.google.com/identity/branding-guidelines
///
/// This screen is reusable across all PlanejaSafra apps (PlanejaChuva, PlanejaBorracha, etc).
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
      final user = await AuthService.signInWithGoogle();

      if (user != null && mounted) {
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

  Future<void> _handleAnonymousSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await AuthService.signInAnonymous();

      if (user != null && mounted) {
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

  void _showPrivacyScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AgroPrivacyScreen(),
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
                _GoogleSignInButton(
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),

                // Anonymous Sign-In Button
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _handleAnonymousSignIn,
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continuar sem login'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                      const TextSpan(text: 'Ao continuar, você concorda com nossos '),
                      TextSpan(
                        text: 'Termos de Uso',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.w500,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = _showPrivacyScreen,
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
                          ..onTap = _showPrivacyScreen,
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

/// Official Google Sign-In Button following Google Branding Guidelines
/// https://developers.google.com/identity/branding-guidelines
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isDarkMode;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Google Brand Colors (Official)
    const googleBlue = Color(0xFF4285F4);
    const googleWhite = Color(0xFFFFFFFF);
    const googleDarkGrey = Color(0xFF757575);

    final backgroundColor = isDarkMode ? googleBlue : googleWhite;
    final textColor = isDarkMode ? googleWhite : googleDarkGrey;
    final borderColor = isDarkMode ? Colors.transparent : Color(0xFFDADADA);

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: isDarkMode ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: borderColor, width: 1),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Logo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: googleWhite,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                ),
              ),
              child: Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 18,
                height: 18,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if image fails to load
                  return const Icon(
                    Icons.login,
                    size: 18,
                    color: Colors.grey,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            // Button Text
            Expanded(
              child: Text(
                'Entrar com o Google',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  letterSpacing: 0.25,
                ),
              ),
            ),
            const SizedBox(width: 48), // Balance the logo padding
          ],
        ),
      ),
    );
  }
}
