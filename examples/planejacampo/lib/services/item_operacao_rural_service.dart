import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'generic_service.dart';

class ItemOperacaoRuralService extends GenericService<ItemOperacaoRural> {
  final MovimentacaoEstoqueProjetadaService _movimentacaoEstoqueService = MovimentacaoEstoqueProjetadaService();
  final LancamentoContabilProjetadoService _lancamentoContabilProjetadoService = LancamentoContabilProjetadoService();
  final ContaContabilService _contaContabilService = ContaContabilService();
  final Duration defaultTimeout = const Duration(seconds: 3);
  final languageCode = AppStateManager().appLocale.languageCode;

  ItemOperacaoRuralService() : super('itensOperacaoRural');

  @override
  ItemOperacaoRural fromMap(Map<String, dynamic> map, String documentId) {
    return ItemOperacaoRural.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ItemOperacaoRural itemOperacaoRural) {
    return itemOperacaoRural.toMap();
  }

  @override
  Future<String?> add(ItemOperacaoRural itemOperacaoRural,
      {bool returnId = false, Duration? timeout}) async {
    try {
      // Primeiro salva o item, depois gera a movimentação e os lançamentos contábeis
      String itemOperacaoRuralId = (await super.add(itemOperacaoRural, returnId: true, timeout: timeout ?? defaultTimeout))!;
      await registrarItemOperacaoRural(itemOperacaoRuralId, itemOperacaoRural.copyWith(id: itemOperacaoRuralId));
      return returnId ? itemOperacaoRuralId : null;
    } catch (e) {
      print('Erro ao adicionar item de operação rural: $e');
      rethrow;
    }
  }

  @override
  Future<void> update(String itemOperacaoRuralId, ItemOperacaoRural itemOperacaoRural, {Duration? timeout}) async {
    try {
      // Armazena item anterior para gerar estorno
      ItemOperacaoRural itemOperacaoRuralAnterior = (await getById(itemOperacaoRuralId))!;
      await super.update(itemOperacaoRuralId, itemOperacaoRural, timeout: timeout ?? defaultTimeout);
      await atualizarItemOperacaoRural(itemOperacaoRuralAnterior, itemOperacaoRural.copyWith(id: itemOperacaoRuralId));
    } catch (e) {
      print('Erro ao atualizar item de operação rural: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String itemOperacaoRuralId, {Duration? timeout}) async {
    try {
      ItemOperacaoRural itemOperacaoRural = (await getById(itemOperacaoRuralId))!;
      await super.delete(itemOperacaoRuralId, timeout: timeout ?? defaultTimeout);
      await excluirItemOperacaoRural(itemOperacaoRural);
    } catch (e) {
      print('Erro ao excluir item de operação rural: $e');
      rethrow;
    }
  }

  Future<void> registrarItemOperacaoRural(String itemOperacaoRuralId, ItemOperacaoRural itemOperacaoRural) async {
    // Cria a movimentação de estoque
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: itemOperacaoRural.propriedadeId,
          itemId: itemOperacaoRural.itemId,
          produtorId: itemOperacaoRural.produtorId,
          quantidade: itemOperacaoRural.quantidadeUtilizada,
          valorUnitario: itemOperacaoRural.cmpAtual,
          tipo: itemOperacaoRural.tipoMovimentacaoEstoque,
          categoria: itemOperacaoRural.categoriaMovimentacaoEstoque,
          data: itemOperacaoRural.dataUtilizacao,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: itemOperacaoRural.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: itemOperacaoRural.cmpAtual,
          unidadeMedidaCMP: itemOperacaoRural.unidadeMedidaCMP,
          origemId: itemOperacaoRuralId,
          origemTipo: 'itensOperacaoRural',
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
      'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'produtorId': itemOperacaoRural.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    if (contas.isNotEmpty) {
      await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
          operacao: 'CompraCusto',
          produtorId: itemOperacaoRural.produtorId,
          data: itemOperacaoRural.dataUtilizacao,
          origemId: itemOperacaoRuralId,
          origemTipo: 'itensOperacaoRural',
          valor: itemOperacaoRural.quantidadeUtilizada * itemOperacaoRural.cmpAtual,
          descricao: 'Operação rural - Consumo de insumo',
          contaContabil: contas.first
      );
    }
  }

  Future<void> atualizarItemOperacaoRural(ItemOperacaoRural itemAnterior, ItemOperacaoRural itemAtualizado) async {
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
          origemTipo: 'itensOperacaoRural',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: itemAnterior.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Tratar lançamentos contábeis
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'produtorId': itemAnterior.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    if (contas.isNotEmpty) {
      // Buscar lançamentos pendentes para inativação
      final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
        'origemId': itemAnterior.id,
        'origemTipo': 'itensOperacaoRural',
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
        'origemTipo': [{'operator': '==', 'value': 'itensOperacaoRural'}],
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
            origemTipo: 'itensOperacaoRural',
            valor: itemAnterior.quantidadeUtilizada * itemAnterior.cmpAtual,
            descricao: 'Estorno de operação rural',
            contaContabil: contas.first,
            idLancamentoAnterior: lancamentoReal.id
        );
      }
    }

    // Gera a nova movimentação de estoque e lançamento contábil
    await registrarItemOperacaoRural(itemAtualizado.id, itemAtualizado);
  }

  Future<void> excluirItemOperacaoRural(ItemOperacaoRural itemOperacaoRural) async {
    // Gera o estorno da movimentação de estoque
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: itemOperacaoRural.propriedadeId,
          itemId: itemOperacaoRural.itemId,
          produtorId: itemOperacaoRural.produtorId,
          quantidade: itemOperacaoRural.quantidadeUtilizada,
          valorUnitario: itemOperacaoRural.cmpAtual,
          tipo: itemOperacaoRural.tipoMovimentacaoEstoque == 'Entrada' ? 'Saida' : 'Entrada',
          categoria: 'Estorno${itemOperacaoRural.categoriaMovimentacaoEstoque}',
          data: itemOperacaoRural.dataUtilizacao,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: itemOperacaoRural.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: itemOperacaoRural.cmpAtual,
          unidadeMedidaCMP: itemOperacaoRural.unidadeMedidaCMP,
          origemId: itemOperacaoRural.id,
          origemTipo: 'itensOperacaoRural',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: itemOperacaoRural.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Tratar lançamentos contábeis
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'produtorId': itemOperacaoRural.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    if (contas.isNotEmpty) {
      // Buscar lançamentos pendentes para inativação
      final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
        'origemId': itemOperacaoRural.id,
        'origemTipo': 'itensOperacaoRural',
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
        'origemId': [{'operator': '==', 'value': itemOperacaoRural.id}],
        'origemTipo': [{'operator': '==', 'value': 'itensOperacaoRural'}],
        'ativo': [{'operator': '==', 'value': true}],
        'statusProcessamento': [{'operator': '==', 'value': 'processado'}]
      });

      // Criar estornos para lançamentos reais
      for (final lancamentoReal in lancamentosReais) {
        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'EstornoCusto',
            produtorId: itemOperacaoRural.produtorId,
            data: itemOperacaoRural.dataUtilizacao,
            origemId: itemOperacaoRural.id,
            origemTipo: 'itensOperacaoRural',
            valor: itemOperacaoRural.quantidadeUtilizada * itemOperacaoRural.cmpAtual,
            descricao: 'Estorno de operação rural - Exclusão',
            contaContabil: contas.first,
            idLancamentoAnterior: lancamentoReal.id
        );
      }
    }
  }
}