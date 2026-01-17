import 'dart:math';

import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/movimentacao_estoque.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';

class MovimentacaoEstoqueOptions {
  static const List<String> tipo = <String>['Entrada', 'Saida'];
  static const List<String> categoria = <String>[
    'Compra',
    'Transferencia',
    'EstornoCompra',
    'EstornoConsumo',
    'EstornoVenda',
    'EstornoDevolucao',
    'EstornoTransferencia',
    'Consumo',
    'Venda',
    'DevolucaoCompra',
    'DevolucaoVenda',
    'DevolucaoConsumo',
    'DevolucaoTransferencia',
    'Perda',
    'Doacao',
    'Bonificacao',
    'Processamento',
    'Colheita'
  ];

  static Map<String, String> getLocalizedTipo(BuildContext context) {
    return {
      'Entrada': S.of(context).entry,
      'Saida': S.of(context).exit,
    };
  }

  static Map<String, String> getLocalizedCategoria(BuildContext context) {
    return {
      'Compra': S.of(context).purchase,
      'Transferencia': S.of(context).transfer,
      'EstornoCompra': S.of(context).purchase_reversal,
      'EstornoConsumo': S.of(context).consumption_reversal,
      'EstornoVenda': S.of(context).sales_reversal,
      'EstornoDevolucao': S.of(context).return_reversal,
      'EstornoTransferencia': S.of(context).transfer_reversal,
      'Consumo': S.of(context).consumption,
      'Venda': S.of(context).sale,
      'DevolucaoCompra': S.of(context).purchase_return,
      'DevolucaoVenda': S.of(context).sales_return,
      'DevolucaoConsumo': S.of(context).consumption_return,
      'DevolucaoTransferencia': S.of(context).transfer_return,
      'Perda': S.of(context).loss,
      'Doacao': S.of(context).donation,
      'Bonificacao': S.of(context).bonus,
      'Processamento': S.of(context).processing,
      'Colheita': S.of(context).type_harvest
    };
  }

  static Map<String, dynamic> calcularQuantidadeECMP({
    required String tipo,
    required String categoria,
    required String modoMovimentacaoEstoque,
    required double quantidadeConvertida,
    required double valorUnitarioConvertido,
    required double quantidadeEstoque,
    required double cmpEstoque,
  }) {
    double novaQuantidadeEstoque = quantidadeEstoque;
    double novoCMP = cmpEstoque;
    double quantidadeEstorno = 0.0;
    bool ativo = false;
    bool requerCalculoDecaimento = false;

    if (modoMovimentacaoEstoque == 'Auto') {
      if (categoria.startsWith('Estorno')) {
        if (tipo == 'Entrada') { // EstornoConsumo
          novaQuantidadeEstoque = quantidadeEstoque + quantidadeConvertida;
          novoCMP = cmpEstoque;
        } else { // EstornoCompra
          quantidadeEstorno = quantidadeEstoque;
          novaQuantidadeEstoque = quantidadeEstoque;
          novoCMP = cmpEstoque;
          requerCalculoDecaimento = false;
        }
      } else if (tipo == 'Entrada') {
        ativo = true;
        novaQuantidadeEstoque = quantidadeEstoque + quantidadeConvertida;
        // Cálculo do CMP para entradas normais
        novoCMP = (quantidadeEstoque * cmpEstoque + quantidadeConvertida * valorUnitarioConvertido) /
            (quantidadeEstoque + quantidadeConvertida);
        requerCalculoDecaimento = false; // Não usar decaimento para compras normais
      } else if (tipo == 'Saida') {
        ativo = true;
        novaQuantidadeEstoque = quantidadeEstoque - quantidadeConvertida;
        novoCMP = cmpEstoque; // Mantém o CMP em saídas
      }
    } else { // Modo Manual
      ativo = true;
      if (categoria.startsWith('Estorno')) {
        if (tipo == 'Entrada') {
          novaQuantidadeEstoque = quantidadeEstoque;
          novoCMP = cmpEstoque;
        } else { // EstornoCompra
          quantidadeEstorno = quantidadeEstoque;
          novaQuantidadeEstoque = quantidadeEstoque;
          novoCMP = cmpEstoque;
          requerCalculoDecaimento = false;
        }
      } else if (tipo == 'Entrada') {
        novaQuantidadeEstoque = quantidadeEstoque + quantidadeConvertida;
        // Mesmo cálculo do CMP para modo manual
        novoCMP = (quantidadeEstoque * cmpEstoque + quantidadeConvertida * valorUnitarioConvertido) /
            (quantidadeEstoque + quantidadeConvertida);
      } else { // Saída
        novaQuantidadeEstoque = quantidadeEstoque - quantidadeConvertida;
        novoCMP = cmpEstoque; // Mantém o CMP em saídas
      }
    }

    return {
      'novaQuantidadeEstoque': novaQuantidadeEstoque,
      'novoCMP': novoCMP,
      'quantidadeEstorno': quantidadeEstorno,
      'ativo': ativo,
      'requerCalculoDecaimento': requerCalculoDecaimento,
    };
  }

  static bool precisaCriarConsumoAutomatico(String tipo, String categoria) {
    return tipo == 'Entrada' && [
      'Compra',
      'Ajuste',
      'Transferencia',
      'Doacao',
      'Bonificacao'
    ].contains(categoria);
  }

  double calcularCMPComDecaimento({
    required Item item,
    required double novoValor,
    required double novaQuantidade,
    required DateTime dataMovimentacao,
    required double cmpHistorico,
    required double estoqueAnterior,
    required DateTime dataUltimaAtualizacao,
  }) {
    int diasDesdeUltimaAtualizacao = dataMovimentacao.difference(dataUltimaAtualizacao).inDays;
    double fatorDecaimento = pow(item.fatorDecaimento, diasDesdeUltimaAtualizacao / 30.0).toDouble();

    double cmpMedio;
    if (estoqueAnterior > 0) {
      cmpMedio = ((cmpHistorico * estoqueAnterior) + (novoValor * novaQuantidade)) /
          (estoqueAnterior + novaQuantidade);
    } else if (cmpHistorico > 0) {
      cmpMedio = (cmpHistorico + novoValor) / 2;
    } else {
      cmpMedio = novoValor;
    }

    return cmpMedio * fatorDecaimento + novoValor * (1 - fatorDecaimento);
  }

}