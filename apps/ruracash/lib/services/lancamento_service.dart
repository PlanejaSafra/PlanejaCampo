import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/lancamento.dart';
import '../models/cash_categoria.dart';

/// Service for managing financial entries (expenses).
class LancamentoService extends ChangeNotifier {
  static final LancamentoService _instance = LancamentoService._internal();
  static LancamentoService get instance => _instance;
  factory LancamentoService() => _instance;
  LancamentoService._internal();

  static const String _boxName = 'lancamentos';
  late Box<Lancamento> _box;

  /// Initialize the service.
  Future<void> init() async {
    _box = await Hive.openBox<Lancamento>(_boxName);
  }

  /// All entries sorted by date descending.
  List<Lancamento> get lancamentos {
    final list = _box.values.toList();
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
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

  /// Entries by category.
  List<Lancamento> getLancamentosPorCategoria(CashCategoria categoria) {
    return lancamentos.where((l) => l.categoria == categoria).toList();
  }

  /// Entries by cost center.
  List<Lancamento> getLancamentosPorCentroCusto(String centroCustoId) {
    return lancamentos
        .where((l) => l.centroCustoId == centroCustoId)
        .toList();
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

  /// Total by category for a period.
  Map<CashCategoria, double> totalPorCategoria(DateTime inicio, DateTime fim) {
    final entries = getLancamentosPorPeriodo(inicio, fim);
    final result = <CashCategoria, double>{};
    for (final entry in entries) {
      result[entry.categoria] =
          (result[entry.categoria] ?? 0) + entry.valor;
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

  /// Monthly totals for a year (for DRE chart).
  Map<int, double> totalMensalAno(int year) {
    final result = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      result[month] = totalPorMes(year, month);
    }
    return result;
  }

  /// Most frequently used category (for smart default).
  CashCategoria? get categoriaMaisUsada {
    if (lancamentos.isEmpty) return null;
    final counts = <CashCategoria, int>{};
    for (final l in lancamentos) {
      counts[l.categoria] = (counts[l.categoria] ?? 0) + 1;
    }
    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Add a new entry.
  Future<Lancamento> addLancamento(Lancamento lancamento) async {
    await _box.put(lancamento.id, lancamento);
    notifyListeners();
    return lancamento;
  }

  /// Quick add: create and save in one call.
  Future<Lancamento> quickAdd({
    required double valor,
    required CashCategoria categoria,
    String? descricao,
    String? centroCustoId,
    DateTime? data,
  }) async {
    final lancamento = Lancamento.create(
      valor: valor,
      categoria: categoria,
      descricao: descricao,
      centroCustoId: centroCustoId,
      data: data,
    );
    return addLancamento(lancamento);
  }

  /// Update an existing entry.
  Future<void> updateLancamento(Lancamento lancamento) async {
    await _box.put(lancamento.id, lancamento);
    notifyListeners();
  }

  /// Delete an entry.
  Future<void> deleteLancamento(String id) async {
    await _box.delete(id);
    notifyListeners();
  }

  /// Get entry by ID.
  Lancamento? getLancamento(String id) {
    return _box.get(id);
  }

  /// Clear all entries.
  Future<void> clearAll() async {
    await _box.clear();
    notifyListeners();
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return lancamentos.map((l) => l.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final lancamento = Lancamento.fromJson(json as Map<String, dynamic>);
      if (!_box.containsKey(lancamento.id)) {
        await _box.put(lancamento.id, lancamento);
      }
    }
    notifyListeners();
  }
}
