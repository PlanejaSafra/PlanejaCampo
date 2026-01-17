import 'package:planejacampo/models/contabil/lancamento_contabil.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/utils/finances/lancamento_contabil_options.dart';
import 'package:planejacampo/utils/finances/operacoes_contabeis_config.dart';
//import 'package:planejacampo/utils/conta_contabil_config.dart';
import '../generic_service.dart';

class LancamentoContabilService extends GenericService<LancamentoContabil> {
  final ContaContabilService _contaContabilService = ContaContabilService();
  final Duration defaultTimeout = const Duration(seconds: 3);

  LancamentoContabilService() : super('lancamentosContabeis');

  @override
  LancamentoContabil fromMap(Map<String, dynamic> map, String documentId) {
    return LancamentoContabil.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(LancamentoContabil lancamentoContabil) {
    return lancamentoContabil.toMap();
  }

  // Registra partidas (lançamentos relacionados)
  Future<void> _registrarPartidas({
    required DateTime data,
    required String produtorId,
    required String origemId,
    required String origemTipo,
    required List<Map<String, dynamic>> partidas,
    String? descricao,
  }) async {
    final String loteId = DateTime.now().toString();
    final DateTime timestamp = DateTime.now();

    for (var partida in partidas) {
      final String contaContabilId = partida['contaContabilId'];
      final String tipo = partida['tipo'];
      final double valor = partida['valor'];

      // Obter o saldo anterior
      final Map<String, dynamic> saldoAnterior = await _carregarSaldoAnterior(
          contaContabilId: contaContabilId,
          data: data
      );

      // Obter a natureza da conta
      final ContaContabil? conta = await _contaContabilService.getById(contaContabilId);
      if (conta == null) throw Exception('Conta não encontrada');

      // Calcular novo saldo
      final resultadoCalculo = LancamentoContabilOptions.calcularSaldo(
          tipo: tipo,
          categoria: '', // Não usamos categoria em lançamentos reais
          valor: valor,
          saldoAtual: saldoAnterior['saldoConta'],
          naturezaConta: conta.natureza
      );

      final lancamento = LancamentoContabil(
        id: DateTime.now().toString(),
        produtorId: produtorId,
        data: data,
        contaContabilId: contaContabilId,
        tipo: tipo,
        valor: valor,
        saldoAtual: resultadoCalculo['novoSaldo'],
        origemId: origemId,
        origemTipo: origemTipo,
        descricao: descricao,
        ativo: true,
        loteId: loteId,
        timestamp: timestamp,
      );

      await add(lancamento);
    }
  }

  Future<Map<String, dynamic>> _carregarSaldoAnterior({
    required String contaContabilId,
    required DateTime data,
  }) async {
    final lancamentosAnteriores = await getByAttributesWithOperators(
        {
          'contaContabilId': [{'value': contaContabilId, 'operator': '=='}],
          'data': [{'value': data, 'operator': '<'}],
          'ativo': [{'value': true, 'operator': '=='}],
        },
        orderBy: [
          {'field': 'data', 'direction': 'desc'},
          {'field': 'timestamp', 'direction': 'desc'}
        ],
        limit: 1
    );

    if (lancamentosAnteriores.isNotEmpty) {
      return {
        'saldoConta': lancamentosAnteriores.first.saldoAtual,
        'dataUltimaAtualizacao': lancamentosAnteriores.first.data,
      };
    }

    return {
      'saldoConta': 0.0,
      'dataUltimaAtualizacao': data,
    };
  }




  // Estorna lançamento
  // Estorna um lote de lançamentos
  Future<void> _estornarLote(String loteId, {String? descricao}) async {
    final lancamentos = await getByAttributes({'loteId': loteId, 'ativo': true});

    if (lancamentos.isEmpty) {
      throw Exception('Lote não encontrado ou já estornado');
    }

    final String novoLoteId = DateTime.now().toString();
    final DateTime timestamp = DateTime.now();

    for (var lancamento in lancamentos) {
      // Cria lançamento de estorno invertendo o tipo (débito/crédito)
      final estorno = lancamento.copyWith(
        id: DateTime.now().toString(),
        tipo: lancamento.tipo == 'debito' ? 'credito' : 'debito',
        descricao: descricao ?? 'Estorno: ${lancamento.descricao}',
        estornoId: lancamento.id,
        loteId: novoLoteId,
        timestamp: timestamp,
      );

      await add(estorno);

      // Marca lançamento original como inativo
      await update(lancamento.id, lancamento.copyWith(ativo: false));
    }
  }

  // Busca saldo de uma conta em um período
  Future<double> getSaldoConta({
    required String contaContabilId,
    required DateTime dataInicial,
    required DateTime dataFinal,
  }) async {
    final lancamentos = await getByAttributesWithOperators(
        {
          'contaContabilId': [{'operator': '==', 'value': contaContabilId}],
          'data': [
            {'operator': '>=', 'value': dataInicial},
            {'operator': '<=', 'value': dataFinal}
          ],
          'ativo': [{'operator': '==', 'value': true}]
        },
        orderBy: [
          {'field': 'data', 'direction': 'desc'},
          {'field': 'timestamp', 'direction': 'desc'}
        ],
        limit: 1
    );

    if (lancamentos.isEmpty) return 0.0;
    return lancamentos.first.saldoAtual;  // Retorna o saldo mais recente
  }

  // Busca saldo hierárquico (inclui subcontas)
  Future<double> getSaldoHierarquico({
    required String codigoConta,
    required DateTime dataInicial,
    required DateTime dataFinal,
    required String produtorId,
    required String languageCode,
  }) async {
    // Busca conta principal
    final ContaContabil? contaPrincipal = await _contaContabilService.getByCode(
      codigoConta,
      produtorId,
      languageCode
    );

    if (contaPrincipal == null) {
      throw Exception('Conta não encontrada');
    }

    double saldoTotal = 0;

    // Se for conta analítica, retorna seu próprio saldo
    if (contaPrincipal.tipo == 'analitica') {
      return getSaldoConta(
        contaContabilId: contaPrincipal.id,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
      );
    }

    // Para contas sintéticas, busca recursivamente todas as subcontas
    final subcontas = await _contaContabilService.getByAttributes({
      'produtorId': produtorId,
      'ativo': true,
      'codigo': {'operator': 'startsWith', 'value': codigoConta},
      'languageCode': {'operator': '==', 'value': languageCode}
    });

    // Soma saldos de todas as contas analíticas
    for (var conta in subcontas.where((c) => c.tipo == 'analitica')) {
      final saldoConta = await getSaldoConta(
        contaContabilId: conta.id,
        dataInicial: dataInicial,
        dataFinal: dataFinal,
      );
      saldoTotal += saldoConta;
    }

    return saldoTotal;
  }

  // Registra lançamentos para uma operação
  Future<void> _registrarLancamentosOperacao({
    required String operacao,
    required String produtorId,
    required DateTime data,
    required String origemId,
    required String origemTipo,
    required double valor,
    required String languageCode,
    String? descricao,
  }) async {
    // Obtém contas configuradas para a operação
    AppStateManager appStateManager = AppStateManager();
    final contas = OperacoesContabeisConfig.getMapeamentoOperacoes(appStateManager.appLocale.languageCode)[operacao];
    if (contas == null) {
      throw Exception('Operação não configurada: $operacao');
    }

    final List<Map<String, dynamic>> partidas = [];

    // Monta partidas conforme operação
    switch (operacao) {
      case 'CompraInsumo':
        final ContaContabil? contaEstoque = await _contaContabilService.getByCode(
          contas['estoque']!,
          produtorId,
          languageCode
        );
        final ContaContabil? contaFornecedor = await _contaContabilService.getByCode(
            contas['fornecedor']!,
            produtorId,
            languageCode
        );

        if (contaEstoque == null || contaFornecedor == null) {
          throw Exception('Contas não encontradas para operação');
        }

        partidas.addAll([
          {
            'contaContabilId': contaEstoque.id,
            'tipo': 'debito',
            'valor': valor
          },
          {
            'contaContabilId': contaFornecedor.id,
            'tipo': 'credito',
            'valor': valor
          }
        ]);
        break;

    // Adicionar outros casos conforme necessário
      default:
        throw Exception('Operação não implementada: $operacao');
    }

    // Registra as partidas
    await _registrarPartidas(
      data: data,
      produtorId: produtorId,
      origemId: origemId,
      origemTipo: origemTipo,
      partidas: partidas,
      descricao: descricao,
    );
  }
}