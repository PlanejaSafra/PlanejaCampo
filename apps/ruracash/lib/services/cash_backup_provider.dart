import 'package:agro_core/agro_core.dart';
import '../services/lancamento_service.dart';
import '../services/centro_custo_service.dart';
import '../models/lancamento.dart';
import '../models/centro_custo.dart';

class CashBackupProvider implements BackupProvider {
  @override
  String get key => 'ruracash_backup';

  @override
  Future<Map<String, dynamic>> getData() async {
    // Backup ALL local data for this app
    final lancamentos = LancamentoService.instance.getAll();
    final centros = CentroCustoService.instance.getAll();

    return {
      'version': '1.0.0',
      'lancamentos': lancamentos.map((e) => e.toJson()).toList(),
      'centro_custos': centros.map((e) => e.toJson()).toList(),
    };
  }

  @override
  Future<void> restoreData(Map<String, dynamic> data) async {
    final lancamentosRaw = data['lancamentos'] as List<dynamic>? ?? [];
    final centrosRaw = data['centro_custos'] as List<dynamic>? ?? [];

    for (var map in centrosRaw) {
      try {
        final item = CentroCusto.fromJson(map);
        if (CentroCustoService.instance.getById(item.id) != null) {
          await CentroCustoService.instance.update(item.id, item);
        } else {
          await CentroCustoService.instance.add(item);
        }
      } catch (e) {
        // ignore
      }
    }

    for (var map in lancamentosRaw) {
      try {
        final item = Lancamento.fromJson(map);
        if (LancamentoService.instance.getById(item.id) != null) {
          await LancamentoService.instance.update(item.id, item);
        } else {
          await LancamentoService.instance.add(item);
        }
      } catch (e) {
        // ignore
      }
    }
  }
}
