/// Centralized keys for privacy settings stored in Hive box "agro_settings".
class AgroPrivacyKeys {
  AgroPrivacyKeys._();

  /// Box name for privacy settings.
  static const String boxName = 'agro_settings';

  /// Whether user has accepted terms of use and privacy policy.
  static const String acceptedTerms = 'accepted_terms';

  /// Consent for data usage and market intelligence (including commercialization,
  /// sale, and licensing of individual or aggregated data to third parties in any sector).
  static const String consentAggregateMetrics = 'consent_aggregate_metrics';

  /// Consent for receiving commercial offers from partners (any sector including
  /// agribusiness, finance, digital entertainment, retail, etc.) via app, email, SMS, or WhatsApp.
  /// Partners are not curated by PlanejaCampo.
  static const String consentSharePartners = 'consent_share_partners';

  /// Consent for personalized advertising via third-party ad networks (Google Ads, Meta, etc.).
  /// Includes sharing user data for ad targeting and lookalike audience creation.
  static const String consentAdsPersonalization = 'consent_ads_personalization';

  /// Whether onboarding flow has been completed.
  static const String onboardingCompleted = 'onboarding_completed';

  /// Timestamp of when consent was given or rejected.
  static const String consentTimestamp = 'consent_timestamp';
}
