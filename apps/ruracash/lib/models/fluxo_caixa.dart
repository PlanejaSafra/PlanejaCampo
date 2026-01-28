import 'package:flutter/material.dart';

class FluxoCaixa {
  final DateTimeRange periodo;
  
  /// Agrupado por categoria (Map<CategoriaNome, Total>)
  final Map<String, double> entradas;
  final Map<String, double> saidas;
  
  final double totalEntradas;
  final double totalSaidas;
  
  /// "RESULTADO · quanto sobrou"
  final double saldoPeriodo;
  
  /// "Você começou Janeiro com"
  final double saldoInicial;
  
  /// "Você terminou Janeiro com"
  final double saldoFinal;

  const FluxoCaixa({
    required this.periodo,
    required this.entradas,
    required this.saidas,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldoPeriodo,
    required this.saldoInicial,
    required this.saldoFinal,
  });
}

class FluxoCaixaMensal {
  final int mes;
  final int ano;
  final double totalEntradas;
  final double totalSaidas;
  final double saldo;

  const FluxoCaixaMensal({
    required this.mes,
    required this.ano,
    required this.totalEntradas,
    required this.totalSaidas,
    required this.saldo,
  });
}
