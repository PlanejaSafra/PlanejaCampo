import 'package:agro_core/agro_core.dart';
import '../models/transferencia.dart';
import 'conta_service.dart';

/// CASH-25: Service for managing transfers between accounts.
class TransferenciaService extends GenericSyncService<Transferencia> {
  static final TransferenciaService _instance = TransferenciaService._internal();
  static TransferenciaService get instance => _instance;
  TransferenciaService._internal();
  factory TransferenciaService() => _instance;

  @override
  String get boxName => 'transferencias';

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'transferencias';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Transferencia fromMap(Map<String, dynamic> map) => Transferencia.fromJson(map);

  @override
  Map<String, dynamic> toMap(Transferencia item) => item.toJson();

  @override
  String getId(Transferencia item) => item.id;

  // ─────────────────────────────────────────────────────────────────────
  // Read Operations
  // ─────────────────────────────────────────────────────────────────────

  /// All transfers sorted by date descending.
  List<Transferencia> get transferencias {
    final farmId = FarmService.instance.defaultFarmId;
    if (farmId == null) return [];
    final list = getByFarmId(farmId);
    list.sort((a, b) => b.data.compareTo(a.data));
    return list;
  }

  /// Transfers for a date range.
  List<Transferencia> getTransferenciasPorPeriodo(DateTime inicio, DateTime fim) {
    return transferencias
        .where((t) =>
            !t.data.isBefore(inicio) &&
            t.data.isBefore(fim.add(const Duration(days: 1))))
        .toList();
  }

  /// Transfers involving a specific account.
  List<Transferencia> getTransferenciasPorConta(String contaId) {
    return transferencias
        .where((t) => t.contaOrigemId == contaId || t.contaDestinoId == contaId)
        .toList();
  }

  // ─────────────────────────────────────────────────────────────────────
  // Write Operations
  // ─────────────────────────────────────────────────────────────────────

  /// Execute a transfer between two accounts.
  Future<Transferencia> executarTransferencia({
    required String contaOrigemId,
    required String contaDestinoId,
    required double valor,
    DateTime? data,
    String? descricao,
  }) async {
    final transferencia = Transferencia.create(
      contaOrigemId: contaOrigemId,
      contaDestinoId: contaDestinoId,
      valor: valor,
      data: data,
      descricao: descricao,
    );

    await super.add(transferencia);

    // Update account balances
    await ContaService.instance.transferir(contaOrigemId, contaDestinoId, valor);

    return transferencia;
  }

  /// Reverse a transfer (on delete).
  Future<void> deleteTransferencia(String id) async {
    final transferencia = getById(id);
    if (transferencia != null) {
      // Reverse: credit origin, debit destination
      await ContaService.instance.creditar(transferencia.contaOrigemId, transferencia.valor);
      await ContaService.instance.debitar(transferencia.contaDestinoId, transferencia.valor);
    }
    await super.delete(id);
  }

  /// Backup helpers.
  List<Map<String, dynamic>> toJsonList() {
    return transferencias.map((t) => t.toJson()).toList();
  }

  Future<void> importFromJson(List<dynamic> jsonList) async {
    for (final json in jsonList) {
      final t = Transferencia.fromJson(json as Map<String, dynamic>);
      if (getById(t.id) == null) {
        await super.add(t);
      }
    }
  }
}
