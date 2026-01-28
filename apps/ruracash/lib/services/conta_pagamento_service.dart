import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:agro_core/agro_core.dart';

import '../models/conta_pagar.dart';
// import 'lancamento_service.dart'; // Future integration

class ContaPagamentoService extends GenericSyncService<ContaPagar> {
  static const String _boxName = 'contas_pagar';

  static final ContaPagamentoService _instance = ContaPagamentoService._internal();
  factory ContaPagamentoService() => _instance;
  ContaPagamentoService._internal();

  @override
  String get boxName => _boxName;

  @override
  String get firestoreCollection => 'contas_pagar';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  // --- Queries ---

  List<ContaPagar> getPendentes({String? farmId}) {
    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    return getAll()
        .where((c) => c.farmId == targetFarmId && c.status == StatusPagamento.pendente && !c.deleted!)
        .toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  }

  List<ContaPagar> getVencidas({String? farmId}) {
    final now = DateTime.now();
    return getPendentes(farmId: farmId)
        .where((c) => c.vencimento.isBefore(now))
        .toList();
  }

  List<ContaPagar> getProximas({int dias = 7, String? farmId}) {
    final now = DateTime.now();
    final limit = now.add(Duration(days: dias));
    return getPendentes(farmId: farmId)
        .where((c) => c.vencimento.isAfter(now) && c.vencimento.isBefore(limit))
        .toList();
  }

  // --- Actions ---

  /// Registra uma compra a prazo (Hidden Double-Entry Step 1)
  /// 1. Cria Lançamento (Despesa, Competência = Hoje, Conta = Null)
  /// 2. Cria ContaPagar (Passivo) vinculada ao lançamento
  ///
  /// Nota: O Lançamento deve ser criado externamente e passado o ID, 
  /// ou este método deve injetar LancamentoService. 
  /// Para desacoplamento, assumimos que quem chama (Controller) já criou o lançamento ou passará o ID.
  Future<void> registrarCompraAPrazo(ContaPagar conta) async {
    await add(conta);
  }

  /// Realiza o pagamento de uma conta (Hidden Double-Entry Step 2)
  /// 1. Atualiza ContaPagar para 'pago'
  /// 2. Registra contaPagamentoId (de onde saiu o dinheiro)
  /// 3. Fluxo de Caixa lerá esta ContaPagar para deduzir do saldo da contaPagamentoId
  Future<void> pagar(String id, String contaPagamentoId, DateTime dataPagamento) async {
    final conta = getById(id);
    if (conta == null) throw Exception('Conta a pagar não encontrada: $id');

    final updated = conta.copyWith(
      status: StatusPagamento.pago,
      contaPagamentoId: contaPagamentoId,
      dataPagamento: dataPagamento,
      updatedAt: DateTime.now(),
    );

    await update(updated);
  }

  /// Adiar o vencimento
  Future<void> adiar(String id, DateTime novoVencimento) async {
    final conta = getById(id);
    if (conta == null) return;

    final updated = conta.copyWith(
      vencimento: novoVencimento,
      updatedAt: DateTime.now(),
    );
    await update(updated);
  }
}
