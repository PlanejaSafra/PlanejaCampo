import 'dart:convert';
import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/parceiro.dart';
import '../models/entrega.dart';
import '../models/item_entrega.dart';
import '../services/parceiro_service.dart';
import '../services/entrega_service.dart';

/// Result of an import operation.
class ImportResult {
  final int importedParceiros;
  final int importedEntregas;
  final int duplicates;

  ImportResult({
    required this.importedParceiros,
    required this.importedEntregas,
    required this.duplicates,
  });
}

/// Service for local backup and restore operations (JSON file).
class BackupService {
  static const String _appVersion = '1.0.0';

  /// Exports all data to a JSON file and shares it.
  static Future<void> exportar() async {
    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    final parceiros = parceiroService.parceiros;
    final entregas = entregaService.entregas;

    if (parceiros.isEmpty && entregas.isEmpty) {
      throw Exception('Nenhum dado para exportar');
    }

    final backup = {
      'app': 'planeja_borracha',
      'version': _appVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'totalParceiros': parceiros.length,
      'totalEntregas': entregas.length,
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

    final jsonString = const JsonEncoder.withIndent('  ').convert(backup);

    // Write to temp file
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file =
        File('${directory.path}/planeja_borracha_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    // Share the file
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Backup RuraRubber',
      text:
          'Backup de ${parceiros.length} parceiros e ${entregas.length} entregas',
    );
  }

  /// Parses a JSON backup string and returns parceiros and entregas.
  static Map<String, List<dynamic>> parseBackup(String jsonString) {
    try {
      final data = json.decode(jsonString) as Map<String, dynamic>;

      // Validate backup structure
      if (data['app'] != 'planeja_borracha') {
        throw Exception('Arquivo de backup inválido');
      }

      final parceiros = (data['parceiros'] as List?)
              ?.map((p) => Parceiro(
                    id: p['id'] as String,
                    nome: p['nome'] as String,
                    percentualPadrao: (p['percentualPadrao'] as num).toDouble(),
                    telefone: p['telefone'] as String?,
                  ))
              .toList() ??
          [];

      final entregas = (data['entregas'] as List?)
              ?.map((e) => Entrega(
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
                              valorTotal:
                                  (item['valorTotal'] as num).toDouble(),
                              descontos: (item['descontos'] as num?)?.toDouble() ?? 0.0,
                            ))
                        .toList(),
                  ))
              .toList() ??
          [];

      return {
        'parceiros': parceiros,
        'entregas': entregas,
      };
    } catch (e) {
      throw Exception('Erro ao processar backup: $e');
    }
  }

  /// Imports data from a parsed backup, avoiding duplicates.
  static Future<ImportResult> importar(
    List<Parceiro> parceiros,
    List<Entrega> entregas,
  ) async {
    final parceiroService = ParceiroService();
    final entregaService = EntregaService();

    await parceiroService.init();
    await entregaService.init();

    // Import parceiros
    final existingParceiroIds =
        parceiroService.parceiros.map((p) => p.id).toSet();
    int importedParceiros = 0;
    int duplicates = 0;

    for (final parceiro in parceiros) {
      if (existingParceiroIds.contains(parceiro.id)) {
        duplicates++;
      } else {
        await parceiroService.addParceiro(parceiro);
        importedParceiros++;
      }
    }

    // Import entregas - save directly to Hive box
    final entregaBox = await Hive.openBox<Entrega>(EntregaService.boxName);
    final existingEntregaIds = entregaBox.values.map((e) => e.id).toSet();
    int importedEntregas = 0;

    for (final entrega in entregas) {
      if (existingEntregaIds.contains(entrega.id)) {
        duplicates++;
      } else {
        await entregaBox.put(entrega.id, entrega);
        importedEntregas++;
      }
    }

    // Refresh service to pick up new data
    await entregaService.init();

    return ImportResult(
      importedParceiros: importedParceiros,
      importedEntregas: importedEntregas,
      duplicates: duplicates,
    );
  }
}
