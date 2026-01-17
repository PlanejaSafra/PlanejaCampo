// lib/utils/finances/contas_agrupamento_config.dart

import 'package:planejacampo/utils/finances/contas_base_config.dart';

/// Configuração dos agrupamentos de contas contábeis para relatórios e análises
class ContasAgrupamentoConfig {

  /// Retorna as contas relacionadas ao tipo de atividade rural
  static List<String> getContasPorTipoAtividade(String tipo) {
    switch(tipo.toUpperCase()) {
      case 'AGRICULTURA':
        return [
          ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
          ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
          ContasBaseConfig.ESTOQUE_PRODUCAO,
          ContasBaseConfig.CULTURAS_FORMACAO
        ];

      case 'PECUARIA':
        return [
          ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS,
          ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS,
          ContasBaseConfig.GADO,
          ContasBaseConfig.ESTOQUE_PRODUCAO
        ];

      case 'SILVICULTURA':
        return [
          ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
          ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
          ContasBaseConfig.FLORESTAS
        ];

      default:
        return [];
    }
  }

  /// Retorna contas de estoque por categoria
  static List<String> getContasEstoque(String categoria) {
    switch(categoria.toUpperCase()) {
      case 'INSUMOS':
        return [ContasBaseConfig.ESTOQUE_INSUMOS];

      case 'SEMENTES':
        return [ContasBaseConfig.ESTOQUE_SEMENTES];

      case 'DEFENSIVOS':
        return [ContasBaseConfig.ESTOQUE_DEFENSIVOS];

      case 'FERTILIZANTES':
        return [ContasBaseConfig.ESTOQUE_FERTILIZANTES];

      case 'PRODUCAO':
        return [ContasBaseConfig.ESTOQUE_PRODUCAO];

      case 'BIOLOGICO':
        return [
          ContasBaseConfig.GADO,
          ContasBaseConfig.FLORESTAS
        ];

      case 'TODOS':
        return [
          ContasBaseConfig.ESTOQUE_INSUMOS,
          ContasBaseConfig.ESTOQUE_SEMENTES,
          ContasBaseConfig.ESTOQUE_DEFENSIVOS,
          ContasBaseConfig.ESTOQUE_FERTILIZANTES,
          ContasBaseConfig.ESTOQUE_PRODUCAO,
          ContasBaseConfig.GADO,
          ContasBaseConfig.FLORESTAS
        ];

      default:
        return [];
    }
  }

  /// Retorna todas as contas de um grupo principal
  static List<String> getContasGrupo(String grupo) {
    switch(grupo) {
      case '1': // Ativos
        return [
          ContasBaseConfig.ATIVO,
          ContasBaseConfig.ATIVO_CIRCULANTE,
          ContasBaseConfig.DISPONIVEL,
          ContasBaseConfig.DIREITOS_REALIZAVEIS,
          ContasBaseConfig.ESTOQUES,
          ContasBaseConfig.ATIVO_NAO_CIRCULANTE,
          ContasBaseConfig.REALIZAVEL_LONGO_PRAZO,
          ContasBaseConfig.INVESTIMENTOS,
          ContasBaseConfig.IMOBILIZADO,
          ContasBaseConfig.ATIVOS_BIOLOGICOS
        ];

      case '2': // Passivos
        return [
          ContasBaseConfig.PASSIVO,
          ContasBaseConfig.PASSIVO_CIRCULANTE,
          ContasBaseConfig.PASSIVO_NAO_CIRCULANTE,
          ContasBaseConfig.EMPRESTIMOS_LP,
          ContasBaseConfig.FINANCIAMENTOS_LP,
          ContasBaseConfig.FINANCIAMENTOS_RURAIS
        ];

      case '3': // Receitas
        return [
          ContasBaseConfig.RECEITAS,
          ContasBaseConfig.RECEITAS_OPERACIONAIS,
          ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
          ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS,
          ContasBaseConfig.OUTRAS_RECEITAS
        ];

      case '4': // Custos
        return [
          ContasBaseConfig.CUSTOS,
          ContasBaseConfig.CUSTOS_PRODUCAO,
          ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
          ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS,
          ContasBaseConfig.CUSTOS_INDIRETOS,
          ContasBaseConfig.DESPESAS
        ];

      case '5': // Apuração
        return [
          ContasBaseConfig.CONTAS_APURACAO,
          ContasBaseConfig.APURACAO_RESULTADO,
          ContasBaseConfig.CULTURAS_FORMACAO
        ];

      default:
        return [];
    }
  }

  /// Retorna contas específicas para análise financeira
  static List<String> getContasAnaliseFinanceira(String tipo) {
    switch(tipo.toUpperCase()) {
      case 'DISPONIBILIDADES':
        return [
          ContasBaseConfig.CAIXA,
          ContasBaseConfig.BANCOS,
          ContasBaseConfig.APLICACOES
        ];

      case 'OBRIGACOES_CURTO_PRAZO':
        return [
          ContasBaseConfig.FORNECEDORES,
          ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS,
          ContasBaseConfig.OBRIGACOES_TRABALHISTAS,
          ContasBaseConfig.OBRIGACOES_TRIBUTARIAS
        ];

      case 'CICLO_OPERACIONAL':
        return [
          ...getContasEstoque('TODOS'),
          ContasBaseConfig.CLIENTES,
          ContasBaseConfig.FORNECEDORES
        ];

      default:
        return [];
    }
  }

  /// Retorna contas para demonstrativos específicos
  static List<String> getContasDemonstrativo(String tipo) {
    switch(tipo.toUpperCase()) {
      case 'DRE':
        return [
          ...getContasGrupo('3'), // Receitas
          ...getContasGrupo('4'), // Custos e Despesas
          ContasBaseConfig.APURACAO_RESULTADO
        ];

      case 'BALANCO':
        return [
          ...getContasGrupo('1'), // Ativos
          ...getContasGrupo('2')  // Passivos
        ];

      case 'FLUXO_CAIXA':
        return [
          ContasBaseConfig.CAIXA,
          ContasBaseConfig.BANCOS,
          ContasBaseConfig.APLICACOES
        ];

      default:
        return [];
    }
  }

  /// Retorna o código da conta de custos apropriada para uma atividade
  static String getContaCustosAtividade(String tipoAtividade) {
    switch(tipoAtividade.toUpperCase()) {
      case 'AGRICULTURA':
        return ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS;

      case 'PECUARIA':
        return ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS;

      default:
        return ContasBaseConfig.CUSTOS_INDIRETOS; // Conta padrão para outros tipos
    }
  }

  /// Retorna o código da conta de receitas apropriada para uma atividade
  static String getContaReceitasAtividade(String tipoAtividade) {
    switch(tipoAtividade.toUpperCase()) {
      case 'AGRICULTURA':
        return ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS;

      case 'PECUARIA':
        return ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS;

      default:
        return ContasBaseConfig.OUTRAS_RECEITAS; // Conta padrão para outros tipos
    }
  }
}