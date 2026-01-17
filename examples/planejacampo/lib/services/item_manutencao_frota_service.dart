import 'package:planejacampo/models/item_manutencao_frota.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'generic_service.dart';

class ItemManutencaoFrotaService extends GenericService<ItemManutencaoFrota> {
  final MovimentacaoEstoqueProjetadaService _movimentacaoEstoqueService = MovimentacaoEstoqueProjetadaService();
  final LancamentoContabilProjetadoService _lancamentoContabilProjetadoService = LancamentoContabilProjetadoService();
  final ContaContabilService _contaContabilService = ContaContabilService();
  final Duration defaultTimeout = const Duration(seconds: 3);
  final languageCode = AppStateManager().appLocale.languageCode;

  ItemManutencaoFrotaService() : super('itensManutencaoFrota');

  @override
  ItemManutencaoFrota fromMap(Map<String, dynamic> map, String documentId) {
    return ItemManutencaoFrota.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ItemManutencaoFrota itemManutencaoFrota) {
    return itemManutencaoFrota.toMap();
  }

  @override
  Future<String?> add(ItemManutencaoFrota itemManutencaoFrota,
      {bool returnId = false, Duration? timeout}) async {
    try {
      // Primeiro salva o item, depois gera a movimentação
      String itemManutencaoFrotaId = (await super.add(itemManutencaoFrota, returnId: true, timeout: timeout ?? defaultTimeout))!;
      await registrarItemManutencaoFrota(itemManutencaoFrotaId, itemManutencaoFrota.copyWith(id: itemManutencaoFrotaId));
      return returnId ? itemManutencaoFrotaId : null;
    } catch (e) {
      print('Erro ao adicionar item de manutenção: $e');
      rethrow;
    }
  }

  @override
  Future<void> update(String itemManutencaoFrotaId, ItemManutencaoFrota itemManutencaoFrota, {Duration? timeout}) async {
    try {
      // Armazena item anterior para gerar estorno
      ItemManutencaoFrota itemManutencaoFrotaAnterior = (await getById(itemManutencaoFrotaId))!;
      await super.update(itemManutencaoFrotaId, itemManutencaoFrota, timeout: timeout ?? defaultTimeout);
      await atualizarItemManutencaoFrota(itemManutencaoFrotaAnterior, itemManutencaoFrota.copyWith(id: itemManutencaoFrotaId));
    } catch (e) {
      print('Erro ao atualizar item de manutenção: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String itemManutencaoFrotaId, {Duration? timeout}) async {
    try {
      ItemManutencaoFrota itemManutencaoFrota = (await getById(itemManutencaoFrotaId))!;
      await super.delete(itemManutencaoFrotaId, timeout: timeout ?? defaultTimeout);
      await excluirItemManutencaoFrota(itemManutencaoFrota);
    } catch (e) {
      print('Erro ao excluir item de manutenção: $e');
      rethrow;
    }
  }

  Future<void> registrarItemManutencaoFrota(String itemManutencaoFrotaId, ItemManutencaoFrota itemManutencaoFrota) async {
    // Cria a movimentação de estoque
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: itemManutencaoFrota.propriedadeId,
          itemId: itemManutencaoFrota.itemId,
          produtorId: itemManutencaoFrota.produtorId,
          quantidade: itemManutencaoFrota.quantidadeUtilizada,
          valorUnitario: itemManutencaoFrota.cmpAtual,
          tipo: itemManutencaoFrota.tipoMovimentacaoEstoque,
          categoria: itemManutencaoFrota.categoriaMovimentacaoEstoque,
          data: itemManutencaoFrota.dataUtilizacao,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: itemManutencaoFrota.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: itemManutencaoFrota.cmpAtual,
          unidadeMedidaCMP: itemManutencaoFrota.unidadeMedidaCMP,
          origemId: itemManutencaoFrotaId,
          origemTipo: 'itensManutencaoFrota',
          ativo: true,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: null,
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Cria o lançamento contábil associado
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.MANUTENCAO,
      'produtorId': itemManutencaoFrota.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    // Se não encontrar conta específica para manutenção, tenta custos gerais
    if (contas.isEmpty) {
      contas = await _contaContabilService.getByAttributes({
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'produtorId': itemManutencaoFrota.produtorId,
        'ativo': true,
        'languageCode': languageCode
      });
    }

    if (contas.isNotEmpty) {
      await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
          operacao: 'CompraCusto',
          produtorId: itemManutencaoFrota.produtorId,
          data: itemManutencaoFrota.dataUtilizacao,
          origemId: itemManutencaoFrotaId,
          origemTipo: 'itensManutencaoFrota',
          valor: itemManutencaoFrota.quantidadeUtilizada * itemManutencaoFrota.cmpAtual,
          descricao: 'Manutenção de frota - Consumo de item',
          contaContabil: contas.first
      );
    }
  }

  Future<void> atualizarItemManutencaoFrota(ItemManutencaoFrota itemAnterior, ItemManutencaoFrota itemAtualizado) async {
    // Gera o estorno da movimentação anterior
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: itemAnterior.propriedadeId,
          itemId: itemAnterior.itemId,
          produtorId: itemAnterior.produtorId,
          quantidade: itemAnterior.quantidadeUtilizada,
          valorUnitario: itemAnterior.cmpAtual,
          tipo: itemAnterior.tipoMovimentacaoEstoque == 'Entrada' ? 'Saida' : 'Entrada',
          categoria: 'Estorno${itemAnterior.categoriaMovimentacaoEstoque}',
          data: itemAnterior.dataUtilizacao,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: itemAnterior.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: itemAnterior.cmpAtual,
          unidadeMedidaCMP: itemAnterior.unidadeMedidaCMP,
          origemId: itemAnterior.id,
          origemTipo: 'itensManutencaoFrota',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: itemAnterior.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Buscar conta contábil apropriada
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.MANUTENCAO,
      'produtorId': itemAnterior.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    // Se não encontrar conta específica para manutenção, tenta custos gerais
    if (contas.isEmpty) {
      contas = await _contaContabilService.getByAttributes({
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'produtorId': itemAnterior.produtorId,
        'ativo': true,
        'languageCode': languageCode
      });
    }

    if (contas.isNotEmpty) {
      // Buscar lançamentos pendentes para inativação
      final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
        'origemId': itemAnterior.id,
        'origemTipo': 'itensManutencaoFrota',
        'statusProcessamento': 'pendente'
      });

      // Inativar lançamentos pendentes
      for (final lancamento in lancamentosPendentes) {
        await _lancamentoContabilProjetadoService.update(
            lancamento.id,
            lancamento.copyWith(ativo: false)
        );
      }

      // Buscar lançamentos reais para estornar
      final lancamentosReais = await _lancamentoContabilProjetadoService.getByAttributesWithOperators({
        'origemId': [{'operator': '==', 'value': itemAnterior.id}],
        'origemTipo': [{'operator': '==', 'value': 'itensManutencaoFrota'}],
        'ativo': [{'operator': '==', 'value': true}],
        'statusProcessamento': [{'operator': '==', 'value': 'processado'}]
      });

      // Criar estornos para lançamentos reais
      for (final lancamentoReal in lancamentosReais) {
        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'EstornoCusto',
            produtorId: itemAnterior.produtorId,
            data: itemAnterior.dataUtilizacao,
            origemId: itemAnterior.id,
            origemTipo: 'itensManutencaoFrota',
            valor: itemAnterior.quantidadeUtilizada * itemAnterior.cmpAtual,
            descricao: 'Estorno de manutenção de frota',
            contaContabil: contas.first,
            idLancamentoAnterior: lancamentoReal.id
        );
      }
    }

    // Gera a nova movimentação e lançamento
    await registrarItemManutencaoFrota(itemAtualizado.id, itemAtualizado);
  }

  Future<void> excluirItemManutencaoFrota(ItemManutencaoFrota itemManutencaoFrota) async {
    // Gera o estorno da movimentação de estoque
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: itemManutencaoFrota.propriedadeId,
          itemId: itemManutencaoFrota.itemId,
          produtorId: itemManutencaoFrota.produtorId,
          quantidade: itemManutencaoFrota.quantidadeUtilizada,
          valorUnitario: itemManutencaoFrota.cmpAtual,
          tipo: itemManutencaoFrota.tipoMovimentacaoEstoque == 'Entrada' ? 'Saida' : 'Entrada',
          categoria: 'Estorno${itemManutencaoFrota.categoriaMovimentacaoEstoque}',
          data: itemManutencaoFrota.dataUtilizacao,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: itemManutencaoFrota.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: itemManutencaoFrota.cmpAtual,
          unidadeMedidaCMP: itemManutencaoFrota.unidadeMedidaCMP,
          origemId: itemManutencaoFrota.id,
          origemTipo: 'itensManutencaoFrota',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: itemManutencaoFrota.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Buscar conta contábil apropriada
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.MANUTENCAO,
      'produtorId': itemManutencaoFrota.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    // Se não encontrar conta específica para manutenção, tenta custos gerais
    if (contas.isEmpty) {
      contas = await _contaContabilService.getByAttributes({
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'produtorId': itemManutencaoFrota.produtorId,
        'ativo': true,
        'languageCode': languageCode
      });
    }

    if (contas.isNotEmpty) {
      // Buscar lançamentos pendentes para inativação
      final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
        'origemId': itemManutencaoFrota.id,
        'origemTipo': 'itensManutencaoFrota',
        'statusProcessamento': 'pendente'
      });

      // Inativar lançamentos pendentes
      for (final lancamento in lancamentosPendentes) {
        await _lancamentoContabilProjetadoService.update(
            lancamento.id,
            lancamento.copyWith(ativo: false)
        );
      }

      // Buscar lançamentos reais para estornar
      final lancamentosReais = await _lancamentoContabilProjetadoService.getByAttributesWithOperators({
        'origemId': [{'operator': '==', 'value': itemManutencaoFrota.id}],
        'origemTipo': [{'operator': '==', 'value': 'itensManutencaoFrota'}],
        'ativo': [{'operator': '==', 'value': true}],
        'statusProcessamento': [{'operator': '==', 'value': 'processado'}]
      });

      // Criar estornos para lançamentos reais
      for (final lancamentoReal in lancamentosReais) {
        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'EstornoCusto',
            produtorId: itemManutencaoFrota.produtorId,
            data: itemManutencaoFrota.dataUtilizacao,
            origemId: itemManutencaoFrota.id,
            origemTipo: 'itensManutencaoFrota',
            valor: itemManutencaoFrota.quantidadeUtilizada * itemManutencaoFrota.cmpAtual,
            descricao: 'Estorno de manutenção de frota - Exclusão',
            contaContabil: contas.first,
            idLancamentoAnterior: lancamentoReal.id
        );
      }
    }
  }
}