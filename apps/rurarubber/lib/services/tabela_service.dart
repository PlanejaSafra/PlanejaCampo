import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/tabela_sangria.dart';

/// Service for managing tapping tables (Tabelas de Sangria) in RuraRubber.
///
/// Provides CRUD operations, enforcada detection, smart table suggestion,
/// and productivity analytics for the D3/D4 tapping rotation system.
///
/// ## Usage
/// ```dart
/// // Initialize in main.dart
/// await TabelaService.instance.init();
///
/// // Create tables for a partner
/// await TabelaService.instance.criarTabelas('parceiro-id', 4);
///
/// // Get suggested table
/// final suggested = TabelaService.instance.getSuggestedTable('parceiro-id');
/// ```
///
/// See RUBBER-23 for architecture.
class TabelaService extends ChangeNotifier {
  static const String boxName = 'tabelas_sangria';
  Box<TabelaSangria>? _box;

  // Singleton
  static final TabelaService _instance = TabelaService._internal();
  static TabelaService get instance => _instance;
  TabelaService._internal();
  factory TabelaService() => _instance;

  /// Initialize the Hive box.
  /// Must be called from main.dart AFTER adapter registration.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<TabelaSangria>(boxName);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All tables sorted by numero.
  List<TabelaSangria> get tabelas {
    if (_box == null) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  /// Get tables for a specific partner, sorted by numero.
  List<TabelaSangria> getTabelasForParceiro(String parceiroId) {
    if (_box == null) return [];
    final list =
        _box!.values.where((t) => t.parceiroId == parceiroId).toList();
    list.sort((a, b) => a.numero.compareTo(b.numero));
    return list;
  }

  /// Check if a partner has any tables configured.
  bool hasTabelas(String parceiroId) {
    if (_box == null) return false;
    return _box!.values.any((t) => t.parceiroId == parceiroId);
  }

  /// Get a specific table by ID.
  TabelaSangria? getTabelaById(String tabelaId) {
    if (_box == null) return null;
    return _box!.get(tabelaId);
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Create N tables for a partner.
  ///
  /// [parceiroId] - The partner to create tables for.
  /// [count] - Number of tables to create (typically 3, 4, or 5).
  /// [arvores] - Optional list of estimated tree counts per table.
  ///             Length must match [count] if provided.
  Future<void> criarTabelas(
    String parceiroId,
    int count, {
    List<int?>? arvores,
  }) async {
    if (_box == null) await init();

    // Remove existing tables for this partner first
    await deleteTabelas(parceiroId);

    for (int i = 0; i < count; i++) {
      final tabela = TabelaSangria.create(
        id: const Uuid().v4(),
        parceiroId: parceiroId,
        numero: i + 1,
        arvoresEstimadas: arvores != null && i < arvores.length
            ? arvores[i]
            : null,
      );
      await _box!.put(tabela.id, tabela);
    }
    notifyListeners();
  }

  /// Update the estimated tree count for a specific table.
  Future<void> updateArvores(String tabelaId, int? arvores) async {
    if (_box == null) await init();
    final tabela = _box!.get(tabelaId);
    if (tabela != null) {
      tabela.arvoresEstimadas = arvores;
      await tabela.save();
      notifyListeners();
    }
  }

  /// Register a tapping event for a table (updates lastTappedDate to now).
  Future<void> registrarSangria(String tabelaId) async {
    if (_box == null) await init();
    final tabela = _box!.get(tabelaId);
    if (tabela != null) {
      tabela.lastTappedDate = DateTime.now();
      await tabela.save();
      notifyListeners();
    }
  }

  /// Delete all tables for a specific partner.
  Future<void> deleteTabelas(String parceiroId) async {
    if (_box == null) await init();
    final toDelete = _box!.values
        .where((t) => t.parceiroId == parceiroId)
        .map((t) => t.id)
        .toList();
    for (final id in toDelete) {
      await _box!.delete(id);
    }
    notifyListeners();
  }

  /// Clear all tables (used for restore).
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    notifyListeners();
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
    final tabela = _box?.get(tabelaId);
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
