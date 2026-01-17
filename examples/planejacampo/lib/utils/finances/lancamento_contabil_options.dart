import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

import 'index.dart';

class LancamentoContabilOptions {
  static const List<String> tipos = <String>['Debito', 'Credito'];

  static const List<String> categoriasDebito = <String>[
    'Compra',
    'Pagamento',
    'Impostos',
    'TransferenciaSaida',
    'EstornoEntrada',
    'OutrasSaidas',
  ];

  static const List<String> categoriasCredito = <String>[
    'Venda',
    'Recebimento',
    'TransferenciaEntrada',
    'EstornoSaida',
    'OutrasEntradas',
  ];

  static Map<String, String> getLocalizedTipos(BuildContext context) {
    return {
      'Debito': S.of(context).debit,
      'Credito': S.of(context).credit,
    };
  }

  static Map<String, String> getLocalizedCategorias(BuildContext context) {
    return {
      'Compra': S.of(context).purchase,
      'Pagamento': S.of(context).payment,
      'Impostos': S.of(context).taxes,
      'TransferenciaSaida': S.of(context).transfer_out,
      'EstornoEntrada': S.of(context).inflow_reversal,
      'OutrasSaidas': S.of(context).other_outflows,
      'Venda': S.of(context).sale,
      'Recebimento': S.of(context).receivement,
      'TransferenciaEntrada': S.of(context).transfer_in,
      'EstornoSaida': S.of(context).outflow_reversal,
      'OutrasEntradas': S.of(context).other_inflows,
    };
  }

  // Funções de validação de categorias contábeis
  static bool isEstorno(String categoria) {
    return categoria.startsWith('Estorno');
  }

  static bool isTransferencia(String categoria) {
    return categoria.startsWith('Transferencia');
  }

  static bool requerContaDestino(String categoria) {
    return isTransferencia(categoria);
  }

  // Calcula o novo saldo após um lançamento contábil
  static Map<String, dynamic> calcularSaldo({
    required String tipo,
    required String categoria,
    required double valor,
    required double saldoAtual,
    required String naturezaConta,
  }) {
    bool ehEstorno = categoria.startsWith('Estorno');
    double novoSaldo = saldoAtual;

    if (naturezaConta == 'credora') {
      if (ehEstorno) {
        // Para estornos em contas credoras, inverte a lógica
        novoSaldo += (tipo == 'Debito' ? -valor : valor);
      } else {
        // Lançamentos normais em contas credoras
        novoSaldo += (tipo == 'Credito' ? valor : -valor);
      }
    } else {
      if (ehEstorno) {
        // Para estornos em contas devedoras, inverte a lógica
        novoSaldo += (tipo == 'Credito' ? -valor : valor);
      } else {
        // Lançamentos normais em contas devedoras
        novoSaldo += (tipo == 'Debito' ? valor : -valor);
      }
    }

    return {
      'novoSaldo': novoSaldo,
      'ativo': true,
    };
  }


  static bool precisaCriarConsumoAutomatico(String tipo, String categoria) {
    // Ajuste conforme sua lógica de “consumo automático”
    return tipo == 'Credito' &&
        [
          'Compra',
          'Ajuste',
          'TransferenciaEntrada',
          'Doacao',
          'Bonificacao'
        ].contains(categoria);
  }

}
