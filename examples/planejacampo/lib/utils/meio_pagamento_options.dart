import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/utils/dias_uteis_options.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
class MeioPagamentoOptions {
  static const List<String> formasDePagamento = [
    'Boleto',
    'Cheque',
    'Crédito',
    'Débito',
    'Dinheiro',
    'Outros',
    'Pix/TED',
  ];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedMeiosDePagamento(BuildContext context) {
    return {
      'Boleto': S.of(context).bank_slip,
      'Cheque': S.of(context).check,
      'Crédito': S.of(context).credit_card,
      'Débito': S.of(context).debit_card,
      'Dinheiro': S.of(context).cash,
      'Outros': S.of(context).others,
      'Pix/TED': S.of(context).pix,
    };
  }

  // Retorna uma lista de meios de pagamento localizadas como Strings
  static List<String> getLocalizedMeiosDePagamentoString(BuildContext context) {
    return getLocalizedMeiosDePagamento(context).values.toList();
  }

  /// Método para verificar se a meio de pagamento requer meio de pagamento
  static bool requiresContaPagamento(String meioPagamento) {
    return ['Cheque', 'Crédito', 'Débito', 'Dinheiro', 'Pix/TED'].contains(meioPagamento);
  }

  // Método para verificar se o tipo de pagamento possui ciclo de faturamento
  static bool requiresFaturamento(String meioPagamento) {
    // Defina quais tipos de pagamento possuem ciclo de faturamento
    const tiposComCiclo = ['Crédito']; // Adicione outros tipos conforme necessário
    return tiposComCiclo.contains(meioPagamento);
  }

  // Método para determinar a conta contábil do meio de pagamento
  String getCodigoContaPagamento(String? meioPagamento) {
    switch (meioPagamento?.toLowerCase()) {
      case 'cartao':
        return ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS;
      case 'cheque':
        return ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS;
      case 'boleto':
        return ContasBaseConfig.FORNECEDORES;
      case 'pix':
      case 'dinheiro':
        return ContasBaseConfig.BANCOS;
      default:
        return ContasBaseConfig.FORNECEDORES;
    }
  }

  static bool deveQuitarAutomaticamente(String meioPagamento, DateTime dataVencimento) {
    // CASO 1: Cartão de Crédito - sempre quitado automaticamente, independente da data
    if (meioPagamento == 'Crédito') {
      return true;
    }

    // CASO 2: Meios de pagamento que dependem da data (PIX/TED, Dinheiro, Débito)
    if (['Pix/TED', 'Dinheiro', 'Débito'].contains(meioPagamento)) {
      // Verificar se a data de vencimento é hoje ou anterior
      // Importante: Ajustar a data atual para o próximo dia útil
      final hoje = DateTime.now();
      final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final dataHojeAjustada = DiasUteisOptions.ajustarParaDiaUtil(dataHoje);

      final dataVencimentoNormalizada = DateTime(
          dataVencimento.year,
          dataVencimento.month,
          dataVencimento.day
      );

      // Se a data de vencimento é anterior ou igual à data de hoje ajustada para dia útil
      return !dataVencimentoNormalizada.isAfter(dataHojeAjustada);
    }

    // CASO 3: Cheque - lógica específica para cheques
    if (meioPagamento == 'Cheque') {
      // Verificar se é lançamento retroativo (data atual ou anterior)
      final hoje = DateTime.now();
      final dataHoje = DateTime(hoje.year, hoje.month, hoje.day);
      final dataVencimentoNormalizada = DateTime(
          dataVencimento.year,
          dataVencimento.month,
          dataVencimento.day
      );

      // Só quita automaticamente se for lançamento retroativo
      return !dataVencimentoNormalizada.isAfter(dataHoje);
    }

    // Para outros meios de pagamento, não quitar automaticamente
    return false;
  }

}
