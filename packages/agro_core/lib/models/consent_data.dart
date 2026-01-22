import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'consent_data.g.dart';

/// User consent data with versioning for LGPD compliance.
@HiveType(typeId: 11)
class ConsentData extends HiveObject {
  /// Whether user accepted terms of use and privacy policy
  @HiveField(0)
  bool termsAccepted;

  /// Version of terms accepted (e.g., '1.0', '1.1')
  @HiveField(1)
  String termsVersion;

  /// When terms were accepted
  @HiveField(2)
  DateTime acceptedAt;

  /// Optional consent: Aggregate metrics (regional statistics)
  @HiveField(3)
  bool? aggregateMetrics;

  /// Optional consent: Share with partners
  @HiveField(4)
  bool? sharePartners;

  /// Optional consent: Ads personalization
  @HiveField(5)
  bool? adsPersonalization;

  /// Optional consent: Regional statistics (JIT - Just In Time)
  @HiveField(6)
  bool? regionalStats;

  /// Optional consent: Cloud Backup (Option 1)
  @HiveField(8)
  bool? cloudBackup;

  /// Optional consent: Social Network (Option 2)
  @HiveField(9)
  bool? socialNetwork;

  /// Consent version (tracks changes to consent structure)
  @HiveField(7)
  String consentVersion;

  ConsentData({
    required this.termsAccepted,
    required this.termsVersion,
    required this.acceptedAt,
    this.aggregateMetrics,
    this.sharePartners,
    this.adsPersonalization,
    this.regionalStats,
    this.cloudBackup,
    this.socialNetwork,
    this.consentVersion = '1.0',
  });

  /// Convert to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'terms_accepted': termsAccepted,
      'terms_version': termsVersion,
      'accepted_at': Timestamp.fromDate(acceptedAt),
      'consent_aggregate_metrics': aggregateMetrics,
      'consent_share_partners': sharePartners,
      'consent_ads_personalization': adsPersonalization,
      'consent_regional_stats': regionalStats,
      'consent_cloud_backup': cloudBackup,
      'consent_social_network': socialNetwork,
      'consent_version': consentVersion,
    };
  }

  /// Create from Firestore Map
  factory ConsentData.fromMap(Map<String, dynamic> map) {
    return ConsentData(
      termsAccepted: map['terms_accepted'] as bool,
      termsVersion: map['terms_version'] as String,
      acceptedAt: (map['accepted_at'] as Timestamp).toDate(),
      aggregateMetrics: map['consent_aggregate_metrics'] as bool?,
      sharePartners: map['consent_share_partners'] as bool?,
      adsPersonalization: map['consent_ads_personalization'] as bool?,
      regionalStats: map['consent_regional_stats'] as bool?,
      cloudBackup: map['consent_cloud_backup'] as bool?,
      socialNetwork: map['consent_social_network'] as bool?,
      consentVersion: map['consent_version'] as String? ?? '1.0',
    );
  }

  /// Factory for default consents (all rejected)
  factory ConsentData.defaults() {
    return ConsentData(
      termsAccepted: false,
      termsVersion: '1.0',
      acceptedAt: DateTime.now(),
      aggregateMetrics: false,
      sharePartners: false,
      adsPersonalization: false,
      regionalStats: false,
      cloudBackup: false,
      socialNetwork: false,
      consentVersion: '1.0',
    );
  }
}
