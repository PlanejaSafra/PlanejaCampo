import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_service.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';

class ContaPagarService extends GenericService<ContaPagar> {
  //final Duration defaultTimeout = const Duration(seconds: 3);
  final languageCode = AppStateManager().appLocale.languageCode;
  final LancamentoContabilProjetadoService _lancamentoContabilProjetadoService = LancamentoContabilProjetadoService();
  final LancamentoContabilService _lancamentoContabilService = LancamentoContabilService();
  final ContaContabilService _contaContabilService = ContaContabilService();
  final ContaService _contaService = ContaService();


  ContaPagarService() : super('contasPagar');

  @override
  ContaPagar fromMap(Map<String, dynamic> map, String documentId) {
    return ContaPagar.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ContaPagar contaPagar) {
    return contaPagar.toMap();
  }

  // Correção precisa para os erros de null safety
  Future<String?> registrarContaPagar(ContaPagar contaPagar, {Duration? timeout}) async {
    _validarContaPagar(contaPagar);

    // Verificar se é um pagamento que deve ser registrado automaticamente
    ContaPagar contaParaRegistrar = contaPagar;

    // Se o meio de pagamento e a data indicam que deve quitar automaticamente
    if (MeioPagamentoOptions.deveQuitarAutomaticamente(
        contaPagar.meioPagamento,
        contaPagar.dataVencimento)) {
      // Criar uma nova conta já com status de pago
      contaParaRegistrar = contaPagar.copyWith(
        valorPago: contaPagar.valor,
        status: 'pago',
        dataPagamento: contaPagar.dataVencimento, // Usar a data de vencimento
      );
    }

    // Resto do método continua igual...
    final String? docId = await add(contaParaRegistrar, returnId: true);
    if (docId != null) {
      print('contaPagar.contaId: ${contaParaRegistrar.contaId}');
      ContaContabil? _contaContabil;
      // Corrigindo a verificação de nullability
      String? contaId = contaParaRegistrar.contaId;
      if (contaId != null && contaId.isNotEmpty) {
        final Conta? conta = await _contaService.getById(contaId);
        print('Conta: $conta, conta.id: ${conta?.id}, conta.nome: ${conta?.nome}, conta.contaContabilId: ${conta?.contaContabilId}');

        // Verificar se a conta contábil existe e não está vazia
        String? contaContabilId = conta?.contaContabilId;
        if (contaContabilId != null && contaContabilId.isNotEmpty) {
          _contaContabil = await _contaContabilService.getById(contaContabilId);
        }
      }

      // Se não encontrou conta contábil específica, buscar uma padrão
      if (_contaContabil == null) {
        // Garantir que o meio de pagamento seja não-nulo para a busca de código
        // Corrigindo o problema de String? vs String
        String meioPagamentoSafe = contaParaRegistrar.meioPagamento ?? 'Boleto'; // Default seguro
        String codigoConta = MeioPagamentoOptions().getCodigoContaPagamento(meioPagamentoSafe);

        final contasEncontradas = await _contaContabilService.getByAttributes({
          'codigo': codigoConta,
          'produtorId': contaParaRegistrar.produtorId,
          'ativo': true,
          'languageCode': languageCode
        });

        if (contasEncontradas.isNotEmpty) {
          _contaContabil = contasEncontradas.first;
        }
      }

      // Se ainda não encontrou, buscamos uma conta genérica de bancos ou fornecedores
      if (_contaContabil == null) {
        final contasBanco = await _contaContabilService.getByAttributes({
          'codigo': ContasBaseConfig.BANCOS,
          'produtorId': contaParaRegistrar.produtorId,
          'ativo': true,
          'languageCode': languageCode
        });

        if (contasBanco.isNotEmpty) {
          _contaContabil = contasBanco.first;
        } else {
          // Última tentativa com conta de fornecedores
          final contasFornecedores = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.FORNECEDORES,
            'produtorId': contaParaRegistrar.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasFornecedores.isNotEmpty) {
            _contaContabil = contasFornecedores.first;
          }
        }
      }

      if (_contaContabil == null) {
        throw Exception('Não foi possível encontrar uma conta contábil apropriada. Verifique se existem contas contábeis básicas configuradas.');
      }

      // ANTES de chamar registrarLancamentosOperacao, busque o nome da conta
      String? nomeConta;
      if (contaParaRegistrar.contaId != null && contaParaRegistrar.contaId!.isNotEmpty) {
        final conta = await _contaService.getById(contaParaRegistrar.contaId!);
        nomeConta = conta?.nome;
      }

      await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
        operacao: 'CreditoParcela',
        produtorId: contaParaRegistrar.produtorId,
        data: contaParaRegistrar.dataVencimento,
        origemId: docId,
        origemTipo: 'contasPagar',
        valor: contaParaRegistrar.valor,
        descricao: 'Parcela ${contaParaRegistrar.numeroParcela ?? 1}/${contaParaRegistrar.totalParcelas ?? 1}${nomeConta != null && nomeConta.isNotEmpty ? ' - $nomeConta' : ''}',
        contaContabil: _contaContabil,
      );
    }
    return docId;
  }

  Future<void> atualizarContaPagar(ContaPagar contaAtualizada, {Duration? timeout}) async {
    _validarContaPagar(contaAtualizada);

    final contaAnterior = await getById(contaAtualizada.id);
    if (contaAnterior == null) {
      throw Exception('Conta a pagar não encontrada');
    }

    // Verificar se mudanças relevantes ocorreram
    bool precisaAtualizarLancamentos = _precisaAtualizarLancamentos(contaAnterior, contaAtualizada);

    if (precisaAtualizarLancamentos) {
      print('------------------------------- Iniciando atualização contábil de conta a pagar: ${contaAtualizada.id}');

      // 1. Buscar a conta contábil anterior
      ContaContabil? contaContabilAnterior;
      if (contaAnterior.contaId != '') {
        final contaAnt = await _contaService.getById(contaAnterior.contaId!);
        contaContabilAnterior = await _contaContabilService.getById(contaAnt?.contaContabilId ?? '');
      }
      contaContabilAnterior ??= (await _contaContabilService.getByAttributes({
        'codigo': MeioPagamentoOptions().getCodigoContaPagamento(contaAnterior.contaId),
        'produtorId': contaAnterior.produtorId,
        'ativo': true,
        'languageCode': languageCode
      })).first;

      // 2. Buscar conta contábil nova (se mudou)
      ContaContabil? contaContabilNova;
      if (contaAtualizada.contaId != '') {
        final contaNova = await _contaService.getById(contaAtualizada.contaId!);
        contaContabilNova = await _contaContabilService.getById(contaNova?.contaContabilId ?? '');
      }
      contaContabilNova ??= (await _contaContabilService.getByAttributes({
        'codigo': MeioPagamentoOptions().getCodigoContaPagamento(contaAtualizada.contaId),
        'produtorId': contaAtualizada.produtorId,
        'ativo': true,
        'languageCode': languageCode
      })).first;

      if (contaContabilAnterior == null || contaContabilNova == null) {
        print('------------------------------- Não foi possível encontrar as contas contábeis necessárias.');
        throw Exception('Conta contábil não encontrada para meio de pagamento');
      }

      // 3. Buscar lançamentos contábeis PROJETADOS PENDENTES
      final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
        'origemId': contaAtualizada.id,
        'origemTipo': 'contasPagar',
        'statusProcessamento': 'pendente'
      });
      print('------------------------------- lancamentosPendentes: ${lancamentosPendentes.length}');

      // 4. Buscar lançamentos contábeis REAIS para estornar
      final lancamentosReais = await _lancamentoContabilService.getByAttributesWithOperators({
        'origemId': [{'operator': '==', 'value': contaAtualizada.id}],
        'origemTipo': [{'operator': '==', 'value': 'contasPagar'}],
        'ativo': [{'operator': '==', 'value': true}]
      });
      print('------------------------------- lancamentosReais a estornar: ${lancamentosReais.length}');

      // 5. Inativar lançamentos PENDENTES
      for (final lancamento in lancamentosPendentes) {
        await _lancamentoContabilProjetadoService.update(
            lancamento.id,
            lancamento.copyWith(ativo: false)
        );
        print('------------------------------- Inativado lançamento pendente: ${lancamento.id}');
      }

      // 6. Criar lançamentos de ESTORNO para cada lançamento real encontrado
      int estornosCriados = 0;
      for (final lancamentoReal in lancamentosReais) {
        try {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoContaPagar',
              produtorId: contaAtualizada.produtorId,
              data: contaAnterior.dataVencimento, // Usar data original para o estorno
              origemId: contaAtualizada.id,
              origemTipo: 'contasPagar',
              valor: lancamentoReal.valor,
              descricao: 'Estorno - Alteração de conta a pagar',
              contaContabil: contaContabilAnterior,
              idLancamentoAnterior: lancamentoReal.id
          );
          estornosCriados++;
          print('------------------------------- Criado estorno para lançamento: ${lancamentoReal.id}');
        } catch (e) {
          print('------------------------------- Erro ao criar estorno: $e');
        }
      }

      // ANTES de criar o novo lançamento, busque o nome da conta
      String? nomeContaNova;
      if (contaAtualizada.contaId != null && contaAtualizada.contaId!.isNotEmpty) {
        final conta = await _contaService.getById(contaAtualizada.contaId!);
        nomeContaNova = conta?.nome;
      }

      // 7. Criar NOVO lançamento para a conta a pagar atualizada
      await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
        operacao: 'CreditoParcela',
        produtorId: contaAtualizada.produtorId,
        data: contaAtualizada.dataVencimento,
        origemId: contaAtualizada.id,
        origemTipo: 'contasPagar',
        valor: contaAtualizada.valor,
        descricao: 'Parcela ${contaAtualizada.numeroParcela ?? 1}/${contaAtualizada.totalParcelas ?? 1}${nomeContaNova != null && nomeContaNova.isNotEmpty ? ' - $nomeContaNova' : ''}',
        contaContabil: contaContabilNova,
      );
      print('------------------------------- Criado novo lançamento para conta a pagar atualizada');

      print('------------------------------- Conta a pagar atualizada: ${contaAtualizada.id}, com $estornosCriados estornos criados');
    }

    // 8. Salvar a atualização da conta a pagar
    await update(contaAtualizada.id, contaAtualizada, timeout: timeout);
  }

// Verifica se mudanças relevantes para contabilidade ocorreram
  bool _precisaAtualizarLancamentos(ContaPagar anterior, ContaPagar atual) {
    return anterior.valor != atual.valor ||
        anterior.dataVencimento != atual.dataVencimento ||
        anterior.contaId != atual.contaId ||
        anterior.meioPagamento != atual.meioPagamento;
  }

  Future<void> registrarPagamento(
      String contaPagarId,
      double valorPagamento,
      {
        Duration? timeout,
        DateTime? dataPagamento,  // Novo parâmetro opcional
      }
      ) async {
    if (valorPagamento <= 0) {
      throw Exception('Valor de pagamento inválido');
    }

    final contaAtual = await getById(contaPagarId);
    if (contaAtual == null) {
      throw Exception('Conta a pagar não encontrada');
    }

    final double novoValorPago = contaAtual.valorPago + valorPagamento;
    if (novoValorPago > contaAtual.valor) {
      throw Exception('Valor de pagamento excede o valor da conta');
    }

    final String novoStatus = _determinarNovoStatus(contaAtual.valor, novoValorPago);

    // Se um pagamento completo está sendo registrado sem informar data,
    // usar a data de vencimento para manter consistência com registros automáticos
    DateTime dataEfetivaPagamento;
    if (novoStatus == 'pago' && dataPagamento == null) {
      // Para pagamentos totais sem data específica, preferir a data de vencimento
      dataEfetivaPagamento = contaAtual.dataVencimento;
    } else {
      // Caso contrário usar a data fornecida ou data atual
      dataEfetivaPagamento = dataPagamento ?? DateTime.now();
    }

    final contaAtualizada = contaAtual.copyWith(
      valorPago: novoValorPago,
      status: novoStatus,
      dataPagamento: novoStatus == 'pago' ? dataEfetivaPagamento : null,
    );

    await atualizarContaPagar(contaAtualizada, timeout: timeout);
  }

  Future<void> cancelarContaPagar(String contaPagarId, {Duration? timeout}) async {
    print('------------------------------- Iniciando cancelamento de conta a pagar: $contaPagarId');
    final contaAtual = await getById(contaPagarId);
    if (contaAtual == null) {
      throw Exception('Conta a pagar não encontrada');
    }

    if (contaAtual.status == 'pago') {
      throw Exception('Não é possível cancelar uma conta já paga');
    }

    // 1. Buscar a conta contábil - exatamente como no método excluirContaPagar
    ContaContabil? contaContabil;
    if (contaAtual.contaId != '') {
      final conta = await _contaService.getById(contaAtual.contaId!);
      contaContabil = await _contaContabilService.getById(conta?.contaContabilId ?? '');
    }
    contaContabil ??= (await _contaContabilService.getByAttributes({
      'codigo': MeioPagamentoOptions().getCodigoContaPagamento(contaAtual.contaId),
      'produtorId': contaAtual.produtorId,
      'ativo': true,
      'languageCode': languageCode
    })).first;

    if (contaContabil == null) {
      print('------------------------------- Não foi possível encontrar a conta contábil para gerar estornos.');
      throw Exception('Conta contábil não encontrada para meio de pagamento');
    }

    // 2. Buscar lançamentos contábeis PROJETADOS PENDENTES - mesmo formato do excluirContaPagar
    final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
      'origemId': contaPagarId,
      'origemTipo': 'contasPagar',
      'statusProcessamento': 'pendente'
    });
    print('------------------------------- lancamentosPendentes: ${lancamentosPendentes.length}');

    // 3. Buscar lançamentos contábeis REAIS para estornar - mesmo formato do excluirContaPagar
    final lancamentosReais = await _lancamentoContabilService.getByAttributesWithOperators({
      'origemId': [{'operator': '==', 'value': contaPagarId}],
      'origemTipo': [{'operator': '==', 'value': 'contasPagar'}],
      'ativo': [{'operator': '==', 'value': true}]
    });
    print('------------------------------- lancamentosReais a estornar: ${lancamentosReais.length}');

    // 4. Inativar lançamentos PENDENTES - mesmo formato do excluirContaPagar
    for (final lancamento in lancamentosPendentes) {
      await _lancamentoContabilProjetadoService.update(
          lancamento.id,
          lancamento.copyWith(ativo: false)
      );
      print('------------------------------- Inativado lançamento pendente: ${lancamento.id}');
    }

    // 5. Criar lançamentos de ESTORNO para cada lançamento real - mesmo formato do excluirContaPagar
    int estornosCriados = 0;
    for (final lancamentoReal in lancamentosReais) {
      try {
        await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
            operacao: 'EstornoContaPagar', // Mesma operação usada no excluirContaPagar
            produtorId: contaAtual.produtorId,
            data: contaAtual.dataVencimento,
            origemId: contaPagarId,
            origemTipo: 'contasPagar', // Mesmo origemTipo do excluirContaPagar
            valor: lancamentoReal.valor,
            descricao: 'Estorno - Cancelamento de conta a pagar',
            contaContabil: contaContabil,
            idLancamentoAnterior: lancamentoReal.id
        );
        estornosCriados++;
        print('------------------------------- Criado estorno para lançamento: ${lancamentoReal.id}');
      } catch (e) {
        print('------------------------------- Erro ao criar estorno: $e');
      }
    }

    // 6. Atualizar a conta a pagar para cancelada (esta parte é específica do cancelamento)
    final contaAtualizada = contaAtual.copyWith(
        status: 'cancelado',
        ativo: false
    );

    // 7. Salvar a atualização da conta a pagar
    await update(contaAtualizada.id, contaAtualizada, timeout: timeout);

    print('------------------------------- Conta a pagar cancelada: $contaPagarId, com $estornosCriados estornos criados');
  }

  Future<List<ContaPagar>> buscarContasPorStatus(String status, {Duration? timeout}) {
    return getByAttributes({
      'status': status,
      'ativo': true
    });
  }

  Future<List<ContaPagar>> buscarContasVencidas({Duration? timeout}) async {
    return getByAttributesWithOperators(
        {
          'dataVencimento': [{'operator': '<', 'value': DateTime.now()}],
          'status': [{'operator': 'in', 'value': ['aberto', 'parcial']}],
          'ativo': [{'operator': '==', 'value': true}]
        },
    );
  }

  Future<List<ContaPagar>> buscarContasPorPeriodo(
      DateTime dataInicial,
      DateTime dataFinal,
      {Duration? timeout}
      ) async {
    return getByAttributesWithOperators(
        {
          'dataVencimento': [
            {'operator': '>=', 'value': dataInicial},
            {'operator': '<=', 'value': dataFinal}
          ],
          'ativo': [{'operator': '==', 'value': true}]
        },
    );
  }

  void _validarContaPagar(ContaPagar conta) {
      if (MeioPagamentoOptions.requiresContaPagamento(conta.meioPagamento)) {
          if (conta.contaId == null || conta.contaId == '') {
            throw Exception('Dados da conta a pagar incompletos ou inválidos');
          }
      }
      if (conta.valor <= 0 || conta.dataVencimento == null) {
          throw Exception('Dados da conta a pagar incompletos ou inválidos');
      }
  }

  String _determinarNovoStatus(double valorTotal, double valorPago) {
    if (valorPago >= valorTotal) return 'pago';
    if (valorPago > 0) return 'parcial';
    return 'aberto';
  }

  Future<void> _gerarMovimentacaoProjetada(
      ContaPagar contaPagar,
      String tipoOperacao
      ) async {
    // await _movimentacaoFinanceiraProjetadaService.criarMovimentacao(
    //   MovimentacaoFinanceiraProjetada(
    //     id: '',
    //     contaId: contaPagar.contaId,
    //     produtorId: contaPagar.produtorId,
    //     valor: contaPagar.valor,
    //     tipo: 'Debito',
    //     categoria: 'ContaPagar${tipoOperacao}',
    //     data: contaPagar.dataVencimento,
    //     timestampLocal: DateTime.now().toLocal(),
    //     saldoProjetado: 0.0,
    //     origemId: contaPagar.id,
    //     origemTipo: 'contasPagar',
    //     ativo: true,
    //     deviceId: AppStateManager().deviceId,
    //     statusProcessamento: 'pendente',
    //     idMovimentacaoReal: null,
    //     dadosOriginais: null,
    //     dataProcessamento: null,
    //     erroProcessamento: null,
    //     numeroDocumento: contaPagar.numeroDocumento,
    //   ),
    // );
  }

  Future<void> _atualizarMovimentacoesProjetadas(
      ContaPagar contaAnterior,
      ContaPagar contaAtualizada
      ) async {
    // Se foi cancelada ou inativada
    if (contaAtualizada.status == 'cancelado' || !contaAtualizada.ativo) {
      await _gerarMovimentacaoEstorno(contaAnterior);
      return;
    }

    // Se houve alteração relevante
    if (_precisaAtualizarMovimentacao(contaAnterior, contaAtualizada)) {
      //await _gerarMovimentacaoEstorno(contaAnterior);
      //await _gerarMovimentacaoProjetada(contaAtualizada, 'Alteracao');
    }
  }

  Future<void> _gerarMovimentacaoEstorno(ContaPagar contaAnterior) async {
    // await _movimentacaoFinanceiraProjetadaService.criarMovimentacao(
    //   MovimentacaoFinanceiraProjetada(
    //     id: '',
    //     contaId: contaAnterior.contaId,
    //     produtorId: contaAnterior.produtorId,
    //     valor: contaAnterior.valor,
    //     tipo: 'Credito',
    //     categoria: 'EstornoContaPagar',
    //     data: contaAnterior.dataVencimento,
    //     timestampLocal: DateTime.now().toLocal(),
    //     saldoProjetado: 0.0,
    //     origemId: contaAnterior.id,
    //     origemTipo: 'contasPagar',
    //     ativo: false,
    //     deviceId: AppStateManager().deviceId,
    //     statusProcessamento: 'pendente',
    //     idMovimentacaoReal: null,
    //     dadosOriginais: contaAnterior.toMap(),
    //     dataProcessamento: null,
    //     erroProcessamento: null,
    //     numeroDocumento: contaAnterior.numeroDocumento,
    //   ),
    // );
  }

  // Método corrigido para excluir conta a pagar e seus lançamentos contábeis associados
  // Método corrigido para respeitar a arquitetura e separação de responsabilidades
  Future<void> excluirContaPagar(String contaPagarId) async {
    print('------------------------------- Entrou em excluirContaPagar: $contaPagarId');
    final contaPagar = await getById(contaPagarId);
    if (contaPagar == null) {
      throw Exception('Conta a pagar não encontrada');
    }

    // 1. Buscar a conta contábil - MODIFICADO PARA EVITAR IDs VAZIOS
    ContaContabil? contaContabil;
    if (contaPagar.contaId != null && contaPagar.contaId!.isNotEmpty) {
      final conta = await _contaService.getById(contaPagar.contaId!);
      // Verificar se contaContabilId existe e não é vazio antes de buscar
      if (conta != null && conta.contaContabilId != null && conta.contaContabilId!.isNotEmpty) {
        contaContabil = await _contaContabilService.getById(conta.contaContabilId!);
      }
    }

    // Se não encontrou por ID específico, tenta buscar por código
    if (contaContabil == null) {
      try {
        // Garantir meio de pagamento não-nulo
        String meioPagamentoSafe = contaPagar.meioPagamento ?? 'Boleto'; // Default seguro
        String codigoConta = MeioPagamentoOptions().getCodigoContaPagamento(meioPagamentoSafe);

        // Só buscar se tiver um código válido
        if (codigoConta.isNotEmpty) {
          final contasEncontradas = await _contaContabilService.getByAttributes({
            'codigo': codigoConta,
            'produtorId': contaPagar.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasEncontradas.isNotEmpty) {
            contaContabil = contasEncontradas.first;
          }
        }
      } catch (e) {
        print('Erro ao buscar conta contábil por código: $e');
      }
    }

    // Se ainda não encontrou, busca uma conta genérica
    if (contaContabil == null) {
      try {
        final contasBanco = await _contaContabilService.getByAttributes({
          'codigo': ContasBaseConfig.BANCOS,
          'produtorId': contaPagar.produtorId,
          'ativo': true,
          'languageCode': languageCode
        });

        if (contasBanco.isNotEmpty) {
          contaContabil = contasBanco.first;
        } else {
          // Última tentativa com conta de fornecedores
          final contasFornecedores = await _contaContabilService.getByAttributes({
            'codigo': ContasBaseConfig.FORNECEDORES,
            'produtorId': contaPagar.produtorId,
            'ativo': true,
            'languageCode': languageCode
          });

          if (contasFornecedores.isNotEmpty) {
            contaContabil = contasFornecedores.first;
          }
        }
      } catch (e) {
        print('Erro ao buscar conta contábil genérica: $e');
      }
    }

    // Se mesmo assim não encontrou, continua sem estorno contábil
    if (contaContabil == null) {
      print('Aviso: Não foi possível encontrar conta contábil para estorno. Continuando exclusão sem estorno contábil.');
    }

    // O restante do método permanece igual...
    // 2. Buscar lançamentos contábeis PROJETADOS PENDENTES
    final lancamentosPendentes = await _lancamentoContabilProjetadoService.getByAttributes({
      'origemId': contaPagarId,
      'origemTipo': 'contasPagar',
      'statusProcessamento': 'pendente'
    });
    print('------------------------------- lancamentosPendentes: ${lancamentosPendentes.length}');

    // 3. Buscar lançamentos contábeis REAIS para estornar
    final lancamentosReais = await _lancamentoContabilService.getByAttributesWithOperators({
      'origemId': [{'operator': '==', 'value': contaPagarId}],
      'origemTipo': [{'operator': '==', 'value': 'contasPagar'}],
      'ativo': [{'operator': '==', 'value': true}]
    });
    print('------------------------------- lancamentosReais a estornar: ${lancamentosReais.length}');

    // 4. Inativar lançamentos PENDENTES
    for (final lancamento in lancamentosPendentes) {
      await _lancamentoContabilProjetadoService.update(
          lancamento.id,
          lancamento.copyWith(ativo: false)
      );
    }

    // 5. Criar lançamentos de ESTORNO para cada lançamento real encontrado
    int estornosCriados = 0;
    if (contaContabil != null) { // Só criar estornos se tiver conta contábil
      for (final lancamentoReal in lancamentosReais) {
        try {
          await _lancamentoContabilProjetadoService.registrarLancamentosOperacao(
              operacao: 'EstornoContaPagar',
              produtorId: contaPagar.produtorId,
              data: contaPagar.dataVencimento,
              origemId: contaPagarId,
              origemTipo: 'contasPagar',
              valor: lancamentoReal.valor,
              descricao: 'Estorno - Exclusão de conta a pagar',
              contaContabil: contaContabil,
              idLancamentoAnterior: lancamentoReal.id
          );
          estornosCriados++;
          print('------------------------------- Criado estorno para lançamento: ${lancamentoReal.id}');
        } catch (e) {
          print('------------------------------- Erro ao criar estorno: $e');
        }
      }
    }

    // 6. Remover a conta a pagar
    await delete(contaPagarId);
    print('------------------------------- Conta a pagar excluída: $contaPagarId, com $estornosCriados estornos criados');
  }

  bool _precisaAtualizarMovimentacao(ContaPagar anterior, ContaPagar atual) {
    return anterior.valor != atual.valor ||
        anterior.dataVencimento != atual.dataVencimento ||
        anterior.contaId != atual.contaId;
  }
}