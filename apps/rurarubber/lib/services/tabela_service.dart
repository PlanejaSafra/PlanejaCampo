import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/tabela_sangria.dart';

/// Service for managing tapping tables (Tabelas de Sangria) in RuraRubber.
/// Migrated to GenericSyncService (CORE-83).
class TabelaService extends GenericSyncService<TabelaSangria> {
  static final TabelaService _instance = TabelaService._internal();
  static TabelaService get instance => _instance;
  TabelaService._internal();
  factory TabelaService() => _instance;

  @override
  String get boxName => 'tabelas_sangria';

  @override
  String get sourceApp => 'rurarubber';

  @override
  bool get syncEnabled => true;

  @override
  TabelaSangria fromMap(Map<String, dynamic> map) =>
      TabelaSangria.fromJson(map);

  @override
  Map<String, dynamic> toMap(TabelaSangria item) => item.toJson();

  @override
  String getId(TabelaSangria item) => item.id;

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
  }

  /// Migra dados antigos (Objetos) para nova estrutura
  Future<void> _migrateDataIfNeeded() async {
    final box = Hive.box(boxName);
    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    if (firstValue is TabelaSangria) {
      debugPrint('[TabelaService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is TabelaSangria) {
          final item = entry.value as TabelaSangria;
          await super.update(item.id, item);
        }
      }
      debugPrint('[TabelaService] Migration completed.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All tables sorted by numero.
  List<TabelaSangria> get tabelas {
    final list = getAll();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  /// Get tables for a specific partner, sorted by numero.
  List<TabelaSangria> getTabelasForParceiro(String parceiroId) {
    final list = getAll().where((t) => t.parceiroId == parceiroId).toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  /// Check if a partner has any tables configured.
  bool hasTabelas(String parceiroId) {
    return getAll().any((t) => t.parceiroId == parceiroId);
  }

  /// Get a specific table by ID.
  TabelaSangria? getTabelaById(String tabelaId) {
    return getById(tabelaId);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Create N tables for a partner.
  Future<void> criarTabelas(
    String parceiroId,
    int count, {
    List<int?>? arvores,
  }) async {
    // Remove existing tables for this partner first
    await deleteTabelas(parceiroId);

    for (int i = 0; i < count; i++) {
      final tabela = TabelaSangria.create(
        id: const Uuid().v4(),
        parceiroId: parceiroId,
        numero: i + 1,
        arvoresEstimadas:
            arvores != null && i < arvores.length ? arvores[i] : null,
      );
      await super.add(tabela);
    }
  }

  /// Update the estimated tree count for a specific table.
  Future<void> updateArvores(String tabelaId, int? arvores) async {
    final tabela = getById(tabelaId);
    if (tabela != null) {
      // Create updated copy manualy because copyWith doesn't handle nulls ideally for simple updates sometimes,
      // but copyWith is fine here.
      // BUT we need to preserve metadata!
      // Since TabelaSangria is immutable for metadata fields in copyWith?
      // Let's check model... yes copyWith preserves farmId, createdBy etc.

      // Actually, looking at model copyWith:
      // return TabelaSangria(..., lastTappedDate: lastTappedDate ?? this.lastTappedDate...)
      // The issue is if we want to set something TO null.
      // arvoresEstimadas is nullable. If updated arvores is null, copyWith (arvores ?? this.arvores) keeps existing.
      // We need to handle explicit null set.
      // For now assume arvores param is the new value.

      // Let's create a new instance to be safe about metadata and values
      final updated = TabelaSangria(
        id: tabela.id,
        parceiroId: tabela.parceiroId,
        numero: tabela.numero,
        arvoresEstimadas: arvores, // Direct set
        lastTappedDate: tabela.lastTappedDate,
        farmId: tabela.farmId,
        createdBy: tabela.createdBy,
        createdAt: tabela.createdAt,
        sourceApp: tabela.sourceApp,
      );

      await super.update(tabelaId, updated);
    }
  }

  /// Register a tapping event for a table (updates lastTappedDate to now).
  Future<void> registrarSangria(String tabelaId) async {
    final tabela = getById(tabelaId);
    if (tabela != null) {
      final updated = TabelaSangria(
        id: tabela.id,
        parceiroId: tabela.parceiroId,
        numero: tabela.numero,
        arvoresEstimadas: tabela.arvoresEstimadas,
        lastTappedDate: DateTime.now(),
        farmId: tabela.farmId,
        createdBy: tabela.createdBy,
        createdAt: tabela.createdAt,
        sourceApp: tabela.sourceApp,
      );
      await super.update(tabelaId, updated);
    }
  }

  /// Delete all tables for a specific partner.
  Future<void> deleteTabelas(String parceiroId) async {
    final toDelete = getAll()
        .where((t) => t.parceiroId == parceiroId)
        .map((t) => t.id)
        .toList();
    for (final id in toDelete) {
      await super.delete(id);
    }
  }

  /// Clear all tables (used for restore).
  @override
  Future<void> clearAll() async {
    await super.clearAll();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Enforcada Detection (23.6)
  // ─────────────────────────────────────────────────────────────────────

  /// Check if a table was tapped yesterday (sangria enforcada).
  ///
  /// "Enforcada" means tapping the same table on consecutive days,
  /// which damages the tree. This method returns true if the table's
  /// lastTappedDate is yesterday (comparing date only, not time).
  bool isEnforcada(String tabelaId) {
    final tabela = getById(tabelaId);
    if (tabela == null || tabela.lastTappedDate == null) return false;

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final tappedDate = tabela.lastTappedDate!;
    final tappedDay = DateTime(
      tappedDate.year,
      tappedDate.month,
      tappedDate.day,
    );

    return tappedDay.isAtSameMomentAs(yesterday);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Smart Suggestion (23.7)
  // ─────────────────────────────────────────────────────────────────────

  /// Get the suggested table for a partner.
  ///
  /// Returns the table that hasn't been tapped most recently.
  /// If multiple tables have never been tapped, returns the one
  /// with the lowest numero. Returns null if no tables exist.
  TabelaSangria? getSuggestedTable(String parceiroId) {
    final tables = getTabelasForParceiro(parceiroId);
    if (tables.isEmpty) return null;

    // Tables that have never been tapped come first (oldest = null → first)
    // Then sort by lastTappedDate ascending (oldest tapped first)
    tables.sort((a, b) {
      if (a.lastTappedDate == null && b.lastTappedDate == null) {
        return a.numero.compareTo(b.numero);
      }
      if (a.lastTappedDate == null) return -1;
      if (b.lastTappedDate == null) return 1;
      return a.lastTappedDate!.compareTo(b.lastTappedDate!);
    });

    return tables.first;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Analytics (23.5)
  // ─────────────────────────────────────────────────────────────────────

  /// Calculate grams per tree for a given weight and tree count.
  ///
  /// [pesoKg] - Weight in kilograms.
  /// [arvores] - Number of trees.
  /// Returns weight in grams per tree.
  double calcGramasArvore(double pesoKg, int arvores) {
    if (arvores <= 0) return 0.0;
    return (pesoKg * 1000) / arvores;
  }

  /// Get productivity by table for a partner within a safra period.
  ///
  /// Returns a map of table numero to total kg.
  /// Requires EntregaService to be set via [setEntregaService].
  ///
  /// Note: This is a simplified implementation. Full integration with
  /// Pesagem → Tabela mapping will be done when pesagem_screen is updated.
  /// For now, returns an empty map (data will be available after
  /// pesagem integration adds tabelaId to weighing records).
  Map<int, double> getProductivityByTable(String parceiroId, Safra safra) {
    // This method prepares the analytics infrastructure.
    // Full implementation requires tabelaId on Pesagem records,
    // which will be added during integration (separate task).
    final tables = getTabelasForParceiro(parceiroId);
    final result = <int, double>{};
    for (final table in tables) {
      result[table.numero] = 0.0;
    }
    return result;
  }
}
