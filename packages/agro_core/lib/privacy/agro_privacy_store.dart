import 'package:hive/hive.dart';

import 'agro_privacy_keys.dart';

/// Static store for privacy settings using Hive.
/// All data is stored locally in the "agro_settings" box.
class AgroPrivacyStore {
  AgroPrivacyStore._();

  static Box? _box;

  /// Initialize the privacy store. Must be called after Hive.initFlutter().
  static Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(AgroPrivacyKeys.boxName);
  }

  static Box get _safeBox {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
        'AgroPrivacyStore not initialized. Call AgroPrivacyStore.init() first.',
      );
    }
    return _box!;
  }

  /// Check if user has accepted terms of use and privacy policy.
  static bool hasAcceptedTerms() {
    return _safeBox.get(AgroPrivacyKeys.acceptedTerms, defaultValue: false)
        as bool;
  }

  /// Set whether user has accepted terms.
  static Future<void> setAcceptedTerms(bool value) async {
    await _safeBox.put(AgroPrivacyKeys.acceptedTerms, value);
  }

  /// Check if onboarding flow has been completed.
  static bool isOnboardingCompleted() {
    return _safeBox.get(AgroPrivacyKeys.onboardingCompleted, defaultValue: false)
        as bool;
  }

  /// Set onboarding as completed.
  static Future<void> setOnboardingCompleted(bool value) async {
    await _safeBox.put(AgroPrivacyKeys.onboardingCompleted, value);
  }

  /// Get consent for aggregate metrics.
  static bool get consentAggregateMetrics {
    return _safeBox.get(
      AgroPrivacyKeys.consentAggregateMetrics,
      defaultValue: false,
    ) as bool;
  }

  /// Get consent for sharing with partners.
  static bool get consentSharePartners {
    return _safeBox.get(
      AgroPrivacyKeys.consentSharePartners,
      defaultValue: false,
    ) as bool;
  }

  /// Get consent for ads personalization.
  static bool get consentAdsPersonalization {
    return _safeBox.get(
      AgroPrivacyKeys.consentAdsPersonalization,
      defaultValue: false,
    ) as bool;
  }

  /// Accept all consents and save timestamp.
  static Future<void> acceptAllConsents() async {
    await _safeBox.put(AgroPrivacyKeys.consentAggregateMetrics, true);
    await _safeBox.put(AgroPrivacyKeys.consentSharePartners, true);
    await _safeBox.put(AgroPrivacyKeys.consentAdsPersonalization, true);
    await _safeBox.put(
      AgroPrivacyKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );
  }

  /// Reject all consents and save timestamp.
  static Future<void> rejectAllConsents() async {
    await _safeBox.put(AgroPrivacyKeys.consentAggregateMetrics, false);
    await _safeBox.put(AgroPrivacyKeys.consentSharePartners, false);
    await _safeBox.put(AgroPrivacyKeys.consentAdsPersonalization, false);
    await _safeBox.put(
      AgroPrivacyKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );
  }

  /// Get the timestamp when consent was last updated.
  static String? get consentTimestamp {
    return _safeBox.get(AgroPrivacyKeys.consentTimestamp) as String?;
  }

  /// Reset all privacy settings (for testing or user request).
  static Future<void> resetAll() async {
    await _safeBox.clear();
  }
}
