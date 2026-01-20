import 'package:flutter/foundation.dart';

import '../privacy/agro_privacy_keys.dart';
import '../privacy/agro_privacy_store.dart';
import 'property_service.dart';
import 'talhao_service.dart';

/// Callback for reporting migration progress.
/// [step] is the current step name, [current] is the current progress, [total] is the total steps.
typedef MigrationProgressCallback = void Function(
    String step, int current, int total);

/// Service responsible for handling data migrations and initialization
/// of defaults for new features (like Privacy).
///
/// Also handles user data migration when merging anonymous accounts
/// with Google accounts (credential-already-in-use scenarios).
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

  /// Transfer all user data from one account to another.
  ///
  /// Used when:
  /// 1. Anonymous user links with Google and gets "credential-already-in-use"
  /// 2. User signs into existing Google account and wants to merge anonymous data
  ///
  /// Transfers:
  /// - Properties (PropertyService)
  /// - Talhões (TalhaoService)
  /// - App-specific data via registered callbacks
  ///
  /// [oldUserId] - The anonymous user's UID (data source)
  /// [newUserId] - The Google account's UID (data destination)
  /// [onProgress] - Optional callback for UI progress updates
  /// [appDataTransferCallbacks] - App-specific transfer functions (e.g., rainfall records)
  Future<MigrationResult> transferAllData(
    String oldUserId,
    String newUserId, {
    MigrationProgressCallback? onProgress,
    List<Future<void> Function(String, String)>? appDataTransferCallbacks,
  }) async {
    if (oldUserId == newUserId) {
      return MigrationResult(success: true, message: 'Same user, no migration needed');
    }

    final errors = <String>[];
    int currentStep = 0;
    final totalSteps = 2 + (appDataTransferCallbacks?.length ?? 0);

    try {
      // Step 1: Transfer Properties
      currentStep++;
      onProgress?.call('properties', currentStep, totalSteps);
      try {
        await PropertyService().transferData(oldUserId, newUserId);
        debugPrint('Migration: Properties transferred successfully');
      } catch (e) {
        errors.add('Properties: $e');
        debugPrint('Migration Error (Properties): $e');
      }

      // Step 2: Transfer Talhões
      currentStep++;
      onProgress?.call('talhoes', currentStep, totalSteps);
      try {
        await TalhaoService().transferData(oldUserId, newUserId);
        debugPrint('Migration: Talhões transferred successfully');
      } catch (e) {
        errors.add('Talhões: $e');
        debugPrint('Migration Error (Talhões): $e');
      }

      // Step 3+: App-specific data (rainfall records, etc.)
      if (appDataTransferCallbacks != null) {
        for (final callback in appDataTransferCallbacks) {
          currentStep++;
          onProgress?.call('app_data', currentStep, totalSteps);
          try {
            await callback(oldUserId, newUserId);
          } catch (e) {
            errors.add('App data: $e');
            debugPrint('Migration Error (App data): $e');
          }
        }
      }

      // Determine result
      if (errors.isEmpty) {
        return MigrationResult(
          success: true,
          message: 'All data transferred successfully',
        );
      } else {
        return MigrationResult(
          success: false,
          message: 'Some data could not be transferred',
          errors: errors,
        );
      }
    } catch (e) {
      debugPrint('Migration Error (Fatal): $e');
      return MigrationResult(
        success: false,
        message: 'Migration failed: $e',
        errors: [...errors, e.toString()],
      );
    }
  }
}

/// Result of a data migration operation.
class MigrationResult {
  final bool success;
  final String message;
  final List<String> errors;

  MigrationResult({
    required this.success,
    required this.message,
    this.errors = const [],
  });
}
