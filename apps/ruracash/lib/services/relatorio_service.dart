import 'package:flutter/material.dart';
import 'package:agro_core/agro_core.dart';

import '../models/balanco_patrimonial.dart';
import '../models/fluxo_caixa.dart';
import '../l10n/cash_l10n_helper.dart';
import 'conta_pagamento_service.dart';
import 'conta_recebimento_service.dart';
import 'conta_service.dart';
import 'lancamento_service.dart';
import 'receita_service.dart';

class RelatorioService {
  static final RelatorioService _instance = RelatorioService._internal();
  factory RelatorioService() => _instance;
  RelatorioService._internal();

  // --- Balanço Patrimonial ---

  Future<BalancoPatrimonial> gerarBalanco(DateTime data) async {
    final l10n = lookupCashLocalizations();

    // 1. ATIVOS (o que o produtor TEM)
    final ativos = <ItemBalanco>[];

    // CASH-23: Saldos de contas bancárias (ativos)
    for (final conta in ContaService.instance.contasAtivo) {
      if (conta.saldoAtual > 0) {
        ativos.add(ItemBalanco(conta.nome, conta.saldoAtual));
      }
    }

    // Contas a Receber pendentes
    final contasReceber = ContaRecebimentoService().getPendentes();
    final totalAReceber = contasReceber.fold(0.0, (sum, c) => sum + c.valor);
    if (totalAReceber > 0) {
      ativos.add(ItemBalanco(l10n.dreReceitas, totalAReceber));
    }

    // 2. PASSIVOS (o que o produtor DEVE)
    final passivos = <ItemBalanco>[];

    // CASH-23: Saldos de contas passivas (cartão, empréstimo)
    for (final conta in ContaService.instance.contasPassivo) {
      if (conta.saldoAtual > 0) {
        passivos.add(ItemBalanco(conta.nome, conta.saldoAtual));
      }
    }

    // Contas a Pagar pendentes
    final contasPagar = ContaPagamentoService.instance.getPendentes();
    final totalAPagar = contasPagar.fold(0.0, (sum, c) => sum + c.valor);
    if (totalAPagar > 0) {
      passivos.add(ItemBalanco(l10n.dreDespesas, totalAPagar));
    }

    // Calcular totais
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
    // 1. SAÍDAS: Lançamentos (despesas) no período
    final lancamentos = LancamentoService.instance.getLancamentosPorPeriodo(inicio, fim);
    final totalSaidas = lancamentos.fold(0.0, (sum, l) => sum + l.valor);

    // Agrupar saídas por categoria
    final saidasPorCategoria = <String, double>{};
    for (final l in lancamentos) {
      final categoria = CategoriaService().getById(l.categoriaId);
      final catName = categoria?.nome ?? 'Outros';
      saidasPorCategoria[catName] = (saidasPorCategoria[catName] ?? 0) + l.valor;
    }

    // 2. ENTRADAS: Receitas (CASH-24) + Contas Recebidas no período
    double totalEntradas = 0.0;
    final entradasPorCategoria = <String, double>{};

    // CASH-24: Receitas registradas
    final receitas = ReceitaService.instance.getReceitasPorPeriodo(inicio, fim);
    for (final r in receitas) {
      totalEntradas += r.valor;
      final cat = CategoriaService().getById(r.categoriaId);
      final catName = cat?.nome ?? 'Receita';
      entradasPorCategoria[catName] = (entradasPorCategoria[catName] ?? 0) + r.valor;
    }

    // Contas Recebidas no período (legacy)
    final todasContasReceber = ContaRecebimentoService().getAll();
    final contasRecebidas = todasContasReceber.where((c) =>
        c.dataRecebimento != null &&
        !c.dataRecebimento!.isBefore(inicio) &&
        c.dataRecebimento!.isBefore(fim.add(const Duration(days: 1))));

    for (final c in contasRecebidas) {
      totalEntradas += c.valor;
      final cat = c.descricao.isNotEmpty ? c.descricao : 'Receita';
      entradasPorCategoria[cat] = (entradasPorCategoria[cat] ?? 0) + c.valor;
    }

    // 3. Calcular saldos — CASH-23: usar saldo real das contas
    final saldoInicial = ContaService.instance.totalAtivos;
    final saldoPeriodo = totalEntradas - totalSaidas;
    final saldoFinal = saldoInicial + saldoPeriodo;

    return FluxoCaixa(
      periodo: DateTimeRange(start: inicio, end: fim),
      entradas: entradasPorCategoria,
      saidas: saidasPorCategoria,
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
      saldoPeriodo: saldoPeriodo,
      saldoInicial: saldoInicial,
      saldoFinal: saldoFinal,
    );
  }
}
