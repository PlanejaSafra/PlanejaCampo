import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:agro_core/agro_core.dart';

import '../models/orcamento.dart';

class OrcamentoService extends GenericSyncService<Orcamento> {
  static const String _boxName = 'orcamentos';

  static final OrcamentoService _instance = OrcamentoService._internal();
  factory OrcamentoService() => _instance;
  OrcamentoService._internal();

  @override
  String get boxName => _boxName;

  @override
  String get sourceApp => 'ruracash';

  @override
  String get firestoreCollection => 'orcamentos';

  @override
  bool get syncEnabled => FarmService.instance.isActiveFarmShared();

  @override
  Orcamento fromMap(Map<String, dynamic> map) => Orcamento.fromJson(map);

  @override
  Map<String, dynamic> toMap(Orcamento item) => item.toJson();

  @override
  String getId(Orcamento item) => item.id;

  // --- Queries ---

  /// Busca orçamento ativo para uma categoria em uma data específica
  Orcamento? getOrcamentoAtivo(String categoriaId, DateTime data, {String? farmId}) {
    final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
    final orcamentos = getAll()
        .where((o) => 
            o.farmId == targetFarmId && 
            o.categoriaId == categoriaId && 
            !o.deleted!)
        .toList();

    // Verifica qual engloba a data
    for (final orcamento in orcamentos) {
      final range = orcamento.periodo;
      if (data.isAfter(range.start.subtract(Duration(seconds: 1))) && 
          data.isBefore(range.end.add(Duration(seconds: 1)))) {
        return orcamento;
      }
    }
    return null;
  }

  List<Orcamento> getPorPeriodoTipo(TipoPeriodoOrcamento tipo, int ano, {String? farmId}) {
     final targetFarmId = farmId ?? FarmService.instance.defaultFarmId;
     return getAll()
        .where((o) => 
            o.farmId == targetFarmId && 
            o.tipo == tipo && 
            o.ano == ano && 
            !o.deleted!)
        .toList();
  }
  
  // --- Consumo (Integração com Lancamentos) ---
  
  // Nota: Isso exigiria acesso ao LancamentoService. 
  // O ideal é o Controller da UI chamar ambos e mesclar os dados,
  // ou injetar LancamentoService aqui (acoplamento).
  // Para manter arquitetura limpa, vou deixar métodos de cálculo aceitando o valor total
  // ou implementados num Domain Service / UseCase.
}
