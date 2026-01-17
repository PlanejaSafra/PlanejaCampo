import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';

class CollectionOptions {
  static const Map<String, Map<String, String>> collectionRelations = {
    'aplicacoesNutrientes': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'recomendacaoNutrienteId': 'recomendacoesNutrientes'},
    'bancos': {'produtorId': 'produtores'},
    'contas': {'produtorId': 'produtores', 'bancoId': 'bancos'},
    'contasContabeis': {'produtorId': 'produtores', 'contaPaiId': 'contasContabeis'},
    'contasPagar': {'produtorId': 'produtores', 'contaId': 'contas', 'fornecedorId': 'pessoas'},
    'lancamentosContabeis': {'produtorId': 'produtores', 'contaContabilId': 'contasContabeis'},
    'lancamentosContabeisProjetados': {'produtorId': 'produtores', 'contaContabilId': 'contasContabeis'},
    'processamentoContabilStatus': {'produtorId': 'produtores', 'contaContabilId': 'contasContabeis'},
    'abastecimentosFrota': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'frotaId': 'frotas', 'itemId': 'itens', 'compraId': 'compras'},
    'atividadesRurais': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'compras': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'fornecedorId': 'pessoas'},
    'estoques': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'itemId': 'itens'},
    'frotas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'frotaOperacoesRurais': {'produtorId': 'produtores', 'atividadeId': 'atividadesRurais', 'operacaoRuralId': 'operacoesRurais', 'frotaId': 'frotas'},
    'itens': {'produtorId': 'produtores'},
    'itensCompra': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'compraId': 'compras', 'itemId': 'itens'},
    'itensManutencaoFrotas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'manutencaoFrotaId': 'manutencoesFrota', 'itemId': 'itens'},
    'itensOperacaoRural': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'operacaoRuralId': 'operacoesRurais'},
    'manutencoesFrota': {'produtorId': 'produtores', 'frotaId': 'frotas'},
    'movimentacoesEstoque': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'movimentacoesEstoqueProjetadas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'itemId': 'itens'},
    'operacoesRurais': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'pessoas': {'produtorId': 'produtores'},
    'processamentoStatus': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'itemId': 'itens'},
    'producoesRurais': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'atividadeId': 'atividadesRurais', 'operacaoRuralId': 'operacoesRurais', 'itemId': 'itens'},
    'produtores': {},
    'propriedades': {'produtorId': 'produtores'},
    'recomendacoes': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'talhaoId': 'talhoes'},
    'recomendacoesCalagem': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'recomendacaoId': 'recomendacoes'},
    'recomendacoesGessagem': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'recomendacaoId': 'recomendacoes'},
    'recomendacoesNutrientes': {'produtorId': 'produtores', 'propriedadeId': 'propriedades', 'recomendacaoId': 'recomendacoes'},
    'registrosChuvas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'registrosColetas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'registrosEntregas': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'talhoes': {'produtorId': 'produtores', 'propriedadeId': 'propriedades'},
    'tiposOperacaoRural': {'produtorId': 'produtores'},
    // Adicione quaisquer coleções adicionais aqui
  };

  static List<String> getDependentCollections(String collection, String ignoredField) {
    // Ignoramos o parâmetro field e procuramos qualquer referência à collection
    List<String> result = [];

    collectionRelations.forEach((collectionName, relationMap) {
      // Verifica todos os valores no mapa de relações
      if (relationMap.values.contains(collection)) {
        result.add(collectionName);
      }
    });

    return result;
  }

  static String getLocalizedCollectionName(BuildContext context, String collectionName) {
    switch (collectionName) {
      case 'abastecimentosFrota':
        return S.of(context).fleet_refueling;
      case 'atividadesRurais':
        return S.of(context).rural_activities;
      case 'bancos':
        return S.of(context).banks;
      case 'compras':
        return S.of(context).purchases;
      case 'contas':
        return S.of(context).accounts;
      case 'contasContabeis':
        return S.of(context).accounting_accounts;
      case 'contasPagar':
        return S.of(context).accounts_payable;
      case 'estoques':
        return S.of(context).stock;
      case 'frotas':
        return S.of(context).fleets;
      case 'frotaOperacoesRurais':
        return S.of(context).frota_operations;
      case 'itens':
        return S.of(context).items;
      case 'itensCompra':
        return S.of(context).purchase_items;
      case 'itensManutencaoFrotas':
        return S.of(context).maintenance_items;
      case 'itensOperacaoRural':
        return S.of(context).rural_operation_items;
      case 'lancamentosContabeis':
        return S.of(context).accounting_entries;
      case 'lancamentosContabeisProjetados':
        return S.of(context).projected_accounting_entries;
      case 'manutencoesFrota':
        return S.of(context).maintenances;
      case 'movimentacoesEstoque':
        return S.of(context).stock_movements;
      case 'movimentacoesEstoqueProjetadas':
        return S.of(context).projected_movements;
      case 'operacoesRurais':
        return S.of(context).rural_operations;
      case 'pagamentosCompra':
        return S.of(context).purchase_payments;
      case 'pessoas':
        return S.of(context).people;
      case 'processamentoContabilStatus':
        return S.of(context).accounting_processing_status;
      case 'processamentoStatus':
        return S.of(context).processing_status;
      case 'producoesRurais':
        return S.of(context).rural_productions;
      case 'propriedades':
        return S.of(context).agricultural_properties;
      case 'registrosChuvas':
        return S.of(context).rain_records;
      case 'registrosColetas':
        return S.of(context).collection_records;
      case 'registrosEntregas':
        return S.of(context).delivery_records;
      case 'talhoes':
        return S.of(context).plots;
      case 'tiposOperacaoRural':
        return S.of(context).rural_operation_types;
      default:
        return collectionName;
    }
  }

  static const Set<String> _collectionsWithoutProducerId = {
    'culturasParametro',
    'faixasInterpretacaoSolo',
    'parametrosCalagem',
    // Adicionar outras coleções globais aqui
  };

  /// Verifica se uma coleção requer filtro por produtorId
  static bool requiresProducerId(String collection) {
    // Produtores é uma coleção especial que não requer filtro por produtor,
    // mas tem permissões especiais
    if (collection == 'produtores') return false;

    // Verificar se a coleção está na lista de exceções
    return !_collectionsWithoutProducerId.contains(collection);
  }
}
