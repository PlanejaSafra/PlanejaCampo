import 'package:agro_core/agro_core.dart';
import '../models/receita.dart';
import 'conta_service.dart';

/// CASH-24: Service for managing revenue entries.
class ReceitaService extends GenericSyncService<Receita> {
  static final ReceitaService _instance = ReceitaService._internal();
  static ReceitaService get instance => _instance;
  ReceitaService._internal();
  factory ReceitaService() => _instance;

  @override
  String get boxName => 'receitas';

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'receitas';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Receita fromMap(Map<String, dynamic> map) => Receita.fromJson(map);

  @override
  Map<String, dynamic> toMap(Receita item) => item.toJson();

  @override
  String getId(Receita item) => item.id;

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All entries sorted by date descending.
  List<Receita> get receitas {
    final farmId = FarmService.instance.defaultFarmId;
    if (farmId == null) return [];
    final list = getByFarmId(farmId);
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  /// Entries for the current month.
  List<Receita> get receitasDoMes {
    final now = DateTime.now();
    return receitas
        .where((r) => r.data.year == now.year && r.data.month == now.month)
        .toList();
  }

  /// Entries for a specific month/year.
  List<Receita> getReceitasPorMes(int year, int month) {
    return receitas
        .where((r) => r.data.year == year && r.data.month == month)
        .toList();
  }

  /// Entries for a date range.
  List<Receita> getReceitasPorPeriodo(DateTime inicio, DateTime fim) {
    return receitas
        .where((r) =>
            !r.data.isBefore(inicio) &&
            r.data.isBefore(fim.add(const Duration(days: 1))))
        .toList();
  }

  /// Total for the current month.
  double get totalDoMes {
    return receitasDoMes.fold(0.0, (sum, r) => sum + r.valor);
  }

  /// Total for a specific month/year.
  double totalPorMes(int year, int month) {
    return getReceitasPorMes(year, month).fold(0.0, (sum, r) => sum + r.valor);
  }

  /// Total by category for a period.
  Map<String, double> totalPorCategoria(DateTime inicio, DateTime fim) {
    final entries = getReceitasPorPeriodo(inicio, fim);
    final result = <String, double>{};
    for (final entry in entries) {
      result[entry.categoriaId] = (result[entry.categoriaId] ?? 0) + entry.valor;
    }
    return result;
  }

  /// Monthly totals for a year.
  Map<int, double> totalMensalAno(int year) {
    final result = <int, double>{};
    for (int month = 1; month <= 12; month++) {
      result[month] = totalPorMes(year, month);
    }
    return result;
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Add a new revenue entry. Optionally credit account balance.
  Future<Receita> addReceita(Receita receita) async {
    await super.add(receita);

    // CASH-23: Update account balance if linked
    if (receita.contaDestinoId != null) {
      await ContaService.instance.creditar(receita.contaDestinoId!, receita.valor);
    }

    return receita;
  }

  /// Quick add.
  Future<Receita> quickAdd({
    required double valor,
    required String categoriaId,
    String? descricao,
    String? centroCustoId,
    String? contaDestinoId,
    DateTime? data,
  }) async {
    final receita = Receita.create(
      valor: valor,
      categoriaId: categoriaId,
      descricao: descricao,
      centroCustoId: centroCustoId,
      contaDestinoId: contaDestinoId,
      data: data,
    );
    return addReceita(receita);
  }

  /// Delete a revenue entry. Reverse account credit if linked.
  Future<void> deleteReceita(String id) async {
    final receita = getById(id);
    if (receita != null && receita.contaDestinoId != null) {
      await ContaService.instance.debitar(receita.contaDestinoId!, receita.valor);
    }
    await super.delete(id);
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return receitas.map((r) => r.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final receita = Receita.fromJson(json as Map<String, dynamic>);
      if (getById(receita.id) == null) {
        await super.add(receita);
      }
    }
  }
}
