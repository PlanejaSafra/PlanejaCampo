import 'package:planejacampo/models/abastecimento_frota.dart';
import 'package:planejacampo/models/compra.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_projetada_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/compra_service.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';


class AbastecimentoFrotaService extends GenericService<AbastecimentoFrota> {
  // Serviços necessários
  final MovimentacaoEstoqueProjetadaService _movimentacaoEstoqueService = MovimentacaoEstoqueProjetadaService();
  final CompraService _compraService = CompraService();
  final LancamentoContabilProjetadoService _lancamentoContabilProjetadoService = LancamentoContabilProjetadoService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  final ContaContabilService _contaContabilService = ContaContabilService();
  final ContaService _contaService = ContaService();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final Duration defaultTimeout = const Duration(seconds: 3);
  final languageCode = AppStateManager().appLocale.languageCode;

  AbastecimentoFrotaService() : super('abastecimentosFrota');

  @override
  AbastecimentoFrota fromMap(Map<String, dynamic> map, String documentId) {
    return AbastecimentoFrota.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(AbastecimentoFrota abastecimentoFrota) {
    return abastecimentoFrota.toMap();
  }

  @override
  Future<String?> add(AbastecimentoFrota abastecimentoFrota,
      {bool returnId = false, Duration? timeout}) async {
    try {
      // Validações para abastecimento externo
      if (abastecimentoFrota.externo) {
        await _validarAbastecimentoExterno(abastecimentoFrota);
      }

      // Se for abastecimento externo, cria a compra primeiro
      String? compraId;
      if (abastecimentoFrota.externo) {
        compraId = await _criarCompraExterna(abastecimentoFrota);
        // Atualiza o abastecimento com o ID da compra criada
        abastecimentoFrota = abastecimentoFrota.copyWith(compraId: compraId);
      }

      // Usa o super.add que já retorna o ID
      final docId = await super.add(abastecimentoFrota, returnId: true, timeout: timeout ?? defaultTimeout);

      if (docId != null) {
        // Registra a movimentação de estoque e lançamentos contábeis usando o ID retornado
        await registrarAbastecimento(docId, abastecimentoFrota.copyWith(id: docId));
      }

      return returnId ? docId : null;
    } catch (e) {
      print('Erro ao adicionar abastecimento: $e');
      rethrow;
    }
  }

  Future<void> _validarAbastecimentoExterno(AbastecimentoFrota abastecimento) async {
    if (abastecimento.fornecedorId == null || abastecimento.fornecedorId!.isEmpty) {
      throw Exception('Fornecedor é obrigatório para abastecimento externo');
    }

    if (abastecimento.valorTotal == null || abastecimento.valorTotal! <= 0) {
      throw Exception('Valor total deve ser maior que zero para abastecimento externo');
    }

    if (abastecimento.quantidadeUtilizada <= 0) {
      throw Exception('Quantidade deve ser maior que zero para abastecimento externo');
    }

    // Verificar número de parcelas
    if (abastecimento.numeroParcelas == null || abastecimento.numeroParcelas! < 1) {
      throw Exception('Número de parcelas deve ser maior ou igual a 1');
    }

    // Verificação chave: se o meio de pagamento requer conta, contaId deve estar presente
    String meioPagamento = abastecimento.meioPagamento ?? 'Pix/TED';
    if (MeioPagamentoOptions.requiresContaPagamento(meioPagamento)) {
      if (abastecimento.contaId == null || abastecimento.contaId!.isEmpty) {
        throw Exception('Conta bancária é obrigatória para meio de pagamento $meioPagamento');
      }
    }
  }

  Future<String> _criarCompraExterna(AbastecimentoFrota abastecimento) async {
    // Validações já devem ter sido feitas antes, mas verificamos novamente
    await _validarAbastecimentoExterno(abastecimento);

    // Cria a compra com ID temporário (será substituído pelo ID real do Firestore)
    final compra = Compra(
      id: '', // ID vazio, deixe o Firestore gerar o ID
      produtorId: abastecimento.produtorId,
      fornecedorId: abastecimento.fornecedorId!,
      data: abastecimento.data,
      valorTotal: abastecimento.valorTotal!,
    );

    // Calcula o preço unitário com proteção contra divisão por zero
    double precoUnitario = 0.0;
    if (abastecimento.quantidadeUtilizada > 0) {
      precoUnitario = abastecimento.valorTotal! / abastecimento.quantidadeUtilizada;
    }

    // Cria o item da compra com ID temporário (será substituído)
    final itemCompra = ItemCompra(
      id: '', // ID vazio, será gerado pelo serviço
      compraId: '', // ID vazio, será atualizado após criar a compra
      produtorId: abastecimento.produtorId,
      propriedadeId: abastecimento.propriedadeId,
      itemId: abastecimento.itemId,
      quantidade: abastecimento.quantidadeUtilizada,
      precoUnitario: precoUnitario,
      valorTotal: abastecimento.valorTotal!,
      unidadeMedida: abastecimento.unidadeMedida,
    );

    // Define meio de pagamento com defaults mais seguro
    String meioPagamento = abastecimento.meioPagamento ?? 'Pix/TED';

    // Se o meio de pagamento requer conta e não temos contaId, alteramos para "Boleto"
    if (MeioPagamentoOptions.requiresContaPagamento(meioPagamento) &&
        (abastecimento.contaId == null || abastecimento.contaId!.isEmpty)) {
      meioPagamento = 'Boleto';
      print('Meio de pagamento alterado para Boleto pois não há contaId definido');
    }

    // Garantir que numeroParcelas tenha um valor padrão seguro
    int numeroParcelas = abastecimento.numeroParcelas ?? 1;
    if (numeroParcelas < 1) numeroParcelas = 1;

    // Criar as contas a pagar com base no número de parcelas
    List<ContaPagar> contasPagar = [];
    double valorParcela = abastecimento.valorTotal! / numeroParcelas;

    for (int i = 1; i <= numeroParcelas; i++) {
      // Calcular data de vencimento para cada parcela
      DateTime dataVencimento = abastecimento.data;
      if (i > 1) {
        dataVencimento = DateTime(
          dataVencimento.year,
          dataVencimento.month + (i - 1),
          dataVencimento.day,
        );
      }

      // Criar conta a pagar para esta parcela
      final contaPagar = ContaPagar(
        id: '', // ID vazio, será gerado pelo serviço
        produtorId: abastecimento.produtorId,
        contaId: abastecimento.contaId,
        valor: valorParcela,
        valorPago: 0.0,
        status: 'aberto',
        dataEmissao: abastecimento.data,
        dataVencimento: dataVencimento,
        dataPagamento: null,
        numeroDocumento: null,
        meioPagamento: meioPagamento,
        numeroParcela: i,
        totalParcelas: numeroParcelas,
        origemId: '', // Será atualizado após a criação da compra
        origemTipo: 'compras',
        categoria: 'Compra',
        observacoes: null,
        ativo: true,
        fornecedorId: abastecimento.fornecedorId,
      );

      contasPagar.add(contaPagar);
    }

    // Registra a compra completa
    try {
      // O método registrarCompra retorna o ID real gerado pelo Firestore
      String compraRealId = await _compraService.registrarCompra(
        compra,
        [itemCompra],
        contasPagar,
      );

      if (compraRealId.isEmpty) {
        throw Exception('Falha ao criar compra: ID não retornado');
      }

      print('Compra criada com ID real do Firestore: $compraRealId');
      return compraRealId; // Retorna o ID REAL gerado pelo Firestore
    } catch (e) {
      print('Erro ao registrar compra para abastecimento externo: $e');
      rethrow;
    }
  }

  @override
  Future<void> delete(String abastecimentoId, {Duration? timeout}) async {
    try {
      AbastecimentoFrota abastecimento = (await getById(abastecimentoId))!;

      // 1. PRIMEIRO: Exclui o abastecimento (gera EstornoConsumo)
      await excluirAbastecimento(abastecimento);

      // Se for externo, tenta excluir a compra relacionada
      if (abastecimento.externo && abastecimento.compraId != null) {
        try {
          // Tenta primeiro com o ID exato da compra
          final compra = await _compraService.getById(abastecimento.compraId!);

          if (compra != null) {
            await _compraService.excluirCompra(abastecimento.compraId!);
          } else {
            // Se não encontrar, procura por compras com o mesmo valor e data
            final List<Compra> comprasPossiveis = await _compraService.getByAttributes({
              'produtorId': abastecimento.produtorId,
              'valorTotal': abastecimento.valorTotal
            });

            // Encontra a mais próxima pela data
            Compra? compraMaisProxima;
            Duration? diferencaMinima;

            for (var c in comprasPossiveis) {
              final diferenca = c.data.difference(abastecimento.data).abs();
              if (diferencaMinima == null || diferenca < diferencaMinima) {
                diferencaMinima = diferenca;
                compraMaisProxima = c;
              }
            }

            if (compraMaisProxima != null) {
              print('Compra encontrada por correspondência: ${compraMaisProxima.id}');
              await _compraService.excluirCompra(compraMaisProxima.id);
            } else {
              print('Não foi possível encontrar a compra correspondente para o abastecimento');
            }
          }
        } catch (compraError) {
          print('Erro ao excluir compra relacionada: $compraError. Continuando com a exclusão do abastecimento.');
        }
      }

      await super.delete(abastecimentoId, timeout: timeout ?? defaultTimeout);
    } catch (e) {
      print('Erro ao excluir abastecimento: $e');
      rethrow;
    }
  }

  Future<void> _atualizarCompraExterna(String compraId, AbastecimentoFrota abastecimento) async {
    // Validações para abastecimento externo
    await _validarAbastecimentoExterno(abastecimento);

    // Busca a compra original
    final compraAntiga = await _compraService.getById(compraId);
    if (compraAntiga == null) {
      throw Exception('Compra não encontrada para atualização');
    }

    // Compra atualizada
    final compraAtual = Compra(
      id: compraId,
      produtorId: abastecimento.produtorId,
      fornecedorId: abastecimento.fornecedorId!,
      data: abastecimento.data,
      valorTotal: abastecimento.valorTotal!,
    );

    // Calcula o preço unitário com proteção contra divisão por zero
    double precoUnitario = 0.0;
    if (abastecimento.quantidadeUtilizada > 0) {
      precoUnitario = abastecimento.valorTotal! / abastecimento.quantidadeUtilizada;
    }

    // Item atualizado
    final itemCompra = ItemCompra(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      compraId: compraId,
      produtorId: abastecimento.produtorId,
      propriedadeId: abastecimento.propriedadeId,
      itemId: abastecimento.itemId,
      quantidade: abastecimento.quantidadeUtilizada,
      precoUnitario: precoUnitario,
      valorTotal: abastecimento.valorTotal!,
      unidadeMedida: abastecimento.unidadeMedida,
    );

    // Garantir que numeroParcelas tenha um valor padrão seguro
    int numeroParcelas = abastecimento.numeroParcelas ?? 1;
    if (numeroParcelas < 1) numeroParcelas = 1;

    // Buscar contas a pagar antigas para determinar se o número de parcelas mudou
    final contasPagarAntigas = await _contaPagarService.getByAttributes({
      'origemId': compraId,
      'origemTipo': 'compras',
      'ativo': true,
    });

    // Define meio de pagamento com defaults mais seguro
    String meioPagamento = abastecimento.meioPagamento ?? 'Pix/TED';

    // Se o meio de pagamento requer conta e não temos contaId, alteramos para "Boleto"
    if (MeioPagamentoOptions.requiresContaPagamento(meioPagamento) &&
        (abastecimento.contaId == null || abastecimento.contaId!.isEmpty)) {
      meioPagamento = 'Boleto';
      print('Meio de pagamento alterado para Boleto pois não há contaId definido');
    }

    // Criar novas contas a pagar com base no número de parcelas
    List<ContaPagar> contasPagar = [];
    double valorParcela = abastecimento.valorTotal! / numeroParcelas;

    // Verificar se o número de parcelas mudou
    bool numeroPorcelasAlterado = numeroParcelas != (contasPagarAntigas.isNotEmpty ?
    contasPagarAntigas.first.totalParcelas ?? 1 : 1);

    // Se o número de parcelas mudou ou o meio de pagamento ou conta mudou, cancelamos as antigas e criamos novas
    bool recriarParcelas = numeroPorcelasAlterado ||
        (contasPagarAntigas.isNotEmpty && (
            contasPagarAntigas.first.meioPagamento != meioPagamento ||
                contasPagarAntigas.first.contaId != abastecimento.contaId));

    if (recriarParcelas) {
      // Cancelar todas as contas a pagar antigas
      for (var contaAntiga in contasPagarAntigas) {
        if (contaAntiga.status != 'pago') {
          try {
            await _contaPagarService.cancelarContaPagar(contaAntiga.id);
          } catch (e) {
            print('Erro ao cancelar conta a pagar: $e');
          }
        }
      }

      // Criar novas parcelas
      for (int i = 1; i <= numeroParcelas; i++) {
        // Calcular data de vencimento para cada parcela
        DateTime dataVencimento = abastecimento.data;
        if (i > 1) {
          dataVencimento = DateTime(
            dataVencimento.year,
            dataVencimento.month + (i - 1),
            dataVencimento.day,
          );
        }

        // Criar nova conta a pagar
        final contaPagar = ContaPagar(
          id: '',
          produtorId: abastecimento.produtorId,
          contaId: abastecimento.contaId,
          valor: valorParcela,
          valorPago: 0.0,
          status: 'aberto',
          dataEmissao: abastecimento.data,
          dataVencimento: dataVencimento,
          dataPagamento: null,
          numeroDocumento: null,
          meioPagamento: meioPagamento,
          numeroParcela: i,
          totalParcelas: numeroParcelas,
          origemId: compraId,
          origemTipo: 'compras',
          categoria: 'Compra',
          observacoes: 'Recriado após alteração de abastecimento',
          ativo: true,
          fornecedorId: abastecimento.fornecedorId,
        );

        contasPagar.add(contaPagar);
      }
    } else {
      // Atualizar parcelas existentes sem cancelar (manter valores pagos)
      for (var contaAntiga in contasPagarAntigas) {
        // Só atualiza se não estiver paga
        if (contaAntiga.status != 'pago') {
          // Calcular nova data de vencimento baseada na data atual de abastecimento
          DateTime novaDataVencimento = abastecimento.data;
          int numeroParcela = contaAntiga.numeroParcela ?? 1;
          if (numeroParcela > 1) {
            novaDataVencimento = DateTime(
              abastecimento.data.year,
              abastecimento.data.month + (numeroParcela - 1),
              abastecimento.data.day,
            );
          }

          // Atualizar valores da parcela existente
          final contaAtualizada = contaAntiga.copyWith(
            valor: valorParcela,
            dataEmissao: abastecimento.data,
            dataVencimento: novaDataVencimento,
            fornecedorId: abastecimento.fornecedorId,
          );

          // Adicionar à lista para atualização
          contasPagar.add(contaAtualizada);
        } else {
          // Se já estiver paga, mantém como está
          contasPagar.add(contaAntiga);
        }
      }

      // Se novas parcelas forem necessárias (caso onde o número não mudou mas algumas foram canceladas)
      if (contasPagar.length < numeroParcelas) {
        // Identificar quais parcelas estão faltando
        final parcelasExistentes = contasPagar.map((cp) => cp.numeroParcela ?? 0).toSet();

        for (int i = 1; i <= numeroParcelas; i++) {
          if (!parcelasExistentes.contains(i)) {
            // Criar data de vencimento para a parcela faltante
            DateTime dataVencimento = abastecimento.data;
            if (i > 1) {
              dataVencimento = DateTime(
                dataVencimento.year,
                dataVencimento.month + (i - 1),
                dataVencimento.day,
              );
            }

            // Criar nova conta a pagar para a parcela faltante
            final contaPagar = ContaPagar(
              id: '',
              produtorId: abastecimento.produtorId,
              contaId: abastecimento.contaId,
              valor: valorParcela,
              valorPago: 0.0,
              status: 'aberto',
              dataEmissao: abastecimento.data,
              dataVencimento: dataVencimento,
              dataPagamento: null,
              numeroDocumento: null,
              meioPagamento: meioPagamento,
              numeroParcela: i,
              totalParcelas: numeroParcelas,
              origemId: compraId,
              origemTipo: 'compras',
              categoria: 'Compra',
              observacoes: 'Parcela recriada',
              ativo: true,
              fornecedorId: abastecimento.fornecedorId,
            );

            contasPagar.add(contaPagar);
          }
        }
      }
    }

    // Atualiza a compra e todas as parcelas
    await _compraService.atualizarCompra(
      compraAntiga,
      compraAtual,
      [itemCompra],
      contasPagar,
    );
  }

  @override
  Future<void> update(String abastecimentoId, AbastecimentoFrota abastecimentoFrota,
      {Duration? timeout}) async {
    try {
      AbastecimentoFrota abastecimentoAnterior = (await getById(abastecimentoId))!;

      // Validações para abastecimento externo
      if (abastecimentoFrota.externo) {
        await _validarAbastecimentoExterno(abastecimentoFrota);
      }

      // Se houver mudança no status externo, trata a criação/exclusão da compra
      if (abastecimentoAnterior.externo != abastecimentoFrota.externo) {
        if (abastecimentoFrota.externo) {
          // Mudou para externo - cria compra
          String? compraId = await _criarCompraExterna(abastecimentoFrota);
          abastecimentoFrota = abastecimentoFrota.copyWith(compraId: compraId);
        } else {
          // Mudou para não externo - exclui compra se existir
          if (abastecimentoAnterior.compraId != null) {
            await _compraService.excluirCompra(abastecimentoAnterior.compraId!);
            abastecimentoFrota = abastecimentoFrota.copyWith(compraId: null);
          }
        }
      } else if (abastecimentoFrota.externo && abastecimentoAnterior.compraId != null) {
        // Manteve-se externo - atualiza compra existente
        await _atualizarCompraExterna(abastecimentoAnterior.compraId!, abastecimentoFrota);
      }

      await super.update(abastecimentoId, abastecimentoFrota, timeout: timeout ?? defaultTimeout);
      await atualizarAbastecimento(abastecimentoAnterior, abastecimentoFrota);
    } catch (e) {
      print('Erro ao atualizar abastecimento: $e');
      rethrow;
    }
  }

  // Modifique o método registrarAbastecimento no AbastecimentoFrotaService
  Future<void> registrarAbastecimento(String abastecimentoId, AbastecimentoFrota abastecimento) async {
    // Para abastecimentos externos, precisamos verificar o modo da propriedade
    if (abastecimento.externo) {
      // Precisamos verificar o modo de movimentação da propriedade
      final propriedade = await _propriedadeService.getById(abastecimento.propriedadeId);
      final modoMovimentacao = propriedade?.modoMovimentacaoEstoque ?? 'Manual';

      print('Abastecimento externo com modo de propriedade: $modoMovimentacao');

      // Em modo Auto, a compra já cria entrada+consumo automaticamente
      if (modoMovimentacao == 'Auto') {
        print('Modo Auto: movimentações de estoque já gerenciadas pela compra');
        return;
      }

      // Em modo Manual, a compra só cria a entrada, precisamos criar o consumo
      if (modoMovimentacao == 'Manual') {
        print('Modo Manual: criando movimentação de consumo para abastecimento externo');

        // Criar apenas a movimentação de SAÍDA (consumo)
        await _movimentacaoEstoqueService.criarMovimentacao(
          MovimentacaoEstoqueProjetada(
              id: '',
              propriedadeId: abastecimento.propriedadeId,
              itemId: abastecimento.itemId,
              produtorId: abastecimento.produtorId,
              quantidade: abastecimento.quantidadeUtilizada,
              valorUnitario: abastecimento.cmpAtual,
              tipo: 'Saida',  // Forçando como Saída
              categoria: 'Consumo',  // Forçando como Consumo
              data: abastecimento.data,
              // Importante: timestamp posterior ao da compra para garantir que
              // a entrada seja processada antes do consumo
              timestampLocal: DateTime.now().toLocal().add(Duration(seconds: 3)),
              unidadeMedida: abastecimento.unidadeMedida,
              saldoProjetado: 0.0,
              cmpProjetado: abastecimento.cmpAtual,
              unidadeMedidaCMP: abastecimento.unidadeMedidaCMP,
              origemId: abastecimentoId,
              origemTipo: 'abastecimentosFrota',
              ativo: true,
              deviceId: AppStateManager().deviceId,
              statusProcessamento: 'pendente',
              idMovimentacaoReal: null,
              dadosOriginais: null,
              dataProcessamento: null,
              erroProcessamento: null
          ),
        );

        // Não criar lançamentos contábeis duplicados (a compra já fez isso)
        return;
      }

      // Em modo Desativado, não fazemos nada
      print('Modo Desativado: estoque não será movimentado');
      return;
    }

    // Para abastecimentos internos, continua com o comportamento original
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: abastecimento.propriedadeId,
          itemId: abastecimento.itemId,
          produtorId: abastecimento.produtorId,
          quantidade: abastecimento.quantidadeUtilizada,
          valorUnitario: abastecimento.cmpAtual,
          tipo: abastecimento.tipoMovimentacaoEstoque,
          categoria: abastecimento.categoriaMovimentacaoEstoque,
          data: abastecimento.data,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: abastecimento.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: abastecimento.cmpAtual,
          unidadeMedidaCMP: abastecimento.unidadeMedidaCMP,
          origemId: abastecimentoId,
          origemTipo: 'abastecimentosFrota',
          ativo: true,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: null,
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Criar lançamento contábil (apenas para abastecimentos internos)
    List<ContaContabil> contas = await _contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'produtorId': abastecimento.produtorId,
      'ativo': true,
      'languageCode': languageCode
    });

    if (contas.isNotEmpty) {
      await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
          operacao: 'CompraCusto',
          produtorId: abastecimento.produtorId,
          data: abastecimento.data,
          origemId: abastecimentoId,
          origemTipo: 'abastecimentosFrota',
          valor: abastecimento.quantidadeUtilizada * abastecimento.cmpAtual,
          descricao: 'Abastecimento de frota - Consumo de combustível',
          contaContabil: contas.first
      );
    }
  }

  // Atualiza movimentação de estoque e lançamentos contábeis para abastecimento existente
  Future<void> atualizarAbastecimento(AbastecimentoFrota abastecimentoAnterior, AbastecimentoFrota abastecimentoAtual) async {
    // Estorna movimentação anterior
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: abastecimentoAnterior.propriedadeId,
          itemId: abastecimentoAnterior.itemId,
          produtorId: abastecimentoAnterior.produtorId,
          quantidade: abastecimentoAnterior.quantidadeUtilizada,
          valorUnitario: abastecimentoAnterior.cmpAtual,
          tipo: abastecimentoAnterior.tipoMovimentacaoEstoque == 'Entrada' ? 'Saida' : 'Entrada',
          categoria: 'Estorno${abastecimentoAnterior.categoriaMovimentacaoEstoque}',
          data: abastecimentoAnterior.data,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: abastecimentoAnterior.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: abastecimentoAnterior.cmpAtual,
          unidadeMedidaCMP: abastecimentoAnterior.unidadeMedidaCMP,
          origemId: abastecimentoAnterior.id,
          origemTipo: 'abastecimentosFrota',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: abastecimentoAnterior.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Tratar lançamentos contábeis para abastecimentos não-externos
    if (!abastecimentoAnterior.externo) {
      // Buscar a conta contábil apropriada para custos
      List<ContaContabil> contas = await _contaContabilService.getByAttributes({
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'produtorId': abastecimentoAnterior.produtorId,
        'ativo': true,
        'languageCode': languageCode
      });

      if (contas.isNotEmpty) {
        // Buscar lançamentos pendentes para inativação
        final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
          'origemId': abastecimentoAnterior.id,
          'origemTipo': 'abastecimentosFrota',
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
          'origemId': [{'operator': '==', 'value': abastecimentoAnterior.id}],
          'origemTipo': [{'operator': '==', 'value': 'abastecimentosFrota'}],
          'ativo': [{'operator': '==', 'value': true}],
          'statusProcessamento': [{'operator': '==', 'value': 'processado'}]
        });

        // Criar estornos para lançamentos reais
        for (final lancamentoReal in lancamentosReais) {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoCusto',
              produtorId: abastecimentoAnterior.produtorId,
              data: abastecimentoAnterior.data,
              origemId: abastecimentoAnterior.id,
              origemTipo: 'abastecimentosFrota',
              valor: abastecimentoAnterior.quantidadeUtilizada * abastecimentoAnterior.cmpAtual,
              descricao: 'Estorno de abastecimento de frota',
              contaContabil: contas.first,
              idLancamentoAnterior: lancamentoReal.id
          );
        }
      }
    }

    // Cria nova movimentação e lançamento
    await registrarAbastecimento(abastecimentoAtual.id, abastecimentoAtual);
  }

  // Excluir movimentação de estoque e lançamentos contábeis
  Future<void> excluirAbastecimento(AbastecimentoFrota abastecimento) async {
    // Estorno da movimentação de estoque
    await _movimentacaoEstoqueService.criarMovimentacao(
      MovimentacaoEstoqueProjetada(
          id: '',
          propriedadeId: abastecimento.propriedadeId,
          itemId: abastecimento.itemId,
          produtorId: abastecimento.produtorId,
          quantidade: abastecimento.quantidadeUtilizada,
          valorUnitario: abastecimento.cmpAtual,
          tipo: abastecimento.tipoMovimentacaoEstoque == 'Entrada' ? 'Saida' : 'Entrada',
          categoria: 'Estorno${abastecimento.categoriaMovimentacaoEstoque}',
          data: abastecimento.data,
          timestampLocal: DateTime.now().toLocal(),
          unidadeMedida: abastecimento.unidadeMedida,
          saldoProjetado: 0.0,
          cmpProjetado: abastecimento.cmpAtual,
          unidadeMedidaCMP: abastecimento.unidadeMedidaCMP,
          origemId: abastecimento.id,
          origemTipo: 'abastecimentosFrota',
          ativo: false,
          deviceId: AppStateManager().deviceId,
          statusProcessamento: 'pendente',
          idMovimentacaoReal: null,
          dadosOriginais: abastecimento.toMap(),
          dataProcessamento: null,
          erroProcessamento: null
      ),
    );

    // Tratar lançamentos contábeis para abastecimentos não-externos
    if (!abastecimento.externo) {
      // Buscar a conta contábil apropriada para custos
      List<ContaContabil> contas = await _contaContabilService.getByAttributes({
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'produtorId': abastecimento.produtorId,
        'ativo': true,
        'languageCode': languageCode
      });

      if (contas.isNotEmpty) {
        // Buscar lançamentos pendentes para inativação
        final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
          'origemId': abastecimento.id,
          'origemTipo': 'abastecimentosFrota',
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
          'origemId': [{'operator': '==', 'value': abastecimento.id}],
          'origemTipo': [{'operator': '==', 'value': 'abastecimentosFrota'}],
          'ativo': [{'operator': '==', 'value': true}],
          'statusProcessamento': [{'operator': '==', 'value': 'processado'}]
        });

        // Criar estornos para lançamentos reais
        for (final lancamentoReal in lancamentosReais) {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoCusto',
              produtorId: abastecimento.produtorId,
              data: abastecimento.data,
              origemId: abastecimento.id,
              origemTipo: 'abastecimentosFrota',
              valor: abastecimento.quantidadeUtilizada * abastecimento.cmpAtual,
              descricao: 'Estorno de abastecimento de frota - Exclusão',
              contaContabil: contas.first,
              idLancamentoAnterior: lancamentoReal.id
          );
        }
      }
    }
  }
}