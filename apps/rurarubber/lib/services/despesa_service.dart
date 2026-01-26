import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/despesa.dart';

/// Service for managing expenses (Despesas) in RuraRubber.
///
/// Provides CRUD operations and safra-aware queries for the
/// break-even cost analysis dashboard (RUBBER-20).
///
/// ## Usage
/// ```dart
/// // Initialize in main.dart
/// await DespesaService.instance.init();
///
/// // Add an expense
/// await DespesaService.instance.adicionarDespesa(
///   valor: 1500.00,
///   categoria: CategoriaDespesa.maoDeObra,
///   data: DateTime.now(),
/// );
///
/// // Get totals for a safra
/// final total = DespesaService.instance.totalPorSafra(safra);
/// ```
class DespesaService extends ChangeNotifier {
  static const String boxName = 'despesas';
  Box<Despesa>? _box;

  static final DespesaService _instance = DespesaService._internal();
  static DespesaService get instance => _instance;
  DespesaService._internal();
  factory DespesaService() => _instance;

  /// Initialize the Hive box.
  /// Must be called from main.dart AFTER adapter registration.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<Despesa>(boxName);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All expenses sorted by date (newest first).
  List<Despesa> get despesas {
    if (_box == null) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  /// Total of all expenses (no safra filter).
  double get totalGeral => despesas.fold(0, (sum, d) => sum + d.valor);

  // ─────────────────────────────────────────────────────────────────────
  // Safra-filtered queries (RUBBER-20)
  // ─────────────────────────────────────────────────────────────────────

  /// Get expenses filtered by a safra's time period.
  List<Despesa> despesasPorSafra(Safra safra) {
    return SafraService.instance.filterBySafra(
      records: despesas,
      safra: safra,
      getDate: (d) => d.data,
    );
  }

  /// Total expenses (R$) within a safra period.
  double totalPorSafra(Safra safra) {
    return SafraService.instance.sumBySafra(
      records: despesas,
      safra: safra,
      getDate: (d) => d.data,
      getValue: (d) => d.valor,
    );
  }

  /// Total expenses grouped by category within a safra.
  /// Returns a map of [CategoriaDespesa] to total R$.
  Map<CategoriaDespesa, double> totalPorCategoria(Safra safra) {
    final filtered = despesasPorSafra(safra);
    final result = <CategoriaDespesa, double>{};
    for (final d in filtered) {
      result[d.categoria] = (result[d.categoria] ?? 0) + d.valor;
    }
    return result;
  }

  /// Monthly totals within a safra period (for trend analysis).
  /// Returns a sorted list of (DateTime with year/month) to total R$.
  List<MapEntry<DateTime, double>> totalMensalSafra(Safra safra) {
    final filtered = despesasPorSafra(safra);
    final monthly = <String, double>{};
    for (final d in filtered) {
      final key =
          '${d.data.year}-${d.data.month.toString().padLeft(2, '0')}';
      monthly[key] = (monthly[key] ?? 0) + d.valor;
    }
    final entries = monthly.entries.map((e) {
      final parts = e.key.split('-');
      return MapEntry(
        DateTime(int.parse(parts[0]), int.parse(parts[1])),
        e.value,
      );
    }).toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Add a new expense.
  Future<void> adicionarDespesa({
    required double valor,
    required CategoriaDespesa categoria,
    required DateTime data,
    String? descricao,
  }) async {
    if (_box == null) await init();
    final despesa = Despesa.create(
      id: const Uuid().v4(),
      valor: valor,
      categoria: categoria,
      data: data,
      descricao: descricao,
    );
    await _box!.put(despesa.id, despesa);
    notifyListeners();
  }

  /// Update an expense (replaces existing with same ID).
  Future<void> updateDespesa({
    required String id,
    required double valor,
    required CategoriaDespesa categoria,
    required DateTime data,
    String? descricao,
  }) async {
    if (_box == null) await init();
    final existing = _box!.get(id);
    if (existing == null) return;
    final updated = Despesa(
      id: existing.id,
      valor: valor,
      categoria: categoria,
      data: data,
      descricao: descricao,
      farmId: existing.farmId,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      sourceApp: existing.sourceApp,
    );
    await _box!.put(id, updated);
    notifyListeners();
  }

  /// Delete an expense by ID.
  Future<void> deleteDespesa(String id) async {
    if (_box == null) await init();
    await _box!.delete(id);
    notifyListeners();
  }

  /// Clear all expenses (used for restore).
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    notifyListeners();
  }
}
