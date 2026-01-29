import 'package:agro_core/agro_core.dart';
import '../models/lancamento.dart';

/// Service for managing financial entries (expenses).
/// CASH-21: Migrated from CashCategoria enum to Categoria model (categoriaId).
class LancamentoService extends GenericSyncService<Lancamento> {
  static final LancamentoService _instance = LancamentoService._internal();
  static LancamentoService get instance => _instance;
  LancamentoService._internal();
  factory LancamentoService() => _instance;

  @override
  String get boxName => 'lancamentos';

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'lancamentos';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Lancamento fromMap(Map<String, dynamic> map) => Lancamento.fromJson(map);

  @override
  Map<String, dynamic> toMap(Lancamento item) => item.toJson();

  @override
  String getId(Lancamento item) => item.id;

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All entries sorted by date descending.
  /// Filtered by the active farm.
  List<Lancamento> get lancamentos {
    final farmId = FarmService.instance.defaultFarmId;
    if (farmId == null) return [];

    final list = getByFarmId(farmId);
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  /// Force UI update (e.g. after switching context)
  void forceUpdate() {
    notifyListeners();
  }

  /// Entries for the current month.
  List<Lancamento> get lancamentosDoMes {
    final now = DateTime.now();
    return lancamentos
        .where((l) => l.data.year == now.year && l.data.month == now.month)
        .toList();
  }

  /// Entries for a specific month/year.
  List<Lancamento> getLancamentosPorMes(int year, int month) {
    return lancamentos
        .where((l) => l.data.year == year && l.data.month == month)
        .toList();
  }

  /// Entries for a date range.
  List<Lancamento> getLancamentosPorPeriodo(DateTime inicio, DateTime fim) {
    return lancamentos
        .where((l) =>
            !l.data.isBefore(inicio) &&
            l.data.isBefore(fim.add(const Duration(days: 1))))
        .toList();
  }

  /// Entries by category ID.
  List<Lancamento> getLancamentosPorCategoria(String categoriaId) {
    return lancamentos.where((l) => l.categoriaId == categoriaId).toList();
  }

  /// Entries by cost center.
  List<Lancamento> getLancamentosPorCentroCusto(String centroCustoId) {
    return lancamentos.where((l) => l.centroCustoId == centroCustoId).toList();
  }

  /// Entries by account (CASH-23).
  List<Lancamento> getLancamentosPorConta(String contaId) {
    return lancamentos.where((l) => l.contaOrigemId == contaId).toList();
  }

  /// Total for the current month.
  double get totalDoMes {
    return lancamentosDoMes.fold(0.0, (sum, l) => sum + l.valor);
  }

  /// Total for a specific month/year.
  double totalPorMes(int year, int month) {
    return getLancamentosPorMes(year, month)
        .fold(0.0, (sum, l) => sum + l.valor);
  }

  /// Total by category for a period (returns Map<categoriaId, total>).
  Map<String, double> totalPorCategoria(DateTime inicio, DateTime fim) {
    final entries = getLancamentosPorPeriodo(inicio, fim);
    final result = <String, double>{};
    for (final entry in entries) {
      result[entry.categoriaId] = (result[entry.categoriaId] ?? 0) + entry.valor;
    }
    return result;
  }

  /// Total by cost center for a period.
  Map<String, double> totalPorCentroCusto(DateTime inicio, DateTime fim) {
    final entries = getLancamentosPorPeriodo(inicio, fim);
    final result = <String, double>{};
    for (final entry in entries) {
      final key = entry.centroCustoId ?? 'default';
      result[key] = (result[key] ?? 0) + entry.valor;
    }
    return result;
  }

  /// Total by account for a period (CASH-23).
  Map<String, double> totalPorConta(DateTime inicio, DateTime fim) {
    final entries = getLancamentosPorPeriodo(inicio, fim);
    final result = <String, double>{};
    for (final entry in entries) {
      final key = entry.contaOrigemId ?? 'caixa';
      result[key] = (result[key] ?? 0) + entry.valor;
    }
    return result;
  }

  /// Monthly totals for a year (for DRE chart).
  Map<int, double> totalMensalAno(int year) {
    final result = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      result[month] = totalPorMes(year, month);
    }
    return result;
  }

  /// Most frequently used category ID (for smart default).
  String? get categoriaMaisUsada {
    if (lancamentos.isEmpty) return null;
    final counts = <String, int>{};
    for (final l in lancamentos) {
      counts[l.categoriaId] = (counts[l.categoriaId] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Add a new entry.
  Future<Lancamento> addLancamento(Lancamento lancamento) async {
    await super.add(lancamento);
    return lancamento;
  }

  /// Quick add: create and save in one call.
  Future<Lancamento> quickAdd({
    required double valor,
    required String categoriaId,
    String? descricao,
    String? centroCustoId,
    String? contaOrigemId,
    DateTime? data,
  }) async {
    final lancamento = Lancamento.create(
      valor: valor,
      categoriaId: categoriaId,
      descricao: descricao,
      centroCustoId: centroCustoId,
      contaOrigemId: contaOrigemId,
      data: data,
    );
    return addLancamento(lancamento);
  }

  /// Update an existing entry.
  Future<void> updateLancamento(Lancamento lancamento) async {
    await super.update(lancamento.id, lancamento);
  }

  /// Delete an entry.
  Future<void> deleteLancamento(String id) async {
    await super.delete(id);
  }

  /// Get entry by ID.
  Lancamento? getLancamento(String id) {
    return getById(id);
  }

  /// Clear all entries.
  @override
  Future<void> clearAll() async {
    await super.clearAll();
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return lancamentos.map((l) => l.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final lancamento = Lancamento.fromJson(json as Map<String, dynamic>);
      if (getById(lancamento.id) == null) {
        await super.add(lancamento);
      }
    }
  }
}
