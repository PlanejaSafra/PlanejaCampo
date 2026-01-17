import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil_projetado.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_processor.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/utils/finances/index.dart';
import 'package:planejacampo/utils/finances/lancamento_contabil_options.dart';
import 'package:planejacampo/utils/finances/operacoes_contabeis_config.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';

/// Serviço análogo a MovimentacaoEstoqueProjetadaService, mas para lançamentos contábeis.
/// Mantém estrutura e funcionalidades similares, adaptadas para contabilidade.
class LancamentoContabilProjetadoService extends GenericService<LancamentoContabilProjetado> {

  // Config
  ContaContabilService _contaContabilService = ContaContabilService();
  //final Duration defaultTimeout = const Duration(seconds: 3);
  final languageCode = AppStateManager().appLocale.languageCode;
  String _modoLancamentoContabil = '';

  LancamentoContabilProjetadoService() : super('lancamentosContabeisProjetados');

  @override
  LancamentoContabilProjetado fromMap(Map<String, dynamic> map, String documentId) {
    return LancamentoContabilProjetado.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(LancamentoContabilProjetado lancamento) {
    final dataMap = lancamento.toMap();
    dataMap['data'] = Timestamp.fromDate(lancamento.data.toUtc());
    dataMap['timestampLocal'] = Timestamp.fromDate(lancamento.timestampLocal.toUtc());
    return dataMap;
  }

  // Método para registrar lançamentos baseados em operações contábeis
  // Em lancamento_contabil_projetado_service.dart
  Future<void> registrarLancamentosOperacao({
    required String operacao,
    required String produtorId,
    required DateTime data,
    required String origemId,
    required String origemTipo,
    required double valor,
    String? descricao,
    required ContaContabil contaContabil,
    String? idLancamentoAnterior,
  }) async {
    final appStateManager = AppStateManager();
    if(!appStateManager.hasModuleAccess('contabil')) {
      return;
    }
    var mapeamentoOperacoes = OperacoesContabeisConfig.getMapeamentoOperacoes(appStateManager.appLocale.languageCode);
    var operacaoConfig = mapeamentoOperacoes[operacao];
    if (operacaoConfig == null) {
      throw Exception('Operação não configurada: $operacao');
    }

    // IMPORTANTE: Usar o ID da conta contábil passada como parâmetro
    if (operacao == 'CreditoParcela' || operacao == 'EstornoContaPagar') {
      operacaoConfig = {
        ...operacaoConfig,
        'contasPadrao': {
          ...operacaoConfig['contasPadrao'] ?? {},
          'MEIO_PAGAMENTO': contaContabil.id,
          'DESCRICAO_MEIO': contaContabil.nome,  // ADICIONAR ESTA LINHA
        }
      };
    }

    final partidas = OperacoesContabeisConfig.gerarPartidas(
      operacao: operacao,
      configuracao: operacaoConfig,
      atividadeRural: null,
      valor: valor,
      complemento: descricao,
    );

    // Para cada partida, busca a conta e cria o lançamento
    for (var partida in partidas) {
      // Se for uma conta direta, usa ela, senão busca pelo código
      String contaId;
      if (partida['contaContabilId'] == contaContabil.id) {
        contaId = contaContabil.id;
      } else {
        final contas = await _contaContabilService.getByAttributes({
          'codigo': partida['contaContabilId'],
          'produtorId': produtorId,
          'ativo': true,
          'languageCode': appStateManager.appLocale.languageCode,
        });
        if (contas.isEmpty) {
          throw Exception('Conta não encontrada para código: ${partida['contaContabilId']}');
        }
        contaId = contas.first.id;
      }

      final lancamento = LancamentoContabilProjetado(
        id: '',
        produtorId: produtorId,
        data: data,
        contaContabilId: contaId,
        tipo: partida['tipo'],
        valor: valor,
        categoria: operacao,
        origemId: origemId,
        origemTipo: origemTipo,
        descricao: partida['historico'],
        ativo: true,
        saldoProjetado: 0.0,
        timestampLocal: DateTime.now().toLocal(),
        deviceId: appStateManager.deviceId,
        statusProcessamento: 'pendente',
        idLancamentoAnterior: idLancamentoAnterior,
      );

      await _criarLancamento(lancamento);
    }
  }

  // Método principal para criar um lançamento individual
  Future<void> _criarLancamento(LancamentoContabilProjetado lancamento) async {
    _validarCamposObrigatorios(lancamento);

    // Carregar modo de lançamento contábil
    _modoLancamentoContabil = await _carregarModoLancamentoContabil(lancamento.produtorId);
    if (_modoLancamentoContabil == 'Desativado') {
      return;
    }

    // Converter moeda se necessário
    final conversoes = await _converterMoeda(lancamento.valor);
    final double valorConvertido = conversoes['valorConvertido'] ?? 0.0;

    // Carregar saldo anterior
    final Map<String, dynamic> saldoAnterior = await _carregarSaldoAnterior(lancamento);

    // Calcular valores
    // Calcular valores
    final Map<String, dynamic> resultadoCalculo = await _calcularValores(
      // Adicionado await
      lancamento: lancamento,
      valorConvertido: valorConvertido,
      saldoAnterior: saldoAnterior,
    );

    // Criar versão atualizada do lançamento
    final lancamentoAtualizado = _criarLancamentoAtualizado(
      lancamento: lancamento,
      valorConvertido: valorConvertido,
      resultadoCalculo: resultadoCalculo,
    );

    // Processar lançamentos
    await _processarLancamentos(
      lancamentoAtualizado: lancamentoAtualizado,
      resultadoCalculo: resultadoCalculo,
      saldoAnterior: saldoAnterior,
    );

    // Trigger processamento se online
    if (AppStateManager().isOnline) {
      await _triggerProcessamento();
    }
  }

  // Métodos auxiliares privados
  void _validarCamposObrigatorios(LancamentoContabilProjetado lancamento) {
    if (lancamento.produtorId.isEmpty || lancamento.contaContabilId.isEmpty || lancamento.tipo.isEmpty || lancamento.categoria.isEmpty) {
      throw Exception('Campos obrigatórios não preenchidos no lançamento contábil projetado');
    }
  }

  Future<String> _carregarModoLancamentoContabil(String produtorId) async {
    // Exemplo: poderia buscar config do produtor no Firestore ou local
    // Retorna "Auto", "Manual" ou "Desativado" de acordo com a necessidade
    return 'Manual';
  }

  // Análogo a _converterUnidades no estoque
  // Aqui apenas retornamos o mesmo valor como exemplo
  Future<Map<String, double>> _converterMoeda(double valorOriginal) async {
    // Exemplo de conversão: sempre retorna valor igual
    // Poderia converter moedas diferentes etc.
    return {
      'valorConvertido': valorOriginal,
    };
  }

  Future<Map<String, dynamic>> _carregarSaldoAnterior(LancamentoContabilProjetado lancamento) async {
    // Busca o último lançamento anterior a esta data para esta conta
    final lancamentosAnteriores = await getByAttributesWithOperators({
      'produtorId': [
        {'value': lancamento.produtorId, 'operator': '=='}
      ],
      'contaContabilId': [
        {'value': lancamento.contaContabilId, 'operator': '=='}
      ],
      'data': [
        {'value': lancamento.data, 'operator': '<'}
      ],
      'ativo': [
        {'value': true, 'operator': '=='}
      ],
    }, orderBy: [
      {'field': 'data', 'direction': 'desc'},
      {'field': 'timestampLocal', 'direction': 'desc'}
    ], limit: 1);

    if (lancamentosAnteriores.isNotEmpty) {
      return {
        'saldoConta': lancamentosAnteriores.first.saldoProjetado,
        'dataUltimaAtualizacao': lancamentosAnteriores.first.data,
      };
    }

    // Se não houver lançamentos anteriores, retorna saldo zero
    return {
      'saldoConta': 0.0,
      'dataUltimaAtualizacao': lancamento.data,
    };
  }

  Future<Map<String, dynamic>> _calcularValores({
    // Adicionado Future<>
    required LancamentoContabilProjetado lancamento,
    required double valorConvertido,
    required Map<String, dynamic> saldoAnterior,
  }) async {
    // Adicionado async
    // Obter o código da conta a partir do id
    final ContaContabil? conta = await _contaContabilService.getById(lancamento.contaContabilId);
    if (conta == null) throw Exception('Conta não encontrada');
    String naturezaConta = NaturezaContaConfig.getNaturezaConta(conta.codigo);

    return LancamentoContabilOptions.calcularSaldo(tipo: lancamento.tipo, categoria: lancamento.categoria, valor: valorConvertido, saldoAtual: saldoAnterior['saldoConta'], naturezaConta: naturezaConta);
  }

  LancamentoContabilProjetado _criarLancamentoAtualizado({
    required LancamentoContabilProjetado lancamento,
    required double valorConvertido,
    required Map<String, dynamic> resultadoCalculo,
  }) {
    return lancamento.copyWith(
      valor: valorConvertido,
      saldoProjetado: resultadoCalculo['novoSaldo'], // Incluir saldo projetado
      ativo: resultadoCalculo['ativo'],
      deviceId: AppStateManager().deviceId,
      statusProcessamento: 'pendente',
      timestampLocal: DateTime.now().toLocal(),
    );
  }

  // Processamento análogo ao de estoque
  Future<void> _processarLancamentos({
    required LancamentoContabilProjetado lancamentoAtualizado,
    required Map<String, dynamic> resultadoCalculo,
    required Map<String, dynamic> saldoAnterior,
  }) async {
    if (_modoLancamentoContabil == 'Auto') {
      if (lancamentoAtualizado.categoria == 'EstornoCompra') {
        await _processarEstornoCompra(
          lancamentoAtualizado: lancamentoAtualizado,
          valorEstorno: resultadoCalculo['novoSaldo'],
        );
      } else if (LancamentoContabilOptions.precisaCriarConsumoAutomatico(lancamentoAtualizado.tipo, lancamentoAtualizado.categoria)) {
        await _processarCreditoComDebito(lancamentoAtualizado, saldoAnterior['saldoConta']);
      } else {
        await _registrarLancamentos(lancamentoAtualizado);
      }
    } else {
      // Modo "Manual"
      if (lancamentoAtualizado.categoria.startsWith('Estorno')) {
        await _atualizarLancamentosAnteriores(lancamentoAtualizado);
        await _registrarLancamentos(lancamentoAtualizado.copyWith(ativo: false));
      } else {
        await _registrarLancamentos(lancamentoAtualizado);
      }
    }
  }

  // Exemplo análogo ao _processarEstornoCompra do estoque
  Future<void> _processarEstornoCompra({
    required LancamentoContabilProjetado lancamentoAtualizado,
    required double valorEstorno,
  }) async {
    // Cria um "inverso" de crédito ou débito, conforme caso
    final lancamentoInverso = lancamentoAtualizado.copyWith(
      tipo: lancamentoAtualizado.tipo == 'Debito' ? 'Credito' : 'Debito',
      categoria: 'EstornoSaida', // Exemplo
      valor: valorEstorno,
      ativo: false,
    );
    await _atualizarLancamentosAnteriores(lancamentoAtualizado);
    await _registrarLancamentos(lancamentoInverso);
    await _registrarLancamentos(lancamentoAtualizado);
  }

  // Exemplo análogo ao _processarEntradaComConsumo do estoque
  Future<void> _processarCreditoComDebito(LancamentoContabilProjetado lancamentoAtualizado, double saldoAnterior) async {
    final lancamentoCompanheiro = lancamentoAtualizado.copyWith(
      tipo: lancamentoAtualizado.tipo == 'Credito' ? 'Debito' : 'Credito',
      categoria: 'ConsumoAutomatico', // Exemplo
      valor: lancamentoAtualizado.valor,
      ativo: true,
    );
    await _registrarLancamentos(lancamentoAtualizado);
    await _registrarLancamentos(lancamentoCompanheiro);
  }

  // Dispara o processamento posterior, se existir
  Future<void> _triggerProcessamento() async {
    try {
      LancamentoContabilProcessor().processarLancamentosPendentes();
    } catch (e) {
      print('Erro ao iniciar processamento contábil: $e');
    }
  }

  // Marcar lançamentos anteriores como inativos (estorno)
  Future<void> _atualizarLancamentosAnteriores(LancamentoContabilProjetado lancamento, {Duration? timeout}) async {
    if (_modoLancamentoContabil == 'Desativado') return;

    final lancamentosAnteriores = await getByAttributesWithOperators({
      'produtorId': [
        {'value': lancamento.produtorId, 'operator': '=='}
      ],
      'origemId': [
        {'value': lancamento.origemId, 'operator': '=='}
      ],
      'deviceId': [
        {'value': lancamento.deviceId, 'operator': '=='}
      ],
      'statusProcessamento': [
        {'value': 'pendente', 'operator': '=='}
      ],
      'ativo': [
        {'value': true, 'operator': '=='}
      ]
    });

    for (var lanAnt in lancamentosAnteriores) {
      await update(lanAnt.id, lanAnt.copyWith(ativo: false));
    }
  }

  Future<void> _registrarLancamentos(LancamentoContabilProjetado novoLancamento, {Duration? timeout}) async {
    await add(novoLancamento);
    await _recalcularLancamentosPosteriores(novoLancamento);
  }

  // Recalcular lançamentos posteriores (análogo ao estoque)
  Future<Map<String, dynamic>> _recalcularLancamentosPosteriores(LancamentoContabilProjetado lancamentoAtual, {Duration? timeout}) async {
    final lancamentosPosteriores = await getByAttributesWithOperators(
      {
        'produtorId': [
          {'value': lancamentoAtual.produtorId, 'operator': '=='}
        ],
        'contaContabilId': [
          {'value': lancamentoAtual.contaContabilId, 'operator': '=='}
        ],
        'statusProcessamento': [
          {'value': 'pendente', 'operator': '=='}
        ],
        'ativo': [
          {'value': true, 'operator': '=='}
        ],
        'data': [
          {'value': lancamentoAtual.data, 'operator': '>='}
        ],
      },
      orderBy: [
        {'field': 'data', 'direction': 'asc'},
        {'field': 'timestampLocal', 'direction': 'asc'},
      ],
    );

    // Começar com o saldo do lançamento atual
    double saldoProjetado = lancamentoAtual.saldoProjetado;
    DateTime dataUltimaAtualizacao = lancamentoAtual.data;

    // Obter natureza da conta
    final ContaContabil? conta = await _contaContabilService.getById(lancamentoAtual.contaContabilId);
    if (conta == null) throw Exception('Conta não encontrada');
    String naturezaConta = NaturezaContaConfig.getNaturezaConta(conta.codigo);

    for (LancamentoContabilProjetado lan in lancamentosPosteriores) {
      final calc = LancamentoContabilOptions.calcularSaldo(tipo: lan.tipo, categoria: lan.categoria, valor: lan.valor, saldoAtual: saldoProjetado, naturezaConta: naturezaConta);

      saldoProjetado = calc['novoSaldo'];

      final lancamentoRecalculado = lan.copyWith(saldoProjetado: saldoProjetado);

      await update(
        lancamentoRecalculado.id,
        lancamentoRecalculado,
      );
      dataUltimaAtualizacao = lan.data;
    }

    return {
      'novoSaldo': saldoProjetado,
      'dataUltimaAtualizacao': dataUltimaAtualizacao,
    };
  }
}
