import 'package:agro_core/agro_core.dart';
import '../services/lancamento_service.dart';
import '../services/centro_custo_service.dart';

class CashDeletionProvider extends AppDeletionProvider {
  @override
  String get appId => 'ruracash';

  @override
  Future<LgpdDeletionResult> deleteAppData({
    required String farmId,
    required String userId,
    required bool isOwner,
  }) async {
    // If user is owner, delete ALL data for this farm from this app.
    // If user is NOT owner, delete ONLY data created by this user in this farm.

    // Note: Core requirement usually says:
    // - Owner can delete EVERYTHING.
    // - Non-owner can only delete THEIR OWN personal data (deletePersonalData),
    //   but NOT farm data they created (it belongs to farm).
    // However, if the method is `deleteAppData` (triggered by farm deletion?),
    // usually it implies we are deleting the farm context.

    // Check DataDeletionService docs:
    // "Delete all data created by this app for a specific farm."
    // "Only deletes entities where sourceApp == appId."

    try {
      final allLancamentos = LancamentoService.instance.getByFarmId(farmId);
      final allCentros = CentroCustoService.instance.getByFarmId(farmId);

      int deletedLancamentos = 0;
      int deletedCentros = 0;

      for (var item in allLancamentos) {
        // If owner, delete all. If not owner, only delete if createdBy matches (if allowed).
        // Usually deleteAppData is called when Deleting the Farm or Deleting the Account (Owner).
        // If isOwner is true, we delete everything for this farm.
        if (isOwner || item.createdBy == userId) {
          await LancamentoService.instance.delete(item.id);
          deletedLancamentos++;
        }
      }

      for (var item in allCentros) {
        if (isOwner || item.createdBy == userId) {
          await CentroCustoService.instance.delete(item.id);
          deletedCentros++;
        }
      }

      return LgpdDeletionResult(
        success: true,
        deletedCount: deletedLancamentos + deletedCentros,
        deletedDetails: [
          'RuraCash: Deleted $deletedLancamentos lancamentos, $deletedCentros centros for farm $farmId'
        ],
      );
    } catch (e) {
      return LgpdDeletionResult(
        success: false,
        errors: ['RuraCash deleteAppData failed: $e'],
      );
    }
  }

  @override
  Future<LgpdDeletionResult> deletePersonalData(
      {required String userId}) async {
    // Delete data that is NOT tied to a specific farm but to the user?
    // In RuraCash, seemingly everything is tied to a farm (even personal farm).
    // If the user deletes their account (`deleteAllUserData`), `deleteAppDataForFarm` is called for every farm?
    // No, `deleteAllUserData` calls `_clearAllLocalData` and Firestore deletion.
    // `deletePersonalDataOnly` calls this.

    // If there is any pure personal data (settings?), delete it here.
    // Currently RuraCash has no independent personal data outside of Hive boxes which are cleared globally.
    // So return empty success.

    return const LgpdDeletionResult(success: true, deletedDetails: [
      'RuraCash: No properties independent data to delete.'
    ]);
  }
}
