// lib/utils/finances/conta_contabil_resolver.dart

import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/utils/finances/contas_atividade_config.dart';
import 'package:planejacampo/utils/finances/operacoes_contabeis_config.dart';

/// Classe responsável por resolver contas contábeis baseadas no contexto da operação
class ContaContabilResolver {

  /// Resolve uma conta baseada em um template e no contexto
  static String resolverConta({
    required String template,
    AtividadeRural? atividadeAtiva,
    required String contaPadrao,
    String? operacao,
  }) {
    // Se não for um template, retorna a própria conta
    if (!_isTemplate(template)) {
      return template;
    }

    // Extrai o identificador do template
    String identificador = _extrairIdentificadorTemplate(template);

    // Resolve a conta baseada na atividade
    return ContasAtividadeConfig.getContaAtividade(
        template: identificador,
        tipo: atividadeAtiva?.tipo,
        subtipo: atividadeAtiva?.subtipo,
        contaPadrao: contaPadrao
    );
  }

  /// Resolve todas as partidas de uma operação
  static List<Map<String, dynamic>> resolverPartidasOperacao({
    required String operacao,
    required double valor,
    AtividadeRural? atividadeAtiva,
    String? complemento,
  }) {
    // Obtém a configuração da operação
    final configOperacoes = OperacoesContabeisConfig.getMapeamentoOperacoes('pt');
    final configOperacao = configOperacoes[operacao];

    if (configOperacao == null) {
      throw Exception('Operação não encontrada: $operacao');
    }

    // Verifica se a operação requer atividade
    if (configOperacao['requerAtividade'] == true && atividadeAtiva == null) {
      throw Exception('Operação $operacao requer uma atividade ativa');
    }

    // Gera as partidas resolvendo as contas
    return OperacoesContabeisConfig.gerarPartidas(
        operacao: operacao,
        configuracao: configOperacao,
        atividadeRural: atividadeAtiva,
        valor: valor,
        complemento: complemento
    );
  }

  /// Resolve contas envolvidas em uma transferência
  static Map<String, String> resolverContasTransferencia({
    required String contaOrigem,
    required String contaDestino,
    AtividadeRural? atividadeAtiva,
  }) {
    String contaOrigemResolvida = resolverConta(
        template: contaOrigem,
        atividadeAtiva: atividadeAtiva,
        contaPadrao: contaOrigem
    );

    String contaDestinoResolvida = resolverConta(
        template: contaDestino,
        atividadeAtiva: atividadeAtiva,
        contaPadrao: contaDestino
    );

    return {
      'origem': contaOrigemResolvida,
      'destino': contaDestinoResolvida
    };
  }

  /// Resolve contas para um estorno
  static List<Map<String, dynamic>> resolverPartidasEstorno({
    required List<Map<String, dynamic>> partidasOriginais,
    AtividadeRural? atividadeAtiva,
    required double valorEstorno,
    String? complemento,
  }) {
    List<Map<String, dynamic>> partidasEstorno = [];

    for (var partida in partidasOriginais) {
      // Resolve a conta considerando a atividade atual
      String contaResolvida = resolverConta(
          template: partida['contaId'],
          atividadeAtiva: atividadeAtiva,
          contaPadrao: partida['contaId']
      );

      // Inverte o tipo do lançamento
      String tipoEstorno = partida['tipo'] == 'debito' ? 'credito' : 'debito';

      // Cria a partida de estorno
      partidasEstorno.add({
        'contaId': contaResolvida,
        'tipo': tipoEstorno,
        'valor': valorEstorno,
        'historico': 'Estorno - ${partida['historico']}${complemento != null ? ' - $complemento' : ''}'
      });
    }

    return partidasEstorno;
  }

  /// Verifica se uma string é um template de conta
  static bool _isTemplate(String conta) {
    return conta.startsWith('{') && conta.endsWith('}');
  }

  /// Extrai o identificador de um template
  static String _extrairIdentificadorTemplate(String template) {
    return template.substring(1, template.length - 1);
  }

  /// Verifica se as contas resolvidas são válidas para a operação
  static bool validarContasOperacao({
    required String operacao,
    required List<String> contas,
    AtividadeRural? atividadeAtiva,
  }) {
    final configOperacoes = OperacoesContabeisConfig.getMapeamentoOperacoes('pt');
    final configOperacao = configOperacoes[operacao];

    if (configOperacao == null) {
      return false;
    }

    // Verifica necessidade de atividade
    if (configOperacao['requerAtividade'] == true && atividadeAtiva == null) {
      return false;
    }

    // Verifica se alguma conta é nula ou vazia
    if (contas.any((conta) => conta.isEmpty)) {
      return false;
    }

    // Verifica se todas as contas pertencem ao contexto correto
    if (atividadeAtiva != null) {
      for (String conta in contas) {
        if (ContasAtividadeConfig.requerAtividade(conta)) {
          if (!ContasAtividadeConfig.isContaAtividade(
              conta: conta,
              tipo: atividadeAtiva.tipo,
              subtipo: atividadeAtiva.subtipo
          )) {
            return false;
          }
        }
      }
    }

    return true;
  }
}