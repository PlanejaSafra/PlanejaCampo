import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class PropriedadeOptions {
  // Auto - Movimentação de Consumo de estoque no ato da entrada (compra). Disponível apenas para licença Admin.
  // Manual - Movimentação de consumo manual (saídas manuais). Disponível para todas as licenças menos AcessoBasico.
  // Desativado - Não movimenta estoque de entrada ou saída. Disponível para todos os tipos de licença.
  static const List<String> modoMovimentacaoEstoque = <String>['Auto', 'Manual', 'Desativado'];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedModoMovimentacaoEstoque(BuildContext context) {
    return {
      'Auto': S.of(context).auto,
      'Manual': S.of(context).manual,
      'Desativado': S.of(context).disabled,
    };
  }
}
