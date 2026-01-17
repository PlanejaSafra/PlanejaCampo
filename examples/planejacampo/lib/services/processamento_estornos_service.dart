import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/item_compra_service.dart';
import 'package:planejacampo/services/item_operacao_rural_service.dart';

class ProcessamentoEstornosService {
  static Future<void> _processarEstornoCompra(String compraId, CompraService compraService) async {
    await compraService.excluirCompra(compraId);
    /*
    final compra = await compraService.getById(compraId);

    if (compra != null) {
      final MovimentacaoEstoqueProjetadaService movimentacaoService = MovimentacaoEstoqueProjetadaService();
      final itensCompra = await ItemCompraService().getByAttributes({'compraId': compraId});

      for (var itemCompra in itensCompra) {
        // 1. Criar movimentação de estorno
        final movimentacaoEstorno = MovimentacaoEstoqueProjetada(
            id: '',
            propriedadeId: itemCompra.propriedadeId,
            itemId: itemCompra.itemId,
            produtorId: compra.produtorId,
            quantidade: itemCompra.quantidade,
            valorUnitario: itemCompra.precoUnitario,
            tipo: 'Saida',
            categoria: 'EstornoCompra',
            data: compra.data,
            timestampLocal: DateTime.now().toLocal(),
            unidadeMedida: itemCompra.unidadeMedida,
            saldoProjetado: 0.0, // Será calculado pelo serviço
            cmpProjetado: itemCompra.precoUnitario,
            unidadeMedidaCMP: itemCompra.unidadeMedida,
            origemId: compra.id,
            origemTipo: 'compras',
            ativo: true,
            deviceId: AppStateManager().deviceId,
            statusProcessamento: 'pendente',
            idMovimentacaoReal: null,
            dadosOriginais: null,
            dataProcessamento: null,
            erroProcessamento: null
        );

        // 2. Processar o estorno
        await movimentacaoService.criarMovimentacao(movimentacaoEstorno);
      }
    }

     */
  }

  static Future<void> _processarEstornoItemOperacaoRural(String itemId, ItemOperacaoRuralService itemOperacaoRuralService) async {
    final itemOperacaoRural = await itemOperacaoRuralService.getById(itemId);

    if (itemOperacaoRural != null) {
      final MovimentacaoEstoqueProjetadaService movimentacaoProjetadaService = MovimentacaoEstoqueProjetadaService();

      // 1. Criar movimentação de estorno
      final movimentacaoEstorno = MovimentacaoEstoqueProjetada(
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
          saldoProjetado: 0.0, // Será calculado pelo serviço
          cmpProjetado: itemOperacaoRural.cmpAtual,
          unidadeMedidaCMP: itemOperacaoRural.unidadeMedidaCMP,
          origemId: itemOperacaoRural.id,
          origemTipo: 'itensOperacaoRural',
          ativo: true,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: itemOperacaoRural.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      );

      // 2. Processar o estorno
      await movimentacaoProjetadaService.criarMovimentacao(movimentacaoEstorno);

      // 3. Marcar movimentações anteriores como inativas
      await movimentacaoProjetadaService.atualizarMovimentacoesAnteriores(movimentacaoEstorno);

      // 4. Recalcular movimentações posteriores
      final movimentacoesFuturas = await movimentacaoProjetadaService.getByAttributesWithOperators(
          {
            'propriedadeId': [{'value': itemOperacaoRural.propriedadeId, 'operator': '=='}],
            'itemId': [{'value': itemOperacaoRural.itemId, 'operator': '=='}],
            'statusProcessamento': [{'value': 'pendente', 'operator': '=='}],
            'data': [{'value': itemOperacaoRural.dataUtilizacao, 'operator': '>='}]
          },
          orderBy: [
            {'field': 'data', 'direction': 'asc'},
            {'field': 'timestampLocal', 'direction': 'asc'}
          ]
      );

      double saldoAtual = 0.0;
      double cmpAtual = 0.0;

      for (var mov in movimentacoesFuturas) {
        if (mov.tipo == 'Entrada') {
          saldoAtual += mov.quantidade;
          if (mov.categoria == 'Compra' || mov.categoria == 'Devolucao') {
            cmpAtual = ((saldoAtual - mov.quantidade) * cmpAtual + mov.quantidade * mov.valorUnitario) / saldoAtual;
          }
        } else {
          saldoAtual -= mov.quantidade;
        }

        await movimentacaoProjetadaService.update(
            mov.id,
            mov.copyWith(
              saldoProjetado: saldoAtual,
              cmpProjetado: cmpAtual,
            )
        );
      }
    }
  }

  static Future<void> processarEstornos(GenericService serviceName, String itemIdValue) async {
    switch (serviceName.baseCollection) {
      case 'compras':
        await _processarEstornoCompra(itemIdValue, serviceName as CompraService);
        break;
      case 'itensOperacaoRural':
        await _processarEstornoItemOperacaoRural(itemIdValue, serviceName as ItemOperacaoRuralService);
        break;
    }
  }
}