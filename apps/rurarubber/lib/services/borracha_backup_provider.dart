import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/parceiro.dart';
import '../models/entrega.dart';
import '../models/item_entrega.dart';
import 'parceiro_service.dart';
import 'entrega_service.dart';

/// Enhanced backup provider for RuraRubber with dependency-aware restore.
///
/// Implements [EnhancedBackupProvider] for 3-phase restore:
/// - Phase 1 (Analysis): Examine backup, produce [RestoreAnalysis]
/// - Phase 2 (Confirmation): User reviews via [RestoreConfirmationDialog]
/// - Phase 3 (Execution): Apply changes, respecting sourceApp isolation
///
/// Only data with `sourceApp == 'rurarubber'` is affected during restore.
/// Data from other apps (e.g., cross-app references) is preserved.
///
/// See CORE-77 and RUBBER-24 for architecture.
class BorrachaBackupProvider implements EnhancedBackupProvider {
  static const String _appId = 'rurarubber';
  static const int _schemaVersion = 2; // v2 includes FarmOwnedEntity fields

  @override
  String get key => 'rura_rubber';

  @override
  String get appId => _appId;

  @override
  int get schemaVersion => _schemaVersion;

  // ═══════════════════════════════════════════════════════════════════════════
  // BackupMeta
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  BackupMeta buildMeta() {
    final userId = AuthService.currentUser?.uid ?? '';
    final farmId = FarmService.instance.defaultFarmId ?? '';

    return BackupMeta(
      appId: _appId,
      appVersion: '1.0.0',
      backupType: 'app',
      backupScope: _isCurrentUserFarmOwner() ? 'full' : 'personal',
      farmId: farmId,
      userId: userId,
      createdAt: DateTime.now(),
      schemaVersion: _schemaVersion,
    );
  }

  bool _isCurrentUserFarmOwner() {
    if (!FarmService.instance.isInitialized) return false;
    final defaultFarm = FarmService.instance.getDefaultFarm();
    if (defaultFarm == null) return false;
    final userId = AuthService.currentUser?.uid;
    return userId != null && defaultFarm.isOwner(userId);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // getData (Export)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<Map<String, dynamic>> getData() async {
    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    final farmId = FarmService.instance.defaultFarmId ?? '';

    // Filter by farmId and sourceApp
    final parceiros = parceiroService.parceiros
        .where((p) => p.farmId == farmId && p.sourceApp == _appId)
        .map((p) => p.toJson())
        .toList();

    final entregas = entregaService.entregas
        .where((e) => e.farmId == farmId && e.sourceApp == _appId)
        .map((e) => e.toJson())
        .toList();

    return {
      '_meta': buildMeta().toJson(),
      'parceiros': parceiros,
      'entregas': entregas,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 1: Analyze Restore
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<RestoreAnalysis> analyzeRestore(Map<String, dynamic> data) async {
    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    // Parse metadata
    BackupMeta meta;
    if (data['_meta'] != null) {
      meta = BackupMeta.fromJson(data['_meta'] as Map<String, dynamic>);
    } else {
      // Legacy backup without meta — assume same farm/user
      meta = buildMeta();
    }

    // Determine farm access
    final farmAccess = _determineFarmAccess(meta);

    // If no access, return blocked analysis
    if (farmAccess == RestoreFarmAccess.noAccess) {
      return RestoreAnalysis(
        meta: meta,
        farmAccess: farmAccess,
        warnings: [],
      );
    }

    final toAdd = <RestoreAction>[];
    final toDelete = <RestoreAction>[];
    final blocked = <String, DependencyCheckResult>{};
    final warnings = <String>[];
    final recalculations = <String>[];

    final currentFarmId = FarmService.instance.defaultFarmId ?? '';

    // ─────────────────────────────────────────────────────────────────────────
    // Analyze Parceiros
    // ─────────────────────────────────────────────────────────────────────────
    final backupParceiros = <String, Map<String, dynamic>>{};
    if (data['parceiros'] != null) {
      for (final p in data['parceiros'] as List) {
        final pMap = p as Map<String, dynamic>;
        backupParceiros[pMap['id'] as String] = pMap;
      }
    }

    final localParceiros = parceiroService.parceiros
        .where((p) => p.farmId == currentFarmId && p.sourceApp == _appId)
        .toList();

    final localParceiroIds = localParceiros.map((p) => p.id).toSet();
    final backupParceiroIds = backupParceiros.keys.toSet();

    // To add: in backup but not local
    for (final id in backupParceiroIds.difference(localParceiroIds)) {
      final p = backupParceiros[id]!;
      toAdd.add(RestoreAction(
        entityType: 'parceiro',
        entityId: id,
        description: p['nome'] as String? ?? id,
      ));
    }

    // To delete: local but not in backup (only sourceApp = rurarubber)
    for (final id in localParceiroIds.difference(backupParceiroIds)) {
      final p = localParceiros.firstWhere((x) => x.id == id);

      // Check cross-app dependencies
      if (DependencyService.instance.isInitialized) {
        final check = await DependencyService.instance.canDelete(
          entityType: 'parceiro',
          entityId: id,
          requestingApp: _appId,
        );
        if (!check.canDelete) {
          blocked[id] = check;
          continue;
        }
      }

      toDelete.add(RestoreAction(
        entityType: 'parceiro',
        entityId: id,
        description: p.nome,
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Analyze Entregas
    // ─────────────────────────────────────────────────────────────────────────
    final backupEntregas = <String, Map<String, dynamic>>{};
    if (data['entregas'] != null) {
      for (final e in data['entregas'] as List) {
        final eMap = e as Map<String, dynamic>;
        backupEntregas[eMap['id'] as String] = eMap;
      }
    }

    final localEntregas = entregaService.entregas
        .where((e) => e.farmId == currentFarmId && e.sourceApp == _appId)
        .toList();

    final localEntregaIds = localEntregas.map((e) => e.id).toSet();
    final backupEntregaIds = backupEntregas.keys.toSet();

    // To add
    for (final id in backupEntregaIds.difference(localEntregaIds)) {
      final e = backupEntregas[id]!;
      final dataStr = e['data'] as String? ?? '';
      toAdd.add(RestoreAction(
        entityType: 'entrega',
        entityId: id,
        description: 'Entrega $dataStr',
      ));
    }

    // To delete
    for (final id in localEntregaIds.difference(backupEntregaIds)) {
      final e = localEntregas.firstWhere((x) => x.id == id);
      toDelete.add(RestoreAction(
        entityType: 'entrega',
        entityId: id,
        description: 'Entrega ${e.data.toIso8601String().split('T')[0]}',
      ));
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Warnings and Recalculations
    // ─────────────────────────────────────────────────────────────────────────
    if (meta.schemaVersion < _schemaVersion) {
      warnings.add('Backup uses older schema (v${meta.schemaVersion}). '
          'Some fields may be missing.');
    }

    if (toDelete.isNotEmpty || toAdd.isNotEmpty) {
      recalculations.add('Saldo com parceiros');
      recalculations.add('Total de produção');
    }

    return RestoreAnalysis(
      meta: meta,
      farmAccess: farmAccess,
      toAdd: toAdd,
      toDelete: toDelete,
      blocked: blocked,
      warnings: warnings,
      recalculations: recalculations,
    );
  }

  RestoreFarmAccess _determineFarmAccess(BackupMeta meta) {
    final currentUserId = AuthService.currentUser?.uid;
    if (currentUserId == null) return RestoreFarmAccess.noAccess;

    // If backup belongs to a farm, check ownership
    if (meta.farmId.isNotEmpty) {
      final farm = FarmService.instance.getFarmById(meta.farmId);

      if (farm == null) {
        // Farm doesn't exist locally — user might have left the farm
        // Check if the backup was created by this user
        if (meta.userId == currentUserId) {
          // User's own backup, but farm is gone — allow personal restore
          return RestoreFarmAccess.member;
        }
        return RestoreFarmAccess.noAccess;
      }

      if (farm.isOwner(currentUserId)) {
        return RestoreFarmAccess.owner;
      }

      // Not owner but farm exists — member with limited access
      return RestoreFarmAccess.member;
    }

    // Legacy backup without farmId — assume owner
    return RestoreFarmAccess.owner;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase 3: Execute Restore
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> executeRestore(
    Map<String, dynamic> data,
    RestoreAnalysis analysis,
  ) async {
    if (!analysis.canProceed) {
      debugPrint('[BorrachaBackup] Restore blocked: ${analysis.farmAccess}');
      return;
    }

    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    final currentFarmId = FarmService.instance.defaultFarmId ?? '';
    final currentUserId = AuthService.currentUser?.uid ?? '';

    int deletedCount = 0;
    int addedCount = 0;

    // ─────────────────────────────────────────────────────────────────────────
    // Delete entities (only those in analysis.toDelete, not blocked)
    // ─────────────────────────────────────────────────────────────────────────
    final blockedIds = analysis.blocked.keys.toSet();

    for (final action in analysis.toDelete) {
      if (blockedIds.contains(action.entityId)) continue;

      if (action.entityType == 'parceiro') {
        await parceiroService.deleteParceiro(action.entityId);
        deletedCount++;
      } else if (action.entityType == 'entrega') {
        await entregaService.deleteEntrega(action.entityId);
        deletedCount++;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Add entities from backup
    // ─────────────────────────────────────────────────────────────────────────
    final addIds = analysis.toAdd.map((a) => a.entityId).toSet();

    // Parceiros
    if (data['parceiros'] != null) {
      for (final p in data['parceiros'] as List) {
        final pMap = p as Map<String, dynamic>;
        final id = pMap['id'] as String;

        if (!addIds.contains(id)) continue;

        // Create with farmId/createdBy from backup or current context
        final parceiro = Parceiro(
          id: id,
          nome: pMap['nome'] as String,
          percentualPadrao: (pMap['percentualPadrao'] as num).toDouble(),
          telefone: pMap['telefone'] as String?,
          tarefasIds: (pMap['tarefasIds'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [],
          fotoPath: pMap['fotoPath'] as String?,
          farmId: pMap['farmId'] as String? ?? currentFarmId,
          createdBy: pMap['createdBy'] as String? ?? currentUserId,
          createdAt: pMap['createdAt'] != null
              ? DateTime.parse(pMap['createdAt'] as String)
              : DateTime.now(),
          sourceApp: _appId,
        );

        await parceiroService.addParceiro(parceiro);
        addedCount++;
      }
    }

    // Entregas
    if (data['entregas'] != null) {
      final box = await Hive.openBox<Entrega>(EntregaService.boxName);

      for (final e in data['entregas'] as List) {
        final eMap = e as Map<String, dynamic>;
        final id = eMap['id'] as String;

        if (!addIds.contains(id)) continue;

        // Create entrega with correct farmId/sourceApp even for legacy backups
        final entregaWithMeta = Entrega(
          id: id,
          data: DateTime.parse(eMap['data'] as String),
          status: eMap['status'] as String? ?? 'Aberto',
          precoDrc: (eMap['precoDrc'] as num?)?.toDouble(),
          precoUmido: (eMap['precoUmido'] as num?)?.toDouble(),
          compradorId: eMap['compradorId'] as String?,
          itens: (eMap['itens'] as List<dynamic>?)
                  ?.map((item) =>
                      ItemEntrega.fromJson(item as Map<String, dynamic>))
                  .toList() ??
              [],
          farmId: eMap['farmId'] as String? ?? currentFarmId,
          createdBy: eMap['createdBy'] as String? ?? currentUserId,
          createdAt: eMap['createdAt'] != null
              ? DateTime.parse(eMap['createdAt'] as String)
              : DateTime.now(),
          sourceApp: _appId,
        );

        await box.put(id, entregaWithMeta);
        addedCount++;
      }

      // Refresh service
      await entregaService.init();
    }

    debugPrint('[BorrachaBackup] Restore completed: '
        'added $addedCount, deleted $deletedCount, '
        'blocked ${analysis.blockedCount}');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Recalculation
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<RecalculationResult> recalculateAfterRestore() async {
    // RuraRubber doesn't have complex derived data that needs recalculation
    // Partner balances are calculated on-the-fly from entregas
    return RecalculationResult.empty();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Legacy Restore (backwards compatibility)
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    // Use 3-phase restore internally
    final analysis = await analyzeRestore(data);
    await executeRestore(data, analysis);
    await recalculateAfterRestore();
  }
}
