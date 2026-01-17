// lib/utils/finances/historico_contabil_config.dart

import 'package:planejacampo/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/atividade_rural.dart';

/// Configuração para geração de históricos padronizados para lançamentos contábeis
class HistoricoContabilConfig {

  /// Gera histórico padrão para operações contábeis
  static String gerarHistorico({
    required BuildContext context,
    required String operacao,
    required String tipo,
    AtividadeRural? atividadeRural,
    Item? item,
    String? complemento,
  }) {
    String historico = '';

    // Adiciona o tipo de operação
    historico = _getOperacaoLocalizada(context, operacao);

    // Adiciona o tipo (débito/crédito)
    if (tipo.isNotEmpty) {
      historico += ' - ${_getTipoLocalizado(context, tipo)}';
    }

    // Adiciona informação da atividade rural se disponível
    if (atividadeRural != null) {
      historico += ' - ${atividadeRural.tipo} - ${atividadeRural.subtipo}';
    }

    // Adiciona informação do item se disponível
    if (item != null) {
      historico += ' - ${item.nome}';
    }

    // Adiciona complemento se fornecido
    if (complemento != null && complemento.isNotEmpty) {
      historico += ' - $complemento';
    }

    return historico;
  }

  /// Gera histórico para estornos
  static String gerarHistoricoEstorno({
    required BuildContext context,
    required String operacao,
    required String documentoOriginal,
    String? complemento,
  }) {
    String historico = S.of(context).reversal_of;  // "Estorno de"
    historico += ' ${_getOperacaoLocalizada(context, operacao)}';
    historico += ' - ${S.of(context).original_document}: $documentoOriginal';

    if (complemento != null && complemento.isNotEmpty) {
      historico += ' - $complemento';
    }

    return historico;
  }

  /// Gera histórico para transferências entre contas
  static String gerarHistoricoTransferencia({
    required BuildContext context,
    required String contaOrigem,
    required String contaDestino,
    String? complemento,
  }) {
    String historico = '${S.of(context).transfer_between_accounts}'; // "Transferência entre contas"
    historico += ' - ${S.of(context).from}: $contaOrigem';
    historico += ' - ${S.of(context).to}: $contaDestino';

    if (complemento != null && complemento.isNotEmpty) {
      historico += ' - $complemento';
    }

    return historico;
  }

  /// Gera histórico para reclassificações
  static String gerarHistoricoReclassificacao({
    required BuildContext context,
    required String contaOriginal,
    required String contaNova,
    String? motivo,
  }) {
    String historico = '${S.of(context).account_reclassification}';  // "Reclassificação de conta"
    historico += ' - ${S.of(context).from}: $contaOriginal';
    historico += ' - ${S.of(context).to}: $contaNova';

    if (motivo != null && motivo.isNotEmpty) {
      historico += ' - ${S.of(context).reason}: $motivo';
    }

    return historico;
  }

  /// Gera histórico para apropriações periódicas
  static String gerarHistoricoApropriacao({
    required BuildContext context,
    required String tipo,
    required String periodo,
    AtividadeRural? atividadeRural,
    String? complemento,
  }) {
    String historico = '${S.of(context).appropriation_of} ${_getTipoApropriacaoLocalizado(context, tipo)}';  // "Apropriação de"
    historico += ' - ${S.of(context).period}: $periodo';

    if (atividadeRural != null) {
      historico += ' - ${atividadeRural.tipo} - ${atividadeRural.subtipo}';
    }

    if (complemento != null && complemento.isNotEmpty) {
      historico += ' - $complemento';
    }

    return historico;
  }

  /// Gera histórico para ajustes de inventário
  static String gerarHistoricoAjusteInventario({
    required BuildContext context,
    required String tipo,
    required Item item,
    String? motivo,
  }) {
    String historico = '${S.of(context).inventory_adjustment}';  // "Ajuste de inventário"
    historico += ' - ${_getTipoAjusteLocalizado(context, tipo)}';
    historico += ' - ${item.nome}';

    if (motivo != null && motivo.isNotEmpty) {
      historico += ' - ${S.of(context).reason}: $motivo';
    }

    return historico;
  }

  /// Obtém a descrição localizada da operação
  static String _getOperacaoLocalizada(BuildContext context, String operacao) {
    switch (operacao) {
      case 'CompraInsumos':
        return S.of(context).input_purchase;
      case 'VendaProducao':
        return S.of(context).production_sale;
      case 'PagamentoFornecedor':
        return S.of(context).supplier_payment;
      case 'RecebimentoCliente':
        return S.of(context).customer_receipt;
      default:
        return operacao;
    }
  }

  /// Obtém a descrição localizada do tipo de lançamento
  static String _getTipoLocalizado(BuildContext context, String tipo) {
    switch (tipo.toLowerCase()) {
      case 'debito':
        return S.of(context).debit;
      case 'credito':
        return S.of(context).credit;
      default:
        return tipo;
    }
  }

  /// Obtém a descrição localizada do tipo de apropriação
  static String _getTipoApropriacaoLocalizado(BuildContext context, String tipo) {
    switch (tipo.toLowerCase()) {
      case 'depreciacao':
        return S.of(context).depreciation;
      case 'amortizacao':
        return S.of(context).amortization;
      case 'custos':
        return S.of(context).costs;
      default:
        return tipo;
    }
  }

  /// Obtém a descrição localizada do tipo de ajuste
  static String _getTipoAjusteLocalizado(BuildContext context, String tipo) {
    switch (tipo.toLowerCase()) {
      case 'quebra':
        return S.of(context).breakage;
      case 'perda':
        return S.of(context).loss;
      case 'sobra':
        return S.of(context).surplus;
      default:
        return tipo;
    }
  }
}