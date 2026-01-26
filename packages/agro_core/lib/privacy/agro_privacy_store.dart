import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/consent_data.dart';
import '../services/user_cloud_service.dart';
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
    final val = _safeBox.get(AgroPrivacyKeys.acceptedTerms, defaultValue: false)
        as bool;
    // debugPrint('[AgroPrivacyStore] hasAcceptedTerms: $val'); // Too noisy
    return val;
  }

  /// Set whether user has accepted terms.
  static Future<void> setAcceptedTerms(bool value) async {
    debugPrint('[AgroPrivacyStore] setAcceptedTerms: $value');
    await _safeBox.put(AgroPrivacyKeys.acceptedTerms, value);
  }

  /// Check if onboarding flow has been completed.
  static bool isOnboardingCompleted() {
    return _safeBox.get(AgroPrivacyKeys.onboardingCompleted,
        defaultValue: false) as bool;
  }

  /// Set onboarding as completed.
  static Future<void> setOnboardingCompleted(bool value) async {
    await _safeBox.put(AgroPrivacyKeys.onboardingCompleted, value);
  }

  /// Get consent for aggregate metrics (Option 3).
  static bool get consentAggregateMetrics {
    return _safeBox.get(
      AgroPrivacyKeys.consentAggregateMetrics,
      defaultValue: false,
    ) as bool;
  }

  /// Get consent for cloud backup (Option 1).
  static bool get consentCloudBackup {
    final val = _safeBox.get(
      AgroPrivacyKeys.consentCloudBackup,
      defaultValue: false,
    ) as bool;
    // debugPrint('[AgroPrivacyStore] get consentCloudBackup: $val');
    return val;
  }

  /// Get consent for social network (Option 2).
  static bool get consentSocialNetwork {
    return _safeBox.get(
      AgroPrivacyKeys.consentSocialNetwork,
      defaultValue: false,
    ) as bool;
  }

  /// Get consent for sharing with partners (Legacy).
  static bool get consentSharePartners {
    return _safeBox.get(
      AgroPrivacyKeys.consentSharePartners,
      defaultValue: false,
    ) as bool;
  }

  /// Get consent for ads personalization (Legacy).
  static bool get consentAdsPersonalization {
    return _safeBox.get(
      AgroPrivacyKeys.consentAdsPersonalization,
      defaultValue: false,
    ) as bool;
  }

  // ========== CORE-35: Getters Granulares ==========

  /// Check if app can collect analytics (requires aggregateMetrics consent).
  static bool get canCollectAnalytics => consentAggregateMetrics;

  /// Check if app can use location for weather/stats (requires aggregateMetrics consent).
  static bool get canUseLocation {
    final val = consentAggregateMetrics;
    debugPrint('[AgroPrivacyStore] canUseLocation: $val');
    return val;
  }

  /// Check if app can show personalized ads (requires adsPersonalization consent).
  static bool get canShowPersonalizedAds => consentAdsPersonalization;

  /// Check if app can share data with partners (requires sharePartners consent).
  static bool get canShareWithPartners => consentSharePartners;

  /// Get a Listenable that notifies when location consent changes.
  /// Use with ValueListenableBuilder to rebuild UI reactively.
  static ValueListenable<Box> get locationConsentListenable {
    return _safeBox.listenable(keys: [AgroPrivacyKeys.consentAggregateMetrics]);
  }

  /// Get a Listenable that notifies when any consent changes.
  static ValueListenable<Box> get allConsentsListenable {
    return _safeBox.listenable(keys: [
      AgroPrivacyKeys.consentCloudBackup,
      AgroPrivacyKeys.consentSocialNetwork,
      AgroPrivacyKeys.consentAggregateMetrics,
    ]);
  }

  // ========== PROPERTY NAME PROMPT ==========

  /// Check if the user has already acknowledged the property name prompt.
  static bool isPropertyNamePrompted() {
    return _safeBox.get(
      AgroPrivacyKeys.propertyNamePrompted,
      defaultValue: false,
    ) as bool;
  }

  /// Mark the property name prompt as acknowledged.
  static Future<void> setPropertyNamePrompted(bool value) async {
    await _safeBox.put(AgroPrivacyKeys.propertyNamePrompted, value);
  }

  // ========== AUTO BACKUP ==========

  /// Check if auto backup on app start is enabled.
  /// Defaults to true - automatic backup is enabled by default.
  static bool get autoBackupEnabled {
    return _safeBox.get(
      AgroPrivacyKeys.autoBackupEnabled,
      defaultValue: true,
    ) as bool;
  }

  /// Set auto backup on app start.
  static Future<void> setAutoBackupEnabled(bool value) async {
    await _safeBox.put(AgroPrivacyKeys.autoBackupEnabled, value);
  }

  // =================================================

  /// Accept all consents and save timestamp.
  /// Enables: Backup, Social, Intelligence.
  static Future<void> acceptAllConsents() async {
    debugPrint('[AgroPrivacyStore] acceptAllConsents() called');

    await _safeBox.put(AgroPrivacyKeys.consentCloudBackup, true);
    await _safeBox.put(AgroPrivacyKeys.consentSocialNetwork, true);
    await _safeBox.put(AgroPrivacyKeys.consentAggregateMetrics, true);

    // Legacy mapping (implicit accept)
    await _safeBox.put(AgroPrivacyKeys.consentSharePartners, true);
    await _safeBox.put(AgroPrivacyKeys.consentAdsPersonalization, true);

    await _safeBox.put(
      AgroPrivacyKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );

    // Verify values were saved
    debugPrint('[AgroPrivacyStore] After save - consentAggregateMetrics: ${_safeBox.get(AgroPrivacyKeys.consentAggregateMetrics)}');
    debugPrint('[AgroPrivacyStore] After save - consentCloudBackup: ${_safeBox.get(AgroPrivacyKeys.consentCloudBackup)}');

    // Sync to Firestore
    await _syncConsentsToCloud();
    debugPrint('[AgroPrivacyStore] acceptAllConsents() completed');
  }

  /// Reject all consents and save timestamp.
  static Future<void> rejectAllConsents() async {
    await _safeBox.put(AgroPrivacyKeys.consentCloudBackup, false);
    await _safeBox.put(AgroPrivacyKeys.consentSocialNetwork, false);
    await _safeBox.put(AgroPrivacyKeys.consentAggregateMetrics, false);

    await _safeBox.put(AgroPrivacyKeys.consentSharePartners, false);
    await _safeBox.put(AgroPrivacyKeys.consentAdsPersonalization, false);

    await _safeBox.put(
      AgroPrivacyKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );

    // Sync to Firestore
    await _syncConsentsToCloud();
  }

  /// Get the timestamp when consent was last updated.
  static String? get consentTimestamp {
    return _safeBox.get(AgroPrivacyKeys.consentTimestamp) as String?;
  }

  /// Reset all privacy settings (for testing or user request).
  static Future<void> resetAll() async {
    await _safeBox.clear();
  }

  /// Get the Hive box for direct access (use sparingly).
  static Future<Box> getBox() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
    return _safeBox;
  }

  /// Set a specific consent value.
  static Future<void> setConsent(String key, bool value) async {
    debugPrint('[AgroPrivacyStore] setConsent $key = $value');
    await _safeBox.put(key, value);
    await _safeBox.put(
      AgroPrivacyKeys.consentTimestamp,
      DateTime.now().toIso8601String(),
    );

    // Sync to Firestore
    await _syncConsentsToCloud();
  }

  /// Sync consents to Firestore (fire-and-forget)
  static Future<void> _syncConsentsToCloud() async {
    debugPrint('[AgroPrivacyStore] _syncConsentsToCloud() called');
    try {
      final cloudService = UserCloudService.instance;
      final userData = cloudService.getCurrentUserData();
      if (userData == null) {
        debugPrint('[AgroPrivacyStore] userData is null, skipping cloud sync');
        return; // Not initialized yet
      }

      final consents = ConsentData(
        termsAccepted: hasAcceptedTerms(),
        termsVersion: '1.0',
        acceptedAt: consentTimestamp != null
            ? DateTime.parse(consentTimestamp!)
            : DateTime.now(),
        aggregateMetrics: consentAggregateMetrics,
        sharePartners: consentSharePartners,
        adsPersonalization: consentAdsPersonalization,
        cloudBackup: consentCloudBackup,
        socialNetwork: consentSocialNetwork,
        consentVersion: '1.1', // Bump version for LGPD 2.0
      );

      await cloudService.updateConsents(consents);
      debugPrint('[AgroPrivacyStore] Cloud sync completed');
    } catch (e) {
      debugPrint('[AgroPrivacyStore] Cloud sync FAILED: $e');
      // Silently fail - user is offline-first
    }
  }
}
