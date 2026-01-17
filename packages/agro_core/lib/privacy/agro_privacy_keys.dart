/// Centralized keys for privacy settings stored in Hive box "agro_settings".
class AgroPrivacyKeys {
  AgroPrivacyKeys._();

  /// Box name for privacy settings.
  static const String boxName = 'agro_settings';

  /// Whether user has accepted terms of use and privacy policy.
  static const String acceptedTerms = 'accepted_terms';

  /// Consent for aggregated metrics collection.
  static const String consentAggregateMetrics = 'consent_aggregate_metrics';

  /// Consent for sharing aggregated data with partners.
  static const String consentSharePartners = 'consent_share_partners';

  /// Consent for personalized ads.
  static const String consentAdsPersonalization = 'consent_ads_personalization';

  /// Whether onboarding flow has been completed.
  static const String onboardingCompleted = 'onboarding_completed';

  /// Timestamp of when consent was given or rejected.
  static const String consentTimestamp = 'consent_timestamp';
}
