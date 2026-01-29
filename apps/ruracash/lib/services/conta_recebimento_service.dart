import 'package:agro_core/agro_core.dart';

import '../models/conta_receber.dart';

class ContaRecebimentoService extends GenericSyncService<ContaReceber> {
  static const String _boxName = 'contas_receber';

  static final ContaRecebimentoService _instance = ContaRecebimentoService._internal();
  factory ContaRecebimentoService() => _instance;
  ContaRecebimentoService._internal();

  @override
  String get boxName => _boxName;

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'contas_receber';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  ContaReceber fromMap(Map<String, dynamic> map) => ContaReceber.fromJson(map);

  @override
  Map<String, dynamic> toMap(ContaReceber item) => item.toJson();

  @override
  String getId(ContaReceber item) => item.id;

  // --- Queries ---

  List<ContaReceber> getPendentes({String? farmId}) {
    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    return getAll()
        .where((c) => c.farmId == targetFarmId && c.status == StatusRecebimento.pendente && !c.deleted!)
        .toList()
      ..sort((a, b) => a.vencimento.compareTo(b.vencimento));
  }

  // --- Actions ---

  /// Receber um valor (baixa)
  Future<void> receber(String id, String contaDestinoId, DateTime dataRecebimento) async {
    final conta = getById(id);
    if (conta == null) throw Exception('Conta a receber não encontrada: $id');

    final updated = conta.copyWith(
      status: StatusRecebimento.recebido,
      contaDestinoId: contaDestinoId,
      dataRecebimento: dataRecebimento,
      updatedAt: DateTime.now(),
    );

    await update(id, updated);
  }
}
