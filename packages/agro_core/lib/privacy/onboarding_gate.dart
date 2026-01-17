import 'package:flutter/material.dart';

import 'agro_privacy_store.dart';
import 'consent_screen.dart';
import 'terms_privacy_screen.dart';

/// Gate widget that controls privacy onboarding flow.
///
/// Shows:
/// - TermsPrivacyScreen if user hasn't accepted terms
/// - ConsentScreen if terms accepted but onboarding not completed
/// - [home] widget if onboarding is completed
class AgroOnboardingGate extends StatefulWidget {
  /// The home widget to show after onboarding is completed.
  final Widget home;

  const AgroOnboardingGate({
    super.key,
    required this.home,
  });

  @override
  State<AgroOnboardingGate> createState() => _AgroOnboardingGateState();
}

class _AgroOnboardingGateState extends State<AgroOnboardingGate> {
  late bool _hasAcceptedTerms;
  late bool _isOnboardingCompleted;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  void _loadState() {
    _hasAcceptedTerms = AgroPrivacyStore.hasAcceptedTerms();
    _isOnboardingCompleted = AgroPrivacyStore.isOnboardingCompleted();
    setState(() => _isInitialized = true);
  }

  void _onTermsAccepted() {
    setState(() {
      _hasAcceptedTerms = true;
    });
  }

  void _onOnboardingCompleted() {
    setState(() {
      _isOnboardingCompleted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_hasAcceptedTerms) {
      return TermsPrivacyScreen(
        onAccepted: () {
          _onTermsAccepted();
        },
      );
    }

    if (!_isOnboardingCompleted) {
      return ConsentScreen(
        onCompleted: _onOnboardingCompleted,
      );
    }

    return widget.home;
  }
}
