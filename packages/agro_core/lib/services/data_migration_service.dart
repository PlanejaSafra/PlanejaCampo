import 'package:flutter/foundation.dart';
// import 'package:hive_flutter/hive_flutter.dart'; // Box is used, but maybe via agro_privacy_store? No.
import '../privacy/agro_privacy_keys.dart';
import '../privacy/agro_privacy_store.dart';

/// Service responsible for handling data migrations and initialization
/// of defaults for new features (like Privacy).
class DataMigrationService {
  DataMigrationService._();

  static final DataMigrationService instance = DataMigrationService._();

  /// Run all necessary migrations on app startup.
  Future<void> runMigrations() async {
    try {
      await _migratePrivacyDefaults();
    } catch (e) {
      debugPrint('Error running data migrations: $e');
    }
  }

  /// Ensure privacy keys are initialized.
  /// If keys are missing (first run with this feature), default them to FALSE (opt-out).
  Future<void> _migratePrivacyDefaults() async {
    final box = await AgroPrivacyStore.getBox();

    // Check if migration has already run for version 1.0 (implied by keys existence)
    // For this simple version, we just check if keys exist.

    if (!box.containsKey(AgroPrivacyKeys.consentAggregateMetrics)) {
      debugPrint(
          'Migrating Privacy: Initializing consentAggregateMetrics to false');
      await box.put(AgroPrivacyKeys.consentAggregateMetrics, false);
    }

    if (!box.containsKey(AgroPrivacyKeys.consentSharePartners)) {
      debugPrint(
          'Migrating Privacy: Initializing consentSharePartners to false');
      await box.put(AgroPrivacyKeys.consentSharePartners, false);
    }

    if (!box.containsKey(AgroPrivacyKeys.consentAdsPersonalization)) {
      debugPrint(
          'Migrating Privacy: Initializing consentAdsPersonalization to false');
      await box.put(AgroPrivacyKeys.consentAdsPersonalization, false);
    }
  }
}
