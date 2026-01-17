import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';

class CompraService extends GenericService<Compra> {
  CompraService() : super('compras');
  final ItemCompraService _itemCompraService = ItemCompraService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final ItemService _itemService = ItemService();
  final ContaContabilService _contaContabilService = ContaContabilService();
  final MovimentacaoEstoqueProjetadaService _movimentacaoEstoqueProjetadaService = MovimentacaoEstoqueProjetadaService();
  //final MovimentacaoFinanceiraProjetadaService _movimentacaoFinanceiraService =
  //MovimentacaoFinanceiraProjetadaService();
  final LancamentoContabilProjetadoService _lancamentoContabilProjetadoService = LancamentoContabilProjetadoService();
  final languageCode = AppStateManager().appLocale.languageCode;

  @override
  Compra fromMap(Map<String, dynamic> map, String documentId) {
    return Compra.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Compra compra) {
    return compra.toMap();
  }

  // ===========================================================================
  // 1) REGISTRAR COMPRA
  // ===========================================================================
  // Modificação no método registrarCompra para retornar o ID real da compra
  Future<String> registrarCompra(
      Compra compra,
      List<ItemCompra> itensCompra,
      List<ContaPagar> contasPagar,
      ) async {
    //print('Desabilitando a rede...');
    //await FirebaseFirestore.instance.disableNetwork();
    //print('Rede desabilitada');
    final deviceId = AppStateManager().deviceId;
    final compraUtc = compra.copyWith(data: compra.data.toUtc());

    // 1) Salva a compra
    //print('Salvando Compra...');
    final compraDocRefId = await add(compraUtc, returnId: true);
    //print('Compra salva com ID: $compraDocRefId');
    //print('Habilitando a rede...');
    //await FirebaseFirestore.instance.enableNetwork();
    //print('Rede habilitada');
    if (compraDocRefId == null) {
      throw Exception('Falha ao criar compra: ID não retornado');
    }

    // 2) Para cada ItemCompra, salva e cria movimentações/lançamentos
    for (final itemCompra in itensCompra) {
      final String? itemCompraId = await _itemCompraService.add(itemCompra.copyWith(compraId: compraDocRefId), returnId: true);

      // Verifica se movimenta estoque
      final item = await _itemService.getById(itemCompra.itemId);
      if (item == null) continue;

      if (item.movimentaEstoque == true) {
        await _movimentacaoEstoqueProjetadaService.criarMovimentacao(
          MovimentacaoEstoqueProjetada(
            id: '',
            propriedadeId: itemCompra.propriedadeId,
            itemId: itemCompra.itemId,
            produtorId: compra.produtorId,
            quantidade: itemCompra.quantidade,
            valorUnitario: itemCompra.precoUnitario,
            tipo: 'Entrada',
            categoria: 'Compra',
            data: compraUtc.data,
            timestampLocal: DateTime.now().toLocal(),
            unidadeMedida: itemCompra.unidadeMedida,
            saldoProjetado: 0,
            cmpProjetado: itemCompra.precoUnitario,
            unidadeMedidaCMP: itemCompra.unidadeMedida,
            origemId: itemCompraId!,
            origemTipo: 'itensCompra',
            ativo: true,
            deviceId: deviceId,
            statusProcessamento: 'pendente',
            idMovimentacaoReal: null,
            dadosOriginais: null,
            dataProcessamento: null,
            erroProcessamento: null,
          ),
        );
        List<ContaContabil> contas = await _contaContabilService.getByAttributes({'codigo': ContasBaseConfig.ESTOQUE_INSUMOS, 'produtorId': compra.produtorId, 'ativo': true, 'languageCode': languageCode});

        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'CompraEstoque', // Nova operação que só faz o débito
            produtorId: compra.produtorId,
            data: compraUtc.data,
            origemId: itemCompraId!,
            origemTipo: 'itensCompra',
            valor: itemCompra.quantidade * itemCompra.precoUnitario,
            descricao: 'Compra de ${item.nome}',
            contaContabil: contas.first);
      } else {
        // Lançamento contábil apenas do DÉBITO em despesa
        List<ContaContabil> contas = await _contaContabilService.getByAttributes({'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS, 'produtorId': compra.produtorId, 'ativo': true, 'languageCode': languageCode});

        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'CompraCusto', // Nova operação que só faz o débito
            produtorId: compra.produtorId,
            data: compraUtc.data,
            origemId: itemCompraId!,
            origemTipo: 'itensCompra',
            valor: itemCompra.quantidade * itemCompra.precoUnitario,
            descricao: 'Despesa com ${item.nome}',
            contaContabil: contas.first);
      }
    }

    // 3) Contas a pagar
    for (final ctaPagar in contasPagar) {
      final ctaPagarOk = ctaPagar.copyWith(origemId: compraDocRefId);
      await _contaPagarService.registrarContaPagar(ctaPagarOk);
    }

    // 4) Retorna o ID real da compra para ser armazenado no abastecimento
    return compraDocRefId;
  }

  // ===========================================================================
  // 2) ATUALIZAR COMPRA
  // ===========================================================================
  Future<void> atualizarCompra(
      Compra compraAnterior,
      Compra compraAtual,
      List<ItemCompra> itensCompra,
      List<ContaPagar> contasPagar, {
        bool atualizarCompra = true,
        bool atualizarItensCompra = true,
        bool atualizarPagamentosCompra = true,
      }) async {
    final deviceId = AppStateManager().deviceId;
    final compraUtc = compraAtual.copyWith(data: compraAtual.data.toUtc());
    double valorTotal = itensCompra.fold(
      0.0,
          (sum, it) => sum + (it.quantidade * it.precoUnitario),
    );
    final compraNova = compraUtc.copyWith(valorTotal: valorTotal);

    // (1) Atualiza registro principal
    if (atualizarCompra) {
      await update(compraNova.id, compraNova);
    }

    // (2) Atualiza itens e lançamentos
    if (atualizarItensCompra) {
      // 2a) Primeiro inativa todos os lançamentos anteriores relacionados aos itens
      final itensAntigos = await _itemCompraService.getByAttributes({'compraId': compraAnterior.id});
      for (final itemAntigo in itensAntigos) {
        final item = await _itemService.getById(itemAntigo.itemId);
        if (item == null) continue;

        // Inativa todos os lançamentos contábeis anteriores
        final lancamentosAntigos = await _lancamentoContabilProjetadoService.getByAttributes({
          'origemId': itemAntigo.id,
          'origemTipo': 'itensCompra',
          'ativo': true,
          'statusProcessamento': 'processado',
        });

        for (final lanc in lancamentosAntigos) {
          await _lancamentoContabilProjetadoService.update(
              lanc.id,
              lanc.copyWith(ativo: false)
          );
        }

        if (item.movimentaEstoque == true) {
          // Estorno de movimentação de estoque
          await _movimentacaoEstoqueProjetadaService.criarMovimentacao(
            MovimentacaoEstoqueProjetada(
              id: '',
              propriedadeId: itemAntigo.propriedadeId,
              itemId: itemAntigo.itemId,
              produtorId: compraAnterior.produtorId,
              quantidade: itemAntigo.quantidade,
              valorUnitario: itemAntigo.precoUnitario,
              tipo: 'Saida',
              categoria: 'EstornoCompra',
              data: compraAnterior.data.toUtc(),
              timestampLocal: DateTime.now().toLocal(),
              unidadeMedida: itemAntigo.unidadeMedida,
              saldoProjetado: 0,
              cmpProjetado: itemAntigo.precoUnitario,
              unidadeMedidaCMP: itemAntigo.unidadeMedida,
              origemId: itemAntigo.id,
              origemTipo: 'itensCompra',
              ativo: false,
              deviceId: deviceId,
              statusProcessamento: 'pendente',
              idMovimentacaoReal: null,
              dadosOriginais: null,
              dataProcessamento: null,
              erroProcessamento: null,
            ),
          );

          // Lançamento contábil de estorno
          final contasEstoque = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.ESTOQUE_INSUMOS,
            'produtorId': compraAnterior.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasEstoque.isNotEmpty) {
            await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
                operacao: 'EstornoEstoque',
                produtorId: compraAnterior.produtorId,
                data: compraAnterior.data.toUtc(),
                origemId: itemAntigo.id,
                origemTipo: 'itensCompra',
                valor: itemAntigo.quantidade * itemAntigo.precoUnitario,
                descricao: 'Estorno de compra - Item: ${item.nome}',
                contaContabil: contasEstoque.first
            );
          }
        } else {
          // Lançamento contábil de estorno para custo
          final contasCusto = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.CUSTOS_PRODUCAO,
            'produtorId': compraAnterior.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasCusto.isNotEmpty) {
            await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
                operacao: 'EstornoCusto',
                produtorId: compraAnterior.produtorId,
                data: compraAnterior.data.toUtc(),
                origemId: itemAntigo.id,
                origemTipo: 'itensCompra',
                valor: itemAntigo.quantidade * itemAntigo.precoUnitario,
                descricao: 'Estorno de compra - Item: ${item.nome}',
                contaContabil: contasCusto.first
            );
          }
        }

        // Remove item antigo
        await _itemCompraService.delete(itemAntigo.id);
      }

      // 2b) Cria todos os novos itens e seus lançamentos
      for (final itemNovo in itensCompra) {
        final String? novoItemCompraId = await _itemCompraService.add(
            itemNovo.copyWith(compraId: compraNova.id),
            returnId: true
        );

        final item = await _itemService.getById(itemNovo.itemId);
        if (item == null) continue;

        if (item.movimentaEstoque == true) {
          // Nova movimentação de estoque
          await _movimentacaoEstoqueProjetadaService.criarMovimentacao(
            MovimentacaoEstoqueProjetada(
              id: '',
              propriedadeId: itemNovo.propriedadeId,
              itemId: itemNovo.itemId,
              produtorId: compraNova.produtorId,
              quantidade: itemNovo.quantidade,
              valorUnitario: itemNovo.precoUnitario,
              tipo: 'Entrada',
              categoria: 'Compra',
              data: compraNova.data,
              timestampLocal: DateTime.now().toLocal(),
              unidadeMedida: itemNovo.unidadeMedida,
              saldoProjetado: 0,
              cmpProjetado: itemNovo.precoUnitario,
              unidadeMedidaCMP: itemNovo.unidadeMedida,
              origemId: novoItemCompraId!,
              origemTipo: 'itensCompra',
              ativo: true,
              deviceId: deviceId,
              statusProcessamento: 'pendente',
              idMovimentacaoReal: null,
              dadosOriginais: null,
              dataProcessamento: null,
              erroProcessamento: null,
            ),
          );

          // Novo lançamento contábil para estoque
          final contasEstoque = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.ESTOQUE_INSUMOS,
            'produtorId': compraNova.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasEstoque.isNotEmpty) {
            await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
                operacao: 'CompraEstoque',
                produtorId: compraNova.produtorId,
                data: compraNova.data,
                origemId: novoItemCompraId!,
                origemTipo: 'itensCompra',
                valor: itemNovo.quantidade * itemNovo.precoUnitario,
                descricao: 'Compra de ${item.nome}',
                contaContabil: contasEstoque.first
            );
          }
        } else {
          // Novo lançamento contábil para custo
          final contasCusto = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.CUSTOS_PRODUCAO,
            'produtorId': compraNova.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasCusto.isNotEmpty) {
            await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
                operacao: 'CompraCusto',
                produtorId: compraNova.produtorId,
                data: compraNova.data,
                origemId: novoItemCompraId!,
                origemTipo: 'itensCompra',
                valor: itemNovo.quantidade * itemNovo.precoUnitario,
                descricao: 'Compra de ${item.nome}',
                contaContabil: contasCusto.first
            );
          }
        }
      }
    }

    // (3) Atualiza contas a pagar
    if (atualizarPagamentosCompra) {
      print('Buscando contas antigas para origemId: ${compraAnterior.id}');
      final contasAntigas = await _contaPagarService.getByAttributes({
        'origemId': compraAnterior.id,
        'origemTipo': 'compras',
      });
      print('Encontradas ${contasAntigas.length} contas antigas');

      for (var cta in contasAntigas) {
        print('Excluindo conta ${cta.id}');
        try {
          await _contaPagarService.excluirContaPagar(cta.id);
          print('Conta ${cta.id} excluída com sucesso');
        } catch (e) {
          print('Erro ao excluir conta ${cta.id}: $e');
          throw e;
        }
      }


      // Cria as novas contas
      for (var ctaNova in contasPagar) {
        final ctaOk = ctaNova.copyWith(
          origemId: compraNova.id,
          origemTipo: 'compras',
        );
        await _contaPagarService.registrarContaPagar(ctaOk);
      }
    }
  }

  // ===========================================================================
  // 3) EXCLUIR COMPRA
  // ===========================================================================
  Future<void> excluirCompra(String compraId) async {
    final deviceId = AppStateManager().deviceId;
    final compra = await getById(compraId);
    if (compra == null) {
      throw Exception('Compra não encontrada');
    }

    final lancamentosContabeisProjetados = await _lancamentoContabilProjetadoService.getByAttributes({
      'ativo': true
    });

    //await Future.delayed(Duration(seconds: 5));
    //for (final lancamento in lancamentosContabeisProjetados) {
    //  await Future.delayed(Duration(seconds: 5));
    //  print('================================= Lançamento contábil encontrado: ${lancamento.id}, lancamento.statusProcessamento: ${lancamento.statusProcessamento}, lancamento.ativo: ${lancamento.ativo}, lancamento.idLancamentoReal: ${lancamento.idLancamentoReal}, lancamento.idlancamentoanterior: ${lancamento.idLancamentoAnterior}, lancamento.origemId: ${lancamento.origemId}, lancamento.origemTipo: ${lancamento.origemTipo}');
    //}
    //final lancamentosContabeisProjetados2 = await _lancamentoContabilProjetadoService.getByAttributes({
    //  'ativo': true
    //});

    //await Future.delayed(Duration(seconds: 5));
    //for (final lancamento in lancamentosContabeisProjetados2) {
    //  await Future.delayed(Duration(seconds: 5));
    //  print('================================= Lançamento contábil encontrado: ${lancamento.id}, lancamento.statusProcessamento: ${lancamento.statusProcessamento}, lancamento.ativo: ${lancamento.ativo}, lancamento.idLancamentoReal: ${lancamento.idLancamentoReal}, lancamento.idlancamentoanterior: ${lancamento.idLancamentoAnterior}, lancamento.origemId: ${lancamento.origemId}, lancamento.origemTipo: ${lancamento.origemTipo}');
    //}

    // 1) Primeiro, excluir contas a pagar, que irá tratar seus próprios lançamentos contábeis
    final contasCompra = await _contaPagarService.getByAttributes({
      'origemId': compraId,
      'origemTipo': 'compras',
    });
    for (final c in contasCompra) {
      try {
        print('Excluindo conta a pagar ${c.id}');
        await _contaPagarService.excluirContaPagar(c.id);
      } catch (e) {
        print('Erro ao excluir conta a pagar ${c.id}: $e');
        throw e; // Re-throw para interromper a operação
      }
    }

    // 2) Estorna itens e seus lançamentos
    final itensCompra = await _itemCompraService.getByAttributes({'compraId': compraId});
    for (final itemCompra in itensCompra) {
      final itemInfo = await _itemService.getById(itemCompra.itemId);
      if (itemInfo == null) continue;

      // 2.1) Se movimenta estoque, criar estorno de movimentação
      if (itemInfo.movimentaEstoque == true) {
        await _movimentacaoEstoqueProjetadaService.criarMovimentacao(
          MovimentacaoEstoqueProjetada(
            id: '',
            propriedadeId: itemCompra.propriedadeId,
            itemId: itemCompra.itemId,
            produtorId: compra.produtorId,
            quantidade: itemCompra.quantidade,
            valorUnitario: itemCompra.precoUnitario,
            tipo: 'Saida',
            categoria: 'EstornoCompra',
            data: compra.data.toUtc(),
            timestampLocal: DateTime.now().toLocal(),
            unidadeMedida: itemCompra.unidadeMedida,
            saldoProjetado: 0,
            cmpProjetado: itemCompra.precoUnitario,
            unidadeMedidaCMP: itemCompra.unidadeMedida,
            origemId: itemCompra.id,
            origemTipo: 'itensCompra',
            ativo: false,
            deviceId: deviceId,
            statusProcessamento: 'pendente',
            idMovimentacaoReal: null,
            dadosOriginais: null,
            dataProcessamento: null,
            erroProcessamento: null,
          ),
        );

        // 2.2) Buscar e inativar lançamento contábil original de estoque
        final lancamentosAntigos = await _lancamentoContabilProjetadoService.getByAttributes({
          'origemId': itemCompra.id,
          'origemTipo': 'itensCompra',
          'ativo': true,
          'statusProcessamento': 'processado',
        });

        for (final lanc in lancamentosAntigos) {
          await _lancamentoContabilProjetadoService.update(
              lanc.id,
              lanc.copyWith(ativo: false)
          );
        }

        // 2.3) Criar lançamento de estorno para estoque
        final contasEstoque = await _contaContabilService.getByAttributes({
          'codigo': ContasBaseConfig.ESTOQUE_INSUMOS,
          'produtorId': compra.produtorId,
          'ativo': true,
          'languageCode': languageCode
        });

        if (contasEstoque.isNotEmpty) {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoEstoque',
              produtorId: compra.produtorId,
              data: compra.data.toUtc(),
              origemId: itemCompra.id,
              origemTipo: 'itensCompra',
              valor: itemCompra.quantidade * itemCompra.precoUnitario,
              descricao: 'Estorno por exclusão de compra - Item: ${itemInfo.nome}',
              contaContabil: contasEstoque.first
          );
        }
      } else {
        // 2.4) Buscar e inativar lançamento contábil original de custo
        final lancamentosAntigos = await _lancamentoContabilProjetadoService.getByAttributes({
          'origemId': itemCompra.id,
          'origemTipo': 'itensCompra',
          'ativo': true,
          'statusProcessamento': 'processado',
        });

        for (final lanc in lancamentosAntigos) {
          await _lancamentoContabilProjetadoService.update(
              lanc.id,
              lanc.copyWith(ativo: false)
          );
        }

        // 2.5) Criar lançamento de estorno para custo
        final contasCusto = await _contaContabilService.getByAttributes({
          'codigo': ContasBaseConfig.CUSTOS_PRODUCAO,
          'produtorId': compra.produtorId,
          'ativo': true,
          'languageCode': languageCode
        });

        if (contasCusto.isNotEmpty) {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoCusto',
              produtorId: compra.produtorId,
              data: compra.data.toUtc(),
              origemId: itemCompra.id,
              origemTipo: 'itensCompra',
              valor: itemCompra.quantidade * itemCompra.precoUnitario,
              descricao: 'Estorno por exclusão de compra - Item: ${itemInfo.nome}',
              contaContabil: contasCusto.first
          );
        }
      }

      // 3) Remove item da compra
      await _itemCompraService.delete(itemCompra.id);
    }

    // 4) Exclui a própria compra
    await delete(compraId);
  }

  /// =========================================
  ///  EXEMPLOS DE VERIFICAÇÃO / RECÁLCULO
  /// =========================================

  Future<bool> _verificarProcessamentoCompleto(String compraId) async {
    // Verifica estoque
    final movEstoque = await _movimentacaoEstoqueProjetadaService.getByAttributes({
      'origemId': compraId,
      'origemTipo': 'compras',
      'ativo': true,
      'statusProcessamento': 'pendente',
    });
    if (movEstoque.isNotEmpty) return false;

    // Verifica contabilidade
    final lancContabeis = await _lancamentoContabilProjetadoService.getByAttributes({
      'origemId': compraId,
      'origemTipo': 'compras',
      'ativo': true,
      'statusProcessamento': 'pendente',
    });
    if (lancContabeis.isNotEmpty) return false;

    // Verifica movimentações financeiras
    /*
    final movFinanceiras = await _movimentacaoFinanceiraService.getByAttributes({
      'origemId': compraId,
      'origemTipo': 'compras',
      'ativo': true,
      'statusProcessamento': 'pendente',
    });
    if (movFinanceiras.isNotEmpty) return false;
    */

    return true;
  }

  Future<void> _recalcularTotais(String compraId) async {
    final compraLocal = await getById(compraId);
    if (compraLocal == null) return;

    final itens = await _itemCompraService.getByAttributes({'compraId': compraId});
    double total = itens.fold(0.0, (sum, i) => sum + i.precoUnitario * i.quantidade);

    final compraAtualizada = compraLocal.copyWith(valorTotal: total);
    await update(compraId, compraAtualizada);
  }
}
