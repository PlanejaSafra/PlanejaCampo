import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';

import '../models/registro_chuva.dart';
import 'chuva_service.dart';

/// Enhanced backup provider for RuraRain.
///
/// Implements [EnhancedBackupProvider] for 3-phase restore:
/// 1. Analysis: Compare backup data with local data
/// 2. Confirmation: Show user what will change
/// 3. Execution: Apply changes selectively by sourceApp
///
/// See CORE-77 and RAIN-03 for architecture.
class ChuvaBackupProvider implements EnhancedBackupProvider {
  static const String _appId = 'rurarain';
  static const int _schemaVersion = 2; // Version 2 includes FarmOwnedMixin fields
  static const String _appVersion = '1.0.0';

  @override
  String get key => 'rura_rain';

  @override
  String get appId => _appId;

  @override
  int get schemaVersion => _schemaVersion;

  @override
  BackupMeta buildMeta() {
    final defaultProperty = PropertyService().getDefaultProperty();
    final currentUser = AuthService.currentUser;

    return BackupMeta(
      appId: _appId,
      appVersion: _appVersion,
      backupType: 'app',
      backupScope: 'full',
      farmId: defaultProperty?.id ?? '',
      userId: currentUser?.uid ?? '',
      createdAt: DateTime.now(),
      schemaVersion: _schemaVersion,
    );
  }

  @override
  Future<Map<String, dynamic>> getData() async {
    final service = ChuvaService();
    final registros = service.listarTodos();

    return {
      'version': _schemaVersion.toString(),
      'records': registros.map((r) => r.toJson()).toList(),
    };
  }

  @override
  Future<RestoreAnalysis> analyzeRestore(Map<String, dynamic> data) async {
    final service = ChuvaService();
    final localRecords = service.listarTodos();

    // Parse backup records
    final backupRecordsList = data['records'] as List? ?? [];
    final backupRecords = backupRecordsList
        .map((r) => RegistroChuva.fromJson(r as Map<String, dynamic>))
        .toList();

    // Build actions lists
    final toAdd = <RestoreAction>[];
    final toDelete = <RestoreAction>[];

    // Local records with sourceApp = rurarain that will be deleted
    for (final record in localRecords) {
      if (record.sourceApp == _appId || record.sourceApp == 'rurarain') {
        toDelete.add(RestoreAction(
          entityType: 'registro_chuva',
          entityId: record.id.toString(),
          description:
              '${record.milimetros}mm - ${record.data.day}/${record.data.month}/${record.data.year}',
        ));
      }
    }

    // Backup records that will be added
    for (final record in backupRecords) {
      if (record.sourceApp == _appId || record.sourceApp == 'rurarain') {
        toAdd.add(RestoreAction(
          entityType: 'registro_chuva',
          entityId: record.id.toString(),
          description:
              '${record.milimetros}mm - ${record.data.day}/${record.data.month}/${record.data.year}',
        ));
      }
    }

    // Determine farm access
    final farmAccess = await _determineFarmAccess(backupRecords);

    // Build meta from data or create default
    final meta = data['_meta'] != null
        ? BackupMeta.fromJson(data['_meta'] as Map<String, dynamic>)
        : buildMeta();

    // Build analysis
    return RestoreAnalysis(
      meta: meta,
      farmAccess: farmAccess,
      toAdd: toAdd,
      toDelete: toDelete,
      blocked: const {},
      conflicts: const [],
      warnings: _buildWarnings(toDelete.length, toAdd.length),
      recalculations: const [],
    );
  }

  Future<RestoreFarmAccess> _determineFarmAccess(
      List<RegistroChuva> backupRecords) async {
    if (backupRecords.isEmpty) return RestoreFarmAccess.owner;

    // Get unique propertyIds from backup
    final propertyIds = backupRecords.map((r) => r.propertyId).toSet();

    // Check if current user owns or is member of these properties
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return RestoreFarmAccess.noAccess;

    // For RuraRain, propertyId maps to Property, not Farm
    // Check ownership via PropertyService
    final propertyService = PropertyService();
    await propertyService.init();

    for (final propertyId in propertyIds) {
      final property = propertyService.getPropertyById(propertyId);
      if (property != null) {
        // Property exists locally - user has access
        return RestoreFarmAccess.owner;
      }
    }

    // Properties from backup don't exist locally
    // Assume owner access for restore (properties will be created or data associated)
    return RestoreFarmAccess.owner;
  }

  List<String> _buildWarnings(int localCount, int backupCount) {
    final warnings = <String>[];

    if (localCount > backupCount) {
      warnings.add(
          'Você tem $localCount registros locais, mas o backup contém apenas $backupCount.');
    }

    return warnings;
  }

  @override
  Future<void> executeRestore(
    Map<String, dynamic> data,
    RestoreAnalysis analysis,
  ) async {
    if (data['records'] == null) return;

    final service = ChuvaService();
    final localRecords = service.listarTodos();

    // Step 1: Delete ONLY records with sourceApp = 'rurarain'
    int deletedCount = 0;
    for (final record in localRecords) {
      if (record.sourceApp == _appId || record.sourceApp == 'rurarain') {
        await service.excluir(record.id);
        deletedCount++;
      }
    }
    debugPrint('[ChuvaBackup] Deleted $deletedCount rurarain records');

    // Step 2: Import backup records (only rurarain ones)
    final backupRecordsList = data['records'] as List;
    int importedCount = 0;

    for (final r in backupRecordsList) {
      final record = RegistroChuva.fromJson(r as Map<String, dynamic>);

      // Only import records from this app
      if (record.sourceApp == _appId || record.sourceApp == 'rurarain') {
        await service.adicionar(record);
        importedCount++;
      }
    }

    debugPrint(
        '[ChuvaBackup] Restored $importedCount records (sourceApp filter applied)');
  }

  @override
  Future<RecalculationResult> recalculateAfterRestore() async {
    // RuraRain doesn't have complex cross-entity recalculations
    // Just return success
    return RecalculationResult.empty();
  }

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    // Legacy restore method - use full replace for backward compatibility
    if (data['records'] == null) return;

    final recordsList = data['records'] as List;
    final registros = recordsList.map((r) {
      // Handle both old format (without createdBy/sourceApp) and new format
      final json = Map<String, dynamic>.from(r as Map<String, dynamic>);

      // Ensure createdBy and sourceApp have defaults for old backups
      if (!json.containsKey('createdBy')) {
        json['createdBy'] = AuthService.currentUser?.uid ?? '';
      }
      if (!json.containsKey('sourceApp')) {
        json['sourceApp'] = _appId;
      }

      return RegistroChuva.fromJson(json);
    }).toList();

    // CLEAR existing data first (restore = replace, not merge)
    final service = ChuvaService();
    await service.limparTodos();

    // Import backup records
    for (final registro in registros) {
      await service.adicionar(registro);
    }

    debugPrint(
        '[ChuvaBackup] Legacy restore: ${registros.length} records (cleared existing first).');
  }
}
