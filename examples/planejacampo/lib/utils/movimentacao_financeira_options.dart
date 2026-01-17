import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class MovimentacaoFinanceiraOptions {
  static const List<String> tipos = <String>['Credito', 'Debito'];

  static const List<String> categoriasCredito = <String>[
    'Venda',
    'Recebimento',
    'TransferenciaEntrada',
    'EstornoSaida',
    'Emprestimo',
    'Investimento',
    'OutrasEntradas',
  ];

  static const List<String> categoriasDebito = <String>[
    'Compra',
    'Pagamento',
    'TransferenciaSaida',
    'EstornoEntrada',
    'DevolucaoEmprestimo',
    'ResgateDinheiro',
    'OutrasSaidas'
  ];

  static Map<String, String> getLocalizedTipos(BuildContext context) {
    return {
      'Credito': S.of(context).credit,
      'Debito': S.of(context).debit,
    };
  }

  static Map<String, String> getLocalizedCategorias(BuildContext context) {
    final categorias = {
      'Venda': S.of(context).sale,
      'Recebimento': S.of(context).receivement,
      'TransferenciaEntrada': S.of(context).transfer_in,
      'EstornoSaida': S.of(context).outflow_reversal,
      'Emprestimo': S.of(context).loan,
      'Investimento': S.of(context).investment,
      'OutrasEntradas': S.of(context).other_inflows,
      'Compra': S.of(context).purchase,
      'Pagamento': S.of(context).payment,
      'TransferenciaSaida': S.of(context).transfer_out,
      'EstornoEntrada': S.of(context).inflow_reversal,
      'DevolucaoEmprestimo': S.of(context).loan_repayment,
      'ResgateDinheiro': S.of(context).money_withdrawal,
      'OutrasSaidas': S.of(context).other_outflows,
    };
    return categorias;
  }

  // Funções de validação de movimentação
  static bool isEstorno(String categoria) {
    return categoria.startsWith('Estorno');
  }

  static bool isTransferencia(String categoria) {
    return categoria.startsWith('Transferencia');
  }

  static bool requerContaDestino(String categoria) {
    return isTransferencia(categoria);
  }

  // Calcula o novo saldo após uma movimentação
  static Map<String, dynamic> calcularSaldo({
    required String tipo,
    required String categoria,
    required double valor,
    required double saldoAtual,
  }) {
    double novoSaldo = saldoAtual;
    bool ativo = true;

    if (isEstorno(categoria)) {
      ativo = false;
    }

    if (tipo == 'Credito') {
      novoSaldo += valor;
    } else {
      novoSaldo -= valor;
    }

    return {
      'novoSaldo': novoSaldo,
      'ativo': ativo,
    };
  }
}