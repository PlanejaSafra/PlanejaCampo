import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/conta_pagar.dart';

/// Service for managing accounts payable (contas a pagar).
///
/// Singleton ChangeNotifier that provides CRUD operations,
/// filtering by status, batch payment, and totals.
///
/// See RUBBER-19 for architecture.
class ContaPagarService extends ChangeNotifier {
  static const String boxName = 'contas_pagar';
  Box<ContaPagar>? _box;

  static final ContaPagarService _instance = ContaPagarService._internal();
  static ContaPagarService get instance => _instance;
  ContaPagarService._internal();
  factory ContaPagarService() => _instance;

  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<ContaPagar>(boxName);
    notifyListeners();
  }

  /// All contas sorted by vencimento (earliest first).
  List<ContaPagar> get contas {
    if (_box == null) return [];
    final list = _box!.values.toList();
    list.sort((a, b) => a.vencimento.compareTo(b.vencimento));
    return list;
  }

  /// Only unpaid contas.
  List<ContaPagar> get pendentes => contas.where((c) => !c.pago).toList();

  /// Only paid contas.
  List<ContaPagar> get pagas => contas.where((c) => c.pago).toList();

  /// Unpaid contas that are past due date.
  List<ContaPagar> get vencidas => pendentes.where((c) => c.isVencido).toList();

  /// Sum of all unpaid values.
  double get totalPendente => pendentes.fold(0, (sum, c) => sum + c.valor);

  /// Sum of all paid values.
  double get totalPago => pagas.fold(0, (sum, c) => sum + c.valor);

  /// Get contas for a specific parceiro.
  List<ContaPagar> contasPorParceiro(String parceiroId) =>
      contas.where((c) => c.parceiroId == parceiroId).toList();

  /// Create a new conta a pagar.
  Future<void> criarConta({
    required String parceiroId,
    String? entregaId,
    required double valor,
    required DateTime vencimento,
  }) async {
    if (_box == null) await init();
    final conta = ContaPagar.create(
      id: const Uuid().v4(),
      parceiroId: parceiroId,
      entregaId: entregaId,
      valor: valor,
      vencimento: vencimento,
    );
    await _box!.put(conta.id, conta);
    notifyListeners();
  }

  /// Mark a single conta as paid.
  Future<void> marcarPago(
    String id, {
    required FormaPagamento forma,
    DateTime? dataPagamento,
  }) async {
    if (_box == null) await init();
    final conta = _box!.get(id);
    if (conta != null) {
      conta.pago = true;
      conta.dataPagamento = dataPagamento ?? DateTime.now();
      conta.formaPagamento = forma;
      await conta.save();
      notifyListeners();
    }
  }

  /// Mark multiple contas as paid in batch.
  Future<void> baixaEmLote(
    List<String> ids, {
    required FormaPagamento forma,
  }) async {
    if (_box == null) await init();
    for (final id in ids) {
      final conta = _box!.get(id);
      if (conta != null && !conta.pago) {
        conta.pago = true;
        conta.dataPagamento = DateTime.now();
        conta.formaPagamento = forma;
        await conta.save();
      }
    }
    notifyListeners();
  }

  /// Update a conta a pagar (replaces existing with same ID).
  Future<void> updateConta({
    required String id,
    required double valor,
    required DateTime vencimento,
  }) async {
    if (_box == null) await init();
    final existing = _box!.get(id);
    if (existing == null) return;
    final updated = ContaPagar(
      id: existing.id,
      parceiroId: existing.parceiroId,
      entregaId: existing.entregaId,
      valor: valor,
      vencimento: vencimento,
      pago: existing.pago,
      dataPagamento: existing.dataPagamento,
      formaPagamento: existing.formaPagamento,
      farmId: existing.farmId,
      createdBy: existing.createdBy,
      createdAt: existing.createdAt,
      sourceApp: existing.sourceApp,
    );
    await _box!.put(id, updated);
    notifyListeners();
  }

  /// Delete a single conta.
  Future<void> deleteConta(String id) async {
    if (_box == null) await init();
    await _box!.delete(id);
    notifyListeners();
  }

  /// Clear all contas (used for restore).
  Future<void> clearAll() async {
    if (_box == null) await init();
    await _box!.clear();
    notifyListeners();
  }
}
