import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:agro_core/agro_core.dart';

import '../models/balanco_patrimonial.dart';
import '../models/fluxo_caixa.dart';

// Imports de dados (assumindo que existem ou injetados)
import '../services/conta_pagamento_service.dart';
// import '../services/receita_service.dart';
// import '../services/lancamento_service.dart';
// import '../services/conta_service.dart'; 

class RelatorioService {
  static final RelatorioService _instance = RelatorioService._internal();
  factory RelatorioService() => _instance;
  RelatorioService._internal();

  // --- Balanço Patrimonial ---

  Future<BalancoPatrimonial> gerarBalanco(DateTime data) async {
    // 1. Obter todas as contas (Bancos, Caixas) -> ATIVOS
    // final contas = ContaService.instance.getAll().where((c) => c.isActive).toList();
    // Simulação:
    final ativos = <ItemBalanco>[
      // ItemBalanco('Caixa', 1000),
      // for(var c in contas) ItemBalanco(c.nome, c.saldoAtual),
      // ItemBalanco('Contas a Receber', totalAReceber),
    ];

    // 2. Obter dívidas (Contas a Pagar pendentes) -> PASSIVOS
    final contasPagar = ContaPagamentoService.instance.getPendentes();
    final passivos = <ItemBalanco>[
      ItemBalanco('Contas a Pagar', contasPagar.fold(0.0, (sum, c) => sum + c.valor)),
      // Outros passivos (Empréstimos?)
    ];

    final totalAtivos = ativos.fold(0.0, (sum, item) => sum + item.valor);
    final totalPassivos = passivos.fold(0.0, (sum, item) => sum + item.valor);

    return BalancoPatrimonial(
      data: data,
      ativos: ativos,
      passivos: passivos,
      totalAtivos: totalAtivos,
      totalPassivos: totalPassivos,
      patrimonioLiquido: totalAtivos - totalPassivos,
    );
  }

  // --- Fluxo de Caixa ---

  Future<FluxoCaixa> gerarFluxoCaixa(DateTime inicio, DateTime fim) async {
    // Buscar receitas e despesas no período
    // final receitas = ReceitaService.instance.getByPeriod(inicio, fim);
    // final despesas = LancamentoService.instance.getByPeriod(inicio, fim);

    final totalEntradas = 0.0; // receitas.sum...
    final totalSaidas = 0.0; // despesas.sum...
    
    // Calcular Saldos (requer histórico de saldo dia a dia ou snapshot)
    final saldoInicial = 0.0; // ContaService.instance.getSaldoEm(inicio.subtract(1 day));
    final saldoFinal = saldoInicial + totalEntradas - totalSaidas;

    return FluxoCaixa(
      periodo: DateTimeRange(start: inicio, end: fim),
      entradas: {}, // Agrupar por categoria
      saidas: {},
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
      saldoPeriodo: totalEntradas - totalSaidas,
      saldoInicial: saldoInicial,
      saldoFinal: saldoFinal,
    );
  }
}
