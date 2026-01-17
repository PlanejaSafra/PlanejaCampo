import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/estoque.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/movimentacao_estoque_projetada.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_processor.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/movimentacao_estoque_options.dart';
import '../generic_service.dart';

class MovimentacaoEstoqueProjetadaService extends GenericService<MovimentacaoEstoqueProjetada> {
  // Serviços
  final EstoqueService _estoqueService = EstoqueService();
  final ItemService _itemService = ItemService();
  final Duration detaultTimeout = const Duration(seconds: 3);
  String _modoMovimentacaoEstoque = '';

  MovimentacaoEstoqueProjetadaService() : super('movimentacoesEstoqueProjetadas');

  @override
  MovimentacaoEstoqueProjetada fromMap(Map<String, dynamic> map, String documentId) {
    return MovimentacaoEstoqueProjetada.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(MovimentacaoEstoqueProjetada movimentacao) {
    final dataMap = movimentacao.toMap();
    dataMap['data'] = Timestamp.fromDate(movimentacao.data.toUtc());
    return dataMap;
  }

  // Método Principal
  Future<void> criarMovimentacao(MovimentacaoEstoqueProjetada movimentacao) async {
    // Validar campos obrigatórios
    _validarCamposObrigatorios(movimentacao);

    // CORREÇÃO: Atribuir o valor retornado à variável de instância
    _modoMovimentacaoEstoque = await _carregarModoMovimentacaoEstoque(movimentacao.propriedadeId);
    if (_modoMovimentacaoEstoque == 'Desativado') {
      print("Modo de movimentação desativado para propriedade ${movimentacao.propriedadeId}. Operação ignorada.");
      return;
    }

    // Verificar diretamente se o item movimenta estoque
    final itemMovimentaEstoque = await _itemService.getItemMovimentaEstoque(movimentacao.itemId);
    if (!itemMovimentaEstoque) {
      print("Item ${movimentacao.itemId} não movimenta estoque. Operação ignorada.");
      return;
    }

    // Carregar dados necessários
    final Item item = (await _itemService.getById(movimentacao.itemId))!;
    final Map<String, dynamic> conversoes = await _converterUnidades(
        movimentacao: movimentacao,
        unidadePadrao: item.unidadeMedida
    );
    final Map<String, dynamic> estoqueAnterior = await _carregarEstoqueAnterior(movimentacao);

    // Calcular valores
    final Map<String, dynamic> resultadoCalculo = _calcularValores(
      movimentacao: movimentacao,
      quantidadeConvertida: conversoes['quantidadeConvertida'],
      valorUnitarioConvertido: conversoes['valorUnitarioConvertido'],
      estoqueAnterior: estoqueAnterior,
      item: item,
    );

    // Criar movimentação atualizada
    final movimentacaoAtualizada = _criarMovimentacaoAtualizada(
      movimentacao: movimentacao,
      unidadePadrao: item.unidadeMedida,
      resultadoCalculo: resultadoCalculo,
      conversoes: conversoes,
    );

    // Processar movimentações
    await _processarMovimentacoes(
      movimentacaoAtualizada: movimentacaoAtualizada,
      resultadoCalculo: resultadoCalculo,
      estoqueAnterior: estoqueAnterior,
    );

    // Trigger processamento se online
    if (AppStateManager().isOnline) {
      await _triggerProcessamento();
    }
  }

  // Métodos Auxiliares Privados
  void _validarCamposObrigatorios(MovimentacaoEstoqueProjetada movimentacao) {
    if (movimentacao.propriedadeId.isEmpty ||
        movimentacao.itemId.isEmpty ||
        movimentacao.origemId.isEmpty) {
      throw Exception('Campos obrigatórios não preenchidos na movimentação de estoque projetada');
    }
  }

  // CORRIGIDO: Este método deve retornar o modo para que possa ser atribuído explicitamente
  Future<String> _carregarModoMovimentacaoEstoque(String propriedadeId) async {
    try {
      final propriedade = await PropriedadeService().getById(propriedadeId);
      return propriedade?.modoMovimentacaoEstoque ?? 'Desativado';
    } catch (e) {
      print('Erro ao obter modo de movimentação de estoque - ${e.toString()}');
      throw Exception('Erro ao obter modo de movimentação de estoque - Possível causa, propriedade não encontrada - $propriedadeId');
    }
  }

  Future<Map<String, dynamic>> _converterUnidades({
    required MovimentacaoEstoqueProjetada movimentacao,
    required String unidadePadrao,
  }) async {
    double quantidadeConvertida = _estoqueService.converterUnidadeMedida(
        movimentacao.quantidade,
        movimentacao.unidadeMedida,
        unidadePadrao
    );

    double fatorConversao = _estoqueService.converterUnidadeMedida(1.0, movimentacao.unidadeMedida, unidadePadrao);
    if (fatorConversao == 0) fatorConversao = 1;
    return {
      'quantidadeConvertida': quantidadeConvertida,
      'valorUnitarioConvertido': movimentacao.valorUnitario / fatorConversao,
    };
  }

  Future<Map<String, dynamic>> _carregarEstoqueAnterior(MovimentacaoEstoqueProjetada movimentacao) async {
    final mapEstoqueAnterior = await _estoqueService.getEstoqueAnterior(
      propriedadeId: movimentacao.propriedadeId,
      itemId: movimentacao.itemId,
      dataReferencia: movimentacao.data,
      origemId: movimentacao.origemId,
      deviceId: AppStateManager().deviceId,
    );

    return {
      'quantidadeEstoque': mapEstoqueAnterior['quantidade'] ?? 0.0,
      'cmpEstoque': mapEstoqueAnterior['cmp'] ?? 0.0,
      'unidadeMedida': mapEstoqueAnterior['unidadeMedida'] ?? '',
      'dataUltimaAtualizacao': mapEstoqueAnterior['dataUltimaAtualizacao'] ?? movimentacao.data,
    };
  }

  Map<String, dynamic> _calcularValores({
    required MovimentacaoEstoqueProjetada movimentacao,
    required double quantidadeConvertida,
    required double valorUnitarioConvertido,
    required Map<String, dynamic> estoqueAnterior,
    required Item item,
  }) {
    // CORREÇÃO: Usar consistentemente a variável de instância
    final resultadoCalculo = MovimentacaoEstoqueOptions.calcularQuantidadeECMP(
      tipo: movimentacao.tipo,
      categoria: movimentacao.categoria,
      modoMovimentacaoEstoque: _modoMovimentacaoEstoque,
      quantidadeConvertida: quantidadeConvertida,
      valorUnitarioConvertido: valorUnitarioConvertido,
      quantidadeEstoque: estoqueAnterior['quantidadeEstoque'],
      cmpEstoque: estoqueAnterior['cmpEstoque'],
    );

    if (resultadoCalculo['requerCalculoDecaimento']) {
      resultadoCalculo['novoCMP'] = MovimentacaoEstoqueOptions().calcularCMPComDecaimento(
        item: item,
        novoValor: valorUnitarioConvertido,
        novaQuantidade: quantidadeConvertida,
        dataMovimentacao: movimentacao.data,
        cmpHistorico: estoqueAnterior['cmpEstoque'],
        estoqueAnterior: estoqueAnterior['quantidadeEstoque'],
        dataUltimaAtualizacao: estoqueAnterior['dataUltimaAtualizacao'],
      );
    }

    return resultadoCalculo;
  }

  MovimentacaoEstoqueProjetada _criarMovimentacaoAtualizada({
    required MovimentacaoEstoqueProjetada movimentacao,
    required String unidadePadrao,
    required Map<String, dynamic> resultadoCalculo,
    required Map<String, dynamic> conversoes,
  }) {
    return movimentacao.copyWith(
        quantidade: conversoes['quantidadeConvertida'],
        valorUnitario: conversoes['valorUnitarioConvertido'],
        unidadeMedida: unidadePadrao,
        saldoProjetado: resultadoCalculo['novaQuantidadeEstoque'],
        cmpProjetado: resultadoCalculo['novoCMP'],
        unidadeMedidaCMP: unidadePadrao,
        timestampLocal: DateTime.now().toLocal(),
        ativo: resultadoCalculo['ativo'],
        deviceId: AppStateManager().deviceId,
        statusProcessamento: 'pendente'
    );
  }

  // Métodos de Processamento
  Future<void> _processarMovimentacoes({
    required MovimentacaoEstoqueProjetada movimentacaoAtualizada,
    required Map<String, dynamic> resultadoCalculo,
    required Map<String, dynamic> estoqueAnterior,
  }) async {
    // CORREÇÃO: Usar consistentemente a variável de instância _modoMovimentacaoEstoque
    if (_modoMovimentacaoEstoque == 'Auto') {
      if (movimentacaoAtualizada.categoria == 'EstornoCompra') {
        await _processarEstornoCompra(
          movimentacaoAtualizada: movimentacaoAtualizada,
          quantidadeEstorno: resultadoCalculo['quantidadeEstorno'],
        );
      } else if (MovimentacaoEstoqueOptions.precisaCriarConsumoAutomatico(
          movimentacaoAtualizada.tipo,
          movimentacaoAtualizada.categoria)) {
        await _processarEntradaComConsumo(
          movimentacaoAtualizada: movimentacaoAtualizada,
          quantidadeEstoque: estoqueAnterior['quantidadeEstoque'],
        );
      } else {
        await _registrarMovimentacoes(movimentacaoAtualizada);
      }
    } else {
      // Modo Manual
      if (movimentacaoAtualizada.categoria.startsWith('Estorno')) {
        print("Processando estorno em modo Manual: ${movimentacaoAtualizada.categoria}");
        await atualizarMovimentacoesAnteriores(movimentacaoAtualizada);
        await _registrarMovimentacoes(movimentacaoAtualizada.copyWith(ativo: false));
      } else {
        await _registrarMovimentacoes(movimentacaoAtualizada);
      }
    }
  }

  Future<void> _processarEntradaComConsumo({
    required MovimentacaoEstoqueProjetada movimentacaoAtualizada,
    required double quantidadeEstoque,
  }) async {
    final movimentacaoConsumo = movimentacaoAtualizada.copyWith(
      tipo: 'Saida',
      categoria: 'Consumo',
      saldoProjetado: quantidadeEstoque,
      valorUnitario: movimentacaoAtualizada.cmpProjetado,
    );
    await _registrarMovimentacoes(movimentacaoAtualizada);
    await _registrarMovimentacoes(movimentacaoConsumo);
  }

  Future<void> _triggerProcessamento() async {
    try {
      MovimentacaoEstoqueProcessor processor = MovimentacaoEstoqueProcessor();
      processor.processarMovimentacoesPendentes();
    } catch (e) {
      print('Erro ao iniciar processamento: $e');
    }
  }

  // CORRIGIDO: Verifica consistentemente modo da propriedade e movimentação de estoque
  // Corrigir a atualização de movimentações anteriores para estornos
  Future<void> atualizarMovimentacoesAnteriores(MovimentacaoEstoqueProjetada movimentacao, {Duration? timeout}) async {
    final movimentacoesAnteriores = await getByAttributesWithOperators({
      'propriedadeId': [{'value': movimentacao.propriedadeId, 'operator': '=='}],
      'itemId': [{'value': movimentacao.itemId, 'operator': '=='}],
      'origemId': [{'operator': '==', 'value': movimentacao.origemId}],
      'origemTipo': [{'operator': '==', 'value': movimentacao.origemTipo}],
      'deviceId': [{'operator': '==', 'value': movimentacao.deviceId}],
      'statusProcessamento': [{'operator': '==', 'value': 'pendente'}],
      'ativo': [{'operator': '==', 'value': true}]
    });

    for (var mov in movimentacoesAnteriores) {
      // CORREÇÃO: Apenas marcar como inativo sem alterar saldos e CMP
      await update(mov.id, mov.copyWith(
        ativo: false,
        // Não alterar saldoProjetado e cmpProjetado
      ), timeout: timeout ?? detaultTimeout);
    }
  }

  // Corrigir o processamento de estornos
  Future<void> _processarEstornoCompra({
    required MovimentacaoEstoqueProjetada movimentacaoAtualizada,
    required double quantidadeEstorno,
  }) async {
    // CORREÇÃO: Manter saldos coerentes no estorno
    final movimentacaoConsumo = movimentacaoAtualizada.copyWith(
      tipo: 'Entrada',
      categoria: 'EstornoConsumo',
      saldoProjetado: quantidadeEstorno,
      ativo: false,
      // Preservar CMP
    );
    await atualizarMovimentacoesAnteriores(movimentacaoAtualizada);
    await _registrarMovimentacoes(movimentacaoConsumo);
    await _registrarMovimentacoes(movimentacaoAtualizada.copyWith(
      ativo: false // Garantir que o estorno esteja inativo
    ));
  }

  Future<void> _registrarMovimentacoes(MovimentacaoEstoqueProjetada movimentacaoNova, {Duration? timeout}) async {
    print("Registrando movimentação projetada: tipo=${movimentacaoNova.tipo}, categoria=${movimentacaoNova.categoria}");
    await add(movimentacaoNova, timeout: timeout ?? detaultTimeout);
    await _recalcularMovimentacoesPosteriores(movimentacaoNova);
  }

  Future<Map<String, dynamic>> _recalcularMovimentacoesPosteriores(MovimentacaoEstoqueProjetada movimentacaoAtual, {Duration? timeout}) async {
    final movimentacoesPosteriores = await getByAttributesWithOperators(
        {
          'propriedadeId': [{'value': movimentacaoAtual.propriedadeId, 'operator': '=='}],
          'itemId': [{'value': movimentacaoAtual.itemId, 'operator': '=='}],
          'statusProcessamento': [{'value': 'pendente', 'operator': '=='}],
          'origemId': [{'value': movimentacaoAtual.origemId, 'operator': '!='}],
          'ativo': [{'value': true, 'operator': '=='}],
          'data': [{'value': movimentacaoAtual.data, 'operator': '>='}]
        },
        orderBy: [
          {'field': 'data', 'direction': 'asc'},
          {'field': 'timestampLocal', 'direction': 'asc'}
        ]
    );

    double saldoProjetado = movimentacaoAtual.saldoProjetado;
    double cmpProjetado = movimentacaoAtual.cmpProjetado;
    DateTime dataUltimaAtualizacao = movimentacaoAtual.data;

    final Item item = (await _itemService.getById(movimentacaoAtual.itemId))!;

    for (MovimentacaoEstoqueProjetada mov in movimentacoesPosteriores) {
      // CORREÇÃO: Usar consistentemente a variável de instância
      final resultadoCalculo = MovimentacaoEstoqueOptions.calcularQuantidadeECMP(
        tipo: mov.tipo,
        categoria: mov.categoria,
        modoMovimentacaoEstoque: _modoMovimentacaoEstoque,
        quantidadeConvertida: mov.quantidade,
        valorUnitarioConvertido: mov.valorUnitario,
        quantidadeEstoque: saldoProjetado,
        cmpEstoque: cmpProjetado,
      );

      saldoProjetado = resultadoCalculo['novaQuantidadeEstoque'];
      cmpProjetado = resultadoCalculo['novoCMP'];

      if (resultadoCalculo['requerCalculoDecaimento']) {
        cmpProjetado = MovimentacaoEstoqueOptions().calcularCMPComDecaimento(
          item: item,
          novoValor: mov.valorUnitario,
          novaQuantidade: mov.quantidade,
          dataMovimentacao: mov.data,
          cmpHistorico: cmpProjetado,
          estoqueAnterior: saldoProjetado,
          dataUltimaAtualizacao: dataUltimaAtualizacao,
        );
      }

      final movimentacaoAtualizada = mov.copyWith(
        saldoProjetado: saldoProjetado,
        cmpProjetado: cmpProjetado,
      );

      await update(movimentacaoAtualizada.id, movimentacaoAtualizada, timeout: timeout ?? detaultTimeout);
      dataUltimaAtualizacao = mov.data;
    }

    return {
      'quantidade': saldoProjetado,
      'cmp': cmpProjetado,
    };
  }
}