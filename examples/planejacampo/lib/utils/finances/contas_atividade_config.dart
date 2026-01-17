// lib/utils/finances/contas_atividade_config.dart

import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/utils/atividade_rural_options.dart';

/// Configuração do mapeamento entre atividades rurais e contas contábeis
class ContasAtividadeConfig {

  /// Retorna o mapeamento entre tipos de atividade e suas contas contábeis
  static Map<String, Map<String, Map<String, String>>> getMapeamentoContasAtividade() {
    Map<String, Map<String, Map<String, String>>> mapeamento = {};

    // Preenche o mapeamento para cada tipo de atividade
    for (String tipoAtividade in AtividadeRuralOptions.tiposAtividade) {
      mapeamento[tipoAtividade] = {};

      // Preenche os subtipos para cada tipo de atividade
      List<String> subtipos = AtividadeRuralOptions.getSubtipos(tipoAtividade);
      for (String subtipo in subtipos) {
        mapeamento[tipoAtividade]![subtipo] = _getContasSubtipo(tipoAtividade, subtipo);
      }
    }

    return mapeamento;
  }

  /// Retorna as contas específicas para um subtipo de atividade
  static Map<String, String> _getContasSubtipo(String tipo, String subtipo) {
    switch (tipo.toUpperCase()) {
      case 'AGRICULTURA':
        return _getContasAtividadeAgricola(subtipo);
      case 'PECUARIA':
        return _getContasAtividadePecuaria(subtipo);
      case 'SILVICULTURA':
        return _getContasAtividadeSilvicultura(subtipo);
      default:
        return _getContasPadrao();
    }
  }

  /// Retorna as contas para atividades agrícolas
  static Map<String, String> _getContasAtividadeAgricola(String subtipo) {
    return {
      'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'RECEITAS_ATIVIDADE': ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
      'ESTOQUE_PRODUCAO': ContasBaseConfig.ESTOQUE_PRODUCAO,
      'CUSTOS_ESPECIFICOS': ContasBaseConfig.CUSTOS_PRODUCAO,
      'CULTURAS_FORMACAO': ContasBaseConfig.CULTURAS_FORMACAO,
    };
  }

  /// Retorna as contas para atividades pecuárias
  static Map<String, String> _getContasAtividadePecuaria(String subtipo) {
    return {
      'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS,
      'RECEITAS_ATIVIDADE': ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS,
      'ESTOQUE_PRODUCAO': ContasBaseConfig.ESTOQUE_PRODUCAO,
      'ATIVOS_BIOLOGICOS': ContasBaseConfig.GADO,
      'CUSTOS_ESPECIFICOS': ContasBaseConfig.CUSTOS_PRODUCAO,
    };
  }

  /// Retorna as contas para atividades de silvicultura
  static Map<String, String> _getContasAtividadeSilvicultura(String subtipo) {
    return {
      'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      'RECEITAS_ATIVIDADE': ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
      'ESTOQUE_PRODUCAO': ContasBaseConfig.ESTOQUE_PRODUCAO,
      'ATIVOS_BIOLOGICOS': ContasBaseConfig.FLORESTAS,
      'CUSTOS_ESPECIFICOS': ContasBaseConfig.CUSTOS_PRODUCAO,
    };
  }

  /// Retorna as contas padrão para outros tipos de atividade
  static Map<String, String> _getContasPadrao() {
    return {
      'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_INDIRETOS,
      'RECEITAS_ATIVIDADE': ContasBaseConfig.OUTRAS_RECEITAS,
      'ESTOQUE_PRODUCAO': ContasBaseConfig.ESTOQUE_PRODUCAO,
      'CUSTOS_ESPECIFICOS': ContasBaseConfig.CUSTOS_PRODUCAO,
    };
  }

  /// Obtém a conta específica para uma atividade
  static String getContaAtividade({
    required String template,
    String? tipo,
    String? subtipo,
    required String contaPadrao
  }) {
    if (tipo == null || subtipo == null) {
      return contaPadrao;
    }

    final mapeamento = getMapeamentoContasAtividade();
    return mapeamento[tipo]?[subtipo]?[template] ?? contaPadrao;
  }

  /// Verifica se uma conta pertence a uma atividade específica
  static bool isContaAtividade({
    required String conta,
    required String tipo,
    required String subtipo
  }) {
    final contas = getMapeamentoContasAtividade()[tipo]?[subtipo];
    if (contas == null) return false;

    return contas.values.contains(conta);
  }

  /// Obtém todas as contas relacionadas a uma atividade
  static List<String> getContasRelacionadas({
    required String tipo,
    required String subtipo
  }) {
    final contas = getMapeamentoContasAtividade()[tipo]?[subtipo];
    if (contas == null) return [];

    return contas.values.toList();
  }

  /// Obtém a atividade relacionada a uma conta específica
  static Map<String, String>? getAtividadeConta(String conta) {
    final mapeamento = getMapeamentoContasAtividade();

    for (var tipo in mapeamento.keys) {
      for (var subtipo in mapeamento[tipo]!.keys) {
        if (mapeamento[tipo]![subtipo]!.values.contains(conta)) {
          return {'tipo': tipo, 'subtipo': subtipo};
        }
      }
    }

    return null;
  }

  /// Verifica se é necessário especificar uma atividade para uma conta
  static bool requerAtividade(String conta) {
    return [
      ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
      ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS,
      ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
      ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS,
      ContasBaseConfig.CULTURAS_FORMACAO,
    ].contains(conta);
  }
}