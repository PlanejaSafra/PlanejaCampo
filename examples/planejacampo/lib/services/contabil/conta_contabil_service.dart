// conta_contabil_service.dart
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/utils/finances/operacoes_contabeis_config.dart';
import 'package:planejacampo/utils/finances/plano_contas_config.dart';
//import 'package:planejacampo/services/finances/lancamento_contabil_service.dart';
//import 'package:planejacampo/utils/conta_contabil_config.dart';
import '../generic_service.dart';

class ContaContabilService extends GenericService<ContaContabil> {
  ContaContabilService() : super('contasContabeis');

  final Duration defaultTimeout = const Duration(seconds: 3);
  //final LancamentoContabilService _lancamentoContabilService = LancamentoContabilService();


  @override
  ContaContabil fromMap(Map<String, dynamic> map, String documentId) {
    return ContaContabil.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ContaContabil contaContabil) {
    return contaContabil.toMap();
  }

  // Busca conta por código
  Future<ContaContabil?> getByCode(String codigo, String produtorId, String languageCode) async {
    final contas = await getByAttributes({
      'codigo': codigo,
      'produtorId': produtorId,
      'ativo': true,
      'languageCode': languageCode,
    });
    return contas.isNotEmpty ? contas.first : null;
  }

  // Busca contas de um determinado nível
  Future<List<ContaContabil>> getContasNivel(String nivel, String produtorId) async {
    return getByAttributesWithOperators({
      'codigo': [{'operator': 'startsWith', 'value': nivel}],
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'ativo': [{'operator': '==', 'value': true}]
    });
  }

  // Busca contas filhas diretas
  Future<List<ContaContabil>> getContasFilhas(String contaPaiId) async {
    return getByAttributes({
      'contaPaiId': contaPaiId,
      'ativo': true
    });
  }

  // Busca todas as contas filhas (recursivamente)
  Future<List<ContaContabil>> getTodasContasFilhas(String codigo, String produtorId) async {
    return getByAttributesWithOperators({
      'codigo': [{'operator': 'startsWith', 'value': codigo}],
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'ativo': [{'operator': '==', 'value': true}]
    });
  }

  // Busca contas analíticas de um grupo
  Future<List<ContaContabil>> getContasAnaliticas(String codigoGrupo, String produtorId) async {
    return getByAttributesWithOperators({
      'codigo': [{'operator': 'startsWith', 'value': codigoGrupo}],
      'produtorId': [{'operator': '==', 'value': produtorId}],
      'tipo': [{'operator': '==', 'value': 'analitica'}],
      'ativo': [{'operator': '==', 'value': true}]
    });
  }

  // Inicializa plano de contas padrão
  Future<void> initPlanoContas(String produtorId, String languageCode) async {
    final planoContasPadrao = PlanoContasConfig.getPlanoContasPadrao(languageCode);

    for (var contaMap in planoContasPadrao) {
      // Verifica se a conta já existe
      final contasExistentes = await getByAttributes({
        'codigo': contaMap['codigo'],
        'produtorId': produtorId,
      });

      if (contasExistentes.isEmpty) {
        // Cria nova conta
        await add(ContaContabil(
          id: DateTime.now().toString(),
          codigo: contaMap['codigo'],
          nome: contaMap['nome'],
          tipo: contaMap['tipo'],
          natureza: contaMap['natureza'],
          contaPaiId: contaMap['contaPaiId'],
          ativo: true,
          produtorId: produtorId,
          languageCode: languageCode,
        ));
      } else {
        // Atualiza conta existente
        final contaExistente = contasExistentes.first;
        await update(contaExistente.id, contaExistente.copyWith(
          nome: contaMap['nome'],
          tipo: contaMap['tipo'],
          natureza: contaMap['natureza'],
          contaPaiId: contaMap['contaPaiId'],
        ));
      }
    }
  }

  // Obtém contas para uma operação específica
  Future<Map<String, ContaContabil>> getContasOperacao(
      String operacao,
      String produtorId,
      String languageCode
      ) async {
    final mapaContas = OperacoesContabeisConfig.getMapeamentoOperacoes(languageCode)[operacao];
    if (mapaContas == null) return {};

    Map<String, ContaContabil> resultado = {};
    for (var entry in mapaContas.entries) {
      final conta = await getByCode(entry.value, produtorId, languageCode);
      if (conta != null) {
        resultado[entry.key] = conta;
      }
    }
    return resultado;
  }

  // Verifica se uma conta tem movimento
  //Future<bool> temMovimento(String contaId) async {
  //  final lancamentos = await _lancamentoContabilService.getByAttributes({
  //    'contaId': contaId,
  //    'ativo': true
  //  }, limit: 1);
  //  return lancamentos.isNotEmpty;
  //}

  // Inativa uma conta (se não tiver movimento)
  //Future<void> inativarConta(String contaId) async {
  //  if (await temMovimento(contaId)) {
  //    throw Exception('Não é possível inativar conta com movimentação');
  //  }
  //  final conta = await getById(contaId);
  //  if (conta == null) throw Exception('Conta não encontrada');
  //  await update(contaId, conta.copyWith(ativo: false));
  //}
}