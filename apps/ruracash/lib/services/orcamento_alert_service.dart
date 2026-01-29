import 'package:flutter/foundation.dart';
import 'package:agro_core/agro_core.dart';
import '../l10n/cash_l10n_helper.dart';
import 'orcamento_service.dart';

class OrcamentoAlertService {
  final OrcamentoService _orcamentoService = OrcamentoService.instance;

  static const int _budgetAlertNotificationId = 9000;

  /// Verifica se um lançamento estoura o orçamento e envia alerta
  Future<void> checkAlert(String categoriaId, double valorNovoLancamento, double valorTotalConsumidoAtual) async {
    final now = DateTime.now();
    final orcamento = _orcamentoService.getOrcamentoAtivo(categoriaId, now);

    if (orcamento == null || !orcamento.alertaAtivo) return;

    final totalFuturo = valorTotalConsumidoAtual + valorNovoLancamento;
    final percentual = (totalFuturo / orcamento.valorLimite) * 100;

    if (percentual >= orcamento.alertaPercentual) {
      final estouro = totalFuturo > orcamento.valorLimite;
      final l10n = lookupCashLocalizations();

      final title = l10n.cashOrcamentoAlertTitle;
      final body = estouro
          ? l10n.cashOrcamentoAlertExceeded(orcamento.categoriaId)
          : l10n.cashOrcamentoAlertWarning(percentual.toInt().toString(), orcamento.categoriaId);

      try {
        await AgroNotificationService.instance.showNotification(
          id: _budgetAlertNotificationId + categoriaId.hashCode.abs() % 1000,
          title: title,
          body: body,
          channelId: 'budget_alerts',
          channelName: 'Alertas de Orçamento',
          channelDescription: 'Alertas quando o orçamento é atingido ou estourado',
          payload: 'budget_alert:$categoriaId',
        );
      } catch (e) {
        debugPrint('[OrcamentoAlertService] Notification failed: $e');
      }
    }
  }
}
