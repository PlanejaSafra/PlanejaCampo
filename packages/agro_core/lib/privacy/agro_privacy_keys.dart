/// Centralized keys for privacy settings stored in Hive box "agro_settings".
class AgroPrivacyKeys {
  AgroPrivacyKeys._();

  /// Box name for privacy settings.
  static const String boxName = 'agro_settings';

  /// Whether user has accepted terms of use and privacy policy.
  static const String acceptedTerms = 'accepted_terms';

  /// Consent for data usage and market intelligence (including commercialization,
  /// sale, and licensing of individual or aggregated data to third parties in any sector).
  /// Maps to "Option 3" in new LGPD flow.
  static const String consentAggregateMetrics = 'consent_aggregate_metrics';

  /// Consent for Cloud Backup and Sync.
  /// Maps to "Option 1" in new LGPD flow.
  static const String consentCloudBackup = 'consent_cloud_backup';

  /// Consent for Business Network and Social features.
  /// Maps to "Option 2" in new LGPD flow.
  static const String consentSocialNetwork = 'consent_social_network';

  /// Legacy: Consent for receiving commercial offers from partners.
  static const String consentSharePartners = 'consent_share_partners';

  /// Legacy: Consent for personalized advertising.
  static const String consentAdsPersonalization = 'consent_ads_personalization';

  /// Whether onboarding flow has been completed.
  static const String onboardingCompleted = 'onboarding_completed';

  /// Timestamp of when consent was given or rejected.
  static const String consentTimestamp = 'consent_timestamp';

  /// Whether auto backup on app start is enabled.
  static const String autoBackupEnabled = 'auto_backup_enabled';
}
