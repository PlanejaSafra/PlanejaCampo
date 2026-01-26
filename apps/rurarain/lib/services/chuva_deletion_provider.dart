import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';

import 'chuva_service.dart';

/// LGPD-compliant data deletion provider for RuraRain.
///
/// Implements [AppDeletionProvider] for granular deletion:
/// - Delete only data with `sourceApp == 'rurarain'`
/// - Respect cross-app dependencies via [DependencyService]
/// - Support ownership-based deletion (farm owner vs member)
///
/// See CORE-77 Section 9 and RAIN-03 for architecture.
class ChuvaDeletionProvider implements AppDeletionProvider {
  static const String _appId = 'rurarain';

  @override
  String get appId => _appId;

  /// Delete all RuraRain data for a specific farm.
  ///
  /// Only deletes entities where `sourceApp == 'rurarain'`.
  /// Respects cross-app dependencies — skips protected entities.
  ///
  /// [farmId]: The farm whose data to delete (maps to propertyId).
  /// [userId]: The user requesting deletion (for audit).
  /// [isOwner]: Whether the user is the farm owner (full rights).
  @override
  Future<LgpdDeletionResult> deleteAppData({
    required String farmId,
    required String userId,
    required bool isOwner,
  }) async {
    if (!isOwner) {
      // Non-owners cannot delete farm data
      return const LgpdDeletionResult(
        success: false,
        errors: ['Only the farm owner can delete farm data'],
      );
    }

    final service = ChuvaService();

    int deletedCount = 0;
    int skippedCount = 0;
    final deletedDetails = <String>[];
    final skippedDetails = <String>[];
    final errors = <String>[];

    // ─────────────────────────────────────────────────────────────────────────
    // Delete Rainfall Records
    // ─────────────────────────────────────────────────────────────────────────
    final recordsToDelete = service
        .listarTodos(propertyId: farmId)
        .where((r) => r.sourceApp == _appId || r.sourceApp == 'rurarain')
        .toList();

    for (final record in recordsToDelete) {
      // Check cross-app dependencies
      if (DependencyService.instance.isInitialized) {
        final check = await DependencyService.instance.canDelete(
          entityType: 'registro_chuva',
          entityId: record.id.toString(),
          requestingApp: _appId,
        );

        if (!check.canDelete) {
          skippedCount++;
          skippedDetails.add(
            'Registro ${record.milimetros}mm '
            '${record.data.day}/${record.data.month}/${record.data.year}: '
            '${check.summary}',
          );
          continue;
        }
      }

      try {
        await service.excluir(record.id);
        deletedCount++;
        deletedDetails.add(
          'Registro ${record.milimetros}mm - '
          '${record.data.day}/${record.data.month}/${record.data.year}',
        );
      } catch (e) {
        errors.add('Failed to delete record ${record.id}: $e');
      }
    }

    debugPrint('[ChuvaDeletion] Deleted $deletedCount, '
        'skipped $skippedCount, errors ${errors.length}');

    return LgpdDeletionResult(
      success: errors.isEmpty,
      deletedCount: deletedCount,
      skippedCount: skippedCount,
      deletedDetails: deletedDetails,
      skippedDetails: skippedDetails,
      errors: errors,
    );
  }

  /// Delete only personal data for a non-owner user.
  ///
  /// For RuraRain, rainfall data is farm-centric:
  /// - Records belong to the property/farm, not the user
  /// - The `createdBy` audit trail is preserved (belongs to farm owner)
  /// - Non-owners can't delete farm data — it belongs to the owner
  @override
  Future<LgpdDeletionResult> deletePersonalData({
    required String userId,
  }) async {
    // RuraRain data is property-centric
    // Non-owners can't delete rainfall data — it belongs to the property owner
    debugPrint('[ChuvaDeletion] Personal data deletion: '
        'No personal-only data in RuraRain');

    return const LgpdDeletionResult(
      success: true,
      deletedCount: 0,
      skippedCount: 0,
      deletedDetails: [],
      skippedDetails: [
        'RuraRain data belongs to the property owner. '
            'Contact the property owner to request deletion.',
      ],
    );
  }
}
