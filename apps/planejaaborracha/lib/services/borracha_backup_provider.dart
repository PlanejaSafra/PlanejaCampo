import 'package:agro_core/agro_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/parceiro.dart';
import '../models/entrega.dart';
import '../models/item_entrega.dart';
import '../services/parceiro_service.dart';
import '../services/entrega_service.dart';

/// Provider for Planeja Borracha backup data.
///
/// Implements the BackupProvider interface for cloud sync integration.
class BorrachaBackupProvider implements BackupProvider {
  @override
  String get key => 'planeja_borracha';

  @override
  Future<Map<String, dynamic>> getData() async {
    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    final parceiros = parceiroService.parceiros;
    final entregas = entregaService.entregas;

    return {
      'version': '1.0.0', // Schema version
      'parceiros': parceiros
          .map((p) => {
                'id': p.id,
                'nome': p.nome,
                'percentualPadrao': p.percentualPadrao,
                'telefone': p.telefone,
              })
          .toList(),
      'entregas': entregas
          .map((e) => {
                'id': e.id,
                'data': e.data.toIso8601String(),
                'compradorId': e.compradorId,
                'status': e.status,
                'itens': e.itens
                    .map((item) => {
                          'parceiroId': item.parceiroId,
                          'pesagens': item.pesagens,
                          'pesoTotal': item.pesoTotal,
                          'valorTotal': item.valorTotal,
                          'descontos': item.descontos,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    if (data['parceiros'] == null && data['entregas'] == null) return;

    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    // CLEAR existing data first (restore = replace, not merge)
    await parceiroService.clearAll();
    await entregaService.clearAll();

    int parceirosImported = 0;
    int entregasImported = 0;

    // Restore Parceiros
    if (data['parceiros'] != null) {
      final parceirosList = data['parceiros'] as List;
      for (final p in parceirosList) {
        final parceiro = Parceiro(
          id: p['id'] as String,
          nome: p['nome'] as String,
          percentualPadrao: (p['percentualPadrao'] as num).toDouble(),
          telefone: p['telefone'] as String?,
        );
        await parceiroService.addParceiro(parceiro);
        parceirosImported++;
      }
    }

    // Restore Entregas
    if (data['entregas'] != null) {
      final entregasList = data['entregas'] as List;
      final box = await Hive.openBox<Entrega>(EntregaService.boxName);

      for (final e in entregasList) {
        final entrega = Entrega(
          id: e['id'] as String,
          data: DateTime.parse(e['data'] as String),
          compradorId: e['compradorId'] as String?,
          status: e['status'] as String,
          itens: (e['itens'] as List)
              .map((item) => ItemEntrega(
                    parceiroId: item['parceiroId'] as String,
                    pesagens: (item['pesagens'] as List)
                        .map((p) => (p as num).toDouble())
                        .toList(),
                    pesoTotal: (item['pesoTotal'] as num).toDouble(),
                    valorTotal: (item['valorTotal'] as num).toDouble(),
                    descontos: (item['descontos'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList(),
        );
        await box.put(entrega.id, entrega);
        entregasImported++;
      }

      await entregaService.init(); // Refresh service state
    }

    debugPrint(
        '[BorrachaBackup] Restored $parceirosImported parceiros, $entregasImported entregas (cleared existing first).');
  }
}
