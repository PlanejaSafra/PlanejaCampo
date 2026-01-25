import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/user_cloud_service.dart';
import '../models/consent_data.dart';
import '../privacy/agro_privacy_store.dart';
import '../privacy/onboarding_gate.dart';
import '../screens/login_screen.dart';

/// A reusable generic AuthGate that handles:
/// 1. Authentication check (AuthService)
/// 2. Login Screen (if not authenticated)
/// 3. User Data Initialization (Cloud Service & Consents)
/// 4. Onboarding Gate (Privacy/Terms enforcement)
/// 5. Custom App Migrations (optional callback)
class AgroAuthGate extends StatefulWidget {
  final Widget home;
  final String appName;
  final String appDescription;
  final IconData appIcon;
  final String? appLogoLightPath;
  final String? appLogoDarkPath;

  /// Optional callback to run app-specific migrations or initialization
  /// after the user is authenticated but before showing the home screen.
  final Future<void> Function()? onUserInitialized;

  const AgroAuthGate({
    super.key,
    required this.home,
    required this.appName,
    required this.appDescription,
    required this.appIcon,
    this.appLogoLightPath,
    this.appLogoDarkPath,
    this.onUserInitialized,
  });

  @override
  State<AgroAuthGate> createState() => _AgroAuthGateState();
}

class _AgroAuthGateState extends State<AgroAuthGate> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitializeUser();
  }

  Future<void> _checkAndInitializeUser() async {
    final currentUser = AuthService.currentUser;

    if (currentUser != null) {
      // User is already signed in, initialize their data
      await _initializeUserData();
    }

    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _initializeUserData() async {
    // Run app-specific migrations if provided
    if (widget.onUserInitialized != null) {
      await widget.onUserInitialized!();
    }

    // Initialize or restore cloud data
    final cloudService = UserCloudService.instance;
    final userData = cloudService.getCurrentUserData();
    final currentUser = AuthService.currentUser;

    if (userData == null && currentUser != null) {
      // First time: create initial cloud data
      final consents = ConsentData(
        termsAccepted: AgroPrivacyStore.hasAcceptedTerms(),
        termsVersion: '1.0',
        acceptedAt: DateTime.now(),
        aggregateMetrics: AgroPrivacyStore.consentAggregateMetrics,
        sharePartners: AgroPrivacyStore.consentSharePartners,
        adsPersonalization: AgroPrivacyStore.consentAdsPersonalization,
        consentVersion: '1.0',
      );

      await cloudService.createInitialUserData(
        uid: currentUser.uid,
        consents: consents,
      );
    }

    // Update last active timestamp (fire-and-forget sync)
    await cloudService.updateLastActive();
  }

  Future<void> _handleLoginSuccess() async {
    // Initialize user data after successful login
    await _initializeUserData();

    // Refresh UI
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading while checking auth status
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentUser = AuthService.currentUser;

    if (currentUser == null) {
      // No user signed in, show login screen
      return LoginScreen(
        onLoginSuccess: _handleLoginSuccess,
        appName: widget.appName,
        appDescription: widget.appDescription,
        appIcon: widget.appIcon,
        appLogoLightPath: widget.appLogoLightPath,
        appLogoDarkPath: widget.appLogoDarkPath,
      );
    }

    // User is signed in, show main app wrapped in privacy gate
    return AgroOnboardingGate(
      home: widget.home,
    );
  }
}
