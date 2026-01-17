import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class PagamentoOptions {
  // Formas de pagamento: mantém as opções como já estavam
  static const List<String> formasDePagamento = [
    'Boleto',
    'Cheque',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Dinheiro',
    'Outros',
    'Pix/TED',
  ];

  // Mapeamento das formas de pagamento para as strings internacionalizadas
  static Map<String, String> getLocalizedFormasDePagamento(BuildContext context) {
    return {
      'Boleto': S.of(context).bank_slip,
      'Cheque': S.of(context).check,
      'Cartão de Crédito': S.of(context).credit_card,
      'Cartão de Débito': S.of(context).debit_card,
      'Dinheiro': S.of(context).cash,
      'Outros': S.of(context).others,
      'Pix/TED': S.of(context).pix,
    };
  }

  // Retorna a lista de formas de pagamento localizadas
  static List<String> getLocalizedFormasDePagamentoString(BuildContext context) {
    return getLocalizedFormasDePagamento(context).values.toList();
  }

}
