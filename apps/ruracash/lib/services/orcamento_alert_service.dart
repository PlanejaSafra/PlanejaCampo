import 'package:agro_core/agro_core.dart';
import '../models/orcamento.dart';
import 'orcamento_service.dart';

class OrcamentoAlertService {
  final OrcamentoService _orcamentoService = OrcamentoService.instance;
  final NotificationService _notificationService = NotificationService.instance; // from agro_core

  /// Verifica se um lançamento estoura o orçamento e envia alerta
  Future<void> checkAlert(String categoriaId, double valorNovoLancamento, double valorTotalConsumidoAtual) async {
    final now = DateTime.now();
    final orcamento = _orcamentoService.getOrcamentoAtivo(categoriaId, now);
    
    if (orcamento == null || !orcamento.alertaAtivo) return;

    final totalFuturo = valorTotalConsumidoAtual + valorNovoLancamento;
    final percentual = (totalFuturo / orcamento.valorLimite) * 100;

    if (percentual >= orcamento.alertaPercentual) {
      final estouro = totalFuturo > orcamento.valorLimite;
      
      await _notificationService.showNotification(
        id: orcamento.id.hashCode, // simples hash ID
        title: 'Alerta de Orçamento',
        body: estouro 
            ? 'Você ultrapassou o orçamento de ${orcamento.categoriaId}!'
            : 'Atenção: Você atingiu ${percentual.toInt()}% do orçamento de ${orcamento.categoriaId}.',
      );
    }
  }
}
