import 'package:agro_core/agro_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/registro_chuva.dart';

/// Service for data migration between app versions.
/// Handles schema changes and ensures data integrity.
class MigrationService {
  /// Migrate existing rainfall records to the property system.
  ///
  /// This migration:
  /// 1. Ensures a default property exists for the current user
  /// 2. Updates all rainfall records without propertyId to use the default property
  /// 3. Marks the migration as completed to avoid running again
  ///
  /// This is a one-time migration that runs on app startup.
  static Future<void> migrateToPropertySystem() async {
    // Use a dedicated box for migration flags
    final migrationBox = await Hive.openBox('migration_flags');

    // Check if already migrated
    if (migrationBox.get('rainfall_to_property_v1') == true) {
      return; // Already migrated
    }

    try {
      // 1. Ensure default property exists
      final propertyService = PropertyService();
      final defaultProperty = await propertyService.ensureDefaultProperty();

      // 2. Get all rainfall records
      final chuvaBox = await Hive.openBox<RegistroChuva>('registros_chuva');
      final allRecords = chuvaBox.values.toList();

      int migratedCount = 0;

      // 3. Migrate records without propertyId (old schema)
      for (final record in allRecords) {
        // Check if record needs migration (propertyId is empty or null)
        // Note: Old records won't have this field, causing a runtime error when accessed
        // So we use try-catch to detect old records
        bool needsMigration = false;
        try {
          // Try to access propertyId - if it throws, record needs migration
          final _ = record.propertyId;
          // If we get here, propertyId exists - check if it's empty
          if (record.propertyId.isEmpty) {
            needsMigration = true;
          }
        } catch (e) {
          // Field doesn't exist - definitely needs migration
          needsMigration = true;
        }

        if (needsMigration) {
          // Create updated record with propertyId and CORE-77 fields
          final updated = RegistroChuva(
            id: record.id,
            data: record.data,
            milimetros: record.milimetros,
            observacao: record.observacao,
            criadoEm: record.criadoEm,
            propertyId: defaultProperty.id,
            createdBy: record.createdBy,
            sourceApp: record.sourceApp,
          );
          await chuvaBox.put(record.id.toString(), updated);
          migratedCount++;
        }
      }

      // 4. Mark migration as complete
      await migrationBox.put('rainfall_to_property_v1', true);

      // Log migration result (for debugging)
      if (migratedCount > 0) {
        print('[MigrationService] Migrated $migratedCount rainfall records to property system');
      }
    } catch (e) {
      // If migration fails, don't mark as complete so it can retry next time
      print('[MigrationService] ERROR during property system migration: $e');
      rethrow;
    }
  }

  /// Reset all migration flags (for testing only).
  /// DO NOT call this in production code.
  static Future<void> resetMigrationFlags() async {
    final migrationBox = await Hive.openBox('migration_flags');
    await migrationBox.clear();
  }
}
