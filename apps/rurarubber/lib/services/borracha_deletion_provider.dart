import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';

import 'parceiro_service.dart';
import 'entrega_service.dart';

/// LGPD-compliant data deletion provider for RuraRubber.
///
/// Implements [AppDeletionProvider] for granular deletion:
/// - Delete only data with `sourceApp == 'rurarubber'`
/// - Respect cross-app dependencies via [DependencyService]
/// - Support ownership-based deletion (farm owner vs member)
///
/// See CORE-77 Section 9 and RUBBER-24 for architecture.
class BorrachaDeletionProvider implements AppDeletionProvider {
  static const String _appId = 'rurarubber';

  @override
  String get appId => _appId;

  /// Delete all RuraRubber data for a specific farm.
  ///
  /// Only deletes entities where `sourceApp == 'rurarubber'`.
  /// Respects cross-app dependencies — skips protected entities.
  ///
  /// [farmId]: The farm whose data to delete.
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

    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    int deletedCount = 0;
    int skippedCount = 0;
    final deletedDetails = <String>[];
    final skippedDetails = <String>[];
    final errors = <String>[];

    // ─────────────────────────────────────────────────────────────────────────
    // Delete Parceiros
    // ─────────────────────────────────────────────────────────────────────────
    final parceirosToDelete = parceiroService.parceiros
        .where((p) => p.farmId == farmId && p.sourceApp == _appId)
        .toList();

    for (final parceiro in parceirosToDelete) {
      // Check cross-app dependencies
      if (DependencyService.instance.isInitialized) {
        final check = await DependencyService.instance.canDelete(
          entityType: 'parceiro',
          entityId: parceiro.id,
          requestingApp: _appId,
        );

        if (!check.canDelete) {
          skippedCount++;
          skippedDetails.add('Parceiro "${parceiro.nome}": ${check.summary}');
          continue;
        }
      }

      try {
        await parceiroService.deleteParceiro(parceiro.id);
        deletedCount++;
        deletedDetails.add('Parceiro "${parceiro.nome}"');
      } catch (e) {
        errors.add('Failed to delete parceiro ${parceiro.id}: $e');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Delete Entregas
    // ─────────────────────────────────────────────────────────────────────────
    final entregasToDelete = entregaService.entregas
        .where((e) => e.farmId == farmId && e.sourceApp == _appId)
        .toList();

    for (final entrega in entregasToDelete) {
      try {
        await entregaService.deleteEntrega(entrega.id);
        deletedCount++;
        deletedDetails.add(
          'Entrega ${entrega.data.toIso8601String().split('T')[0]}',
        );
      } catch (e) {
        errors.add('Failed to delete entrega ${entrega.id}: $e');
      }
    }

    debugPrint('[BorrachaDeletion] Deleted $deletedCount, '
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
  /// For RuraRubber, "personal data" is limited because:
  /// - Parceiros belong to the farm, not the user
  /// - Entregas belong to the farm, not the user
  ///
  /// The `createdBy` audit trail is preserved (belongs to farm owner).
  /// Only user-specific preferences would be deleted (if any existed).
  @override
  Future<LgpdDeletionResult> deletePersonalData({
    required String userId,
  }) async {
    // RuraRubber doesn't store personal-only data separate from farm data
    // All data is farm-centric with createdBy for audit
    // Non-owners can't delete farm data they created — it belongs to the owner
    debugPrint('[BorrachaDeletion] Personal data deletion: '
        'No personal-only data in RuraRubber');

    return const LgpdDeletionResult(
      success: true,
      deletedCount: 0,
      skippedCount: 0,
      deletedDetails: [],
      skippedDetails: [
        'RuraRubber data belongs to the farm owner. '
            'Contact the farm owner to request deletion.',
      ],
    );
  }
}
