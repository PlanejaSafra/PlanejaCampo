import 'package:agro_core/agro_core.dart';
import 'package:agro_core/services/sync/generic_sync_service.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/despesa.dart';

/// Service for managing expenses (Despesas) in RuraRubber.
/// Migrated to GenericSyncService (CORE-83).
class DespesaService extends GenericSyncService<Despesa> {
  static final DespesaService _instance = DespesaService._internal();
  static DespesaService get instance => _instance;
  DespesaService._internal();
  factory DespesaService() => _instance;

  @override
  String get boxName => 'despesas';

  @override
  String get sourceApp => 'rurarubber';

  @override
  bool get syncEnabled => true;

  @override
  Despesa fromMap(Map<String, dynamic> map) => Despesa.fromJson(map);

  @override
  Map<String, dynamic> toMap(Despesa item) => item.toJson();

  @override
  String getId(Despesa item) => item.id;

  @override
  Future<void> init() async {
    await super.init();
    await _migrateDataIfNeeded();
  }

  /// Migra dados antigos (Objetos) para nova estrutura (Maps com Metadata)
  Future<void> _migrateDataIfNeeded() async {
    final box = Hive.box(boxName);
    if (box.isEmpty) return;

    final firstKey = box.keys.first;
    final firstValue = box.get(firstKey);

    if (firstValue is Despesa) {
      debugPrint('[DespesaService] Migrating data from Adapter to Map...');
      final Map<dynamic, dynamic> rawMap = box.toMap();

      for (final entry in rawMap.entries) {
        if (entry.value is Despesa) {
          final item = entry.value as Despesa;
          await super.update(item.id, item);
        }
      }
      debugPrint('[DespesaService] Migration completed.');
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All expenses sorted by date (newest first).
  List<Despesa> get despesas {
    final list = getAll();
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
  Map<CategoriaDespesa, double> totalPorCategoria(Safra safra) {
    final filtered = despesasPorSafra(safra);
    final result = <CategoriaDespesa, double>{};
    for (final d in filtered) {
      result[d.categoria] = (result[d.categoria] ?? 0) + d.valor;
    }
    return result;
  }

  /// Monthly totals within a safra period (for trend analysis).
  List<MapEntry<DateTime, double>> totalMensalSafra(Safra safra) {
    final filtered = despesasPorSafra(safra);
    final monthly = <String, double>{};
    for (final d in filtered) {
      final key = '${d.data.year}-${d.data.month.toString().padLeft(2, '0')}';
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
    final despesa = Despesa.create(
      id: const Uuid().v4(),
      valor: valor,
      categoria: categoria,
      data: data,
      descricao: descricao,
    );
    await super.add(despesa);
  }

  /// Update an expense (replaces existing with same ID).
  Future<void> updateDespesa({
    required String id,
    required double valor,
    required CategoriaDespesa categoria,
    required DateTime data,
    String? descricao,
  }) async {
    final existing = getById(id);
    if (existing == null) return;

    // Create updated copy preserving metadata not passed in arguments
    // Despesa model uses immutable fields for metadata, but we need
    // to preserve things like createdBy/createdAt if they aren't changing.
    // Despesa.create generates NEW metadata. We should construct manually or copy.

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

    await super.update(id, updated);
  }

  /// Delete an expense by ID.
  Future<void> deleteDespesa(String id) async {
    await super.delete(id);
  }
}
