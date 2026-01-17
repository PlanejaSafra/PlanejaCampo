// lib/config/contabil/plano_contas_config.dart

import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/utils/finances/contas_nomes_config.dart';

/// Define a estrutura padrão do plano de contas
/// Contém a definição das contas, suas naturezas e relacionamentos hierárquicos
class PlanoContasConfig {
  /// Retorna o plano de contas padrão completo no idioma especificado
  static List<Map<String, dynamic>> getPlanoContasPadrao(String languageCode) {
    final nomes = ContasNomesConfig.getNomesContas(languageCode);

    return [
      // GRUPO 1 - ATIVOS
      {
        'codigo': ContasBaseConfig.ATIVO,
        'nome': nomes['ativo'],
        'tipo': 'sintetica',
        'natureza': 'devedora'
      },
      {
        'codigo': ContasBaseConfig.ATIVO_CIRCULANTE,
        'nome': nomes['ativoCirculante'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO
      },
      {
        'codigo': ContasBaseConfig.DISPONIVEL,
        'nome': nomes['disponivel'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.CAIXA,
        'nome': nomes['caixa'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DISPONIVEL
      },
      {
        'codigo': ContasBaseConfig.BANCOS,
        'nome': nomes['bancos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DISPONIVEL
      },
      {
        'codigo': ContasBaseConfig.APLICACOES,
        'nome': nomes['aplicacoes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DISPONIVEL
      },

      // DIREITOS REALIZÁVEIS
      {
        'codigo': ContasBaseConfig.DIREITOS_REALIZAVEIS,
        'nome': nomes['direitosRealizaveis'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.CLIENTES,
        'nome': nomes['clientes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DIREITOS_REALIZAVEIS
      },
      {
        'codigo': ContasBaseConfig.ADIANTAMENTOS,
        'nome': nomes['adiantamentos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DIREITOS_REALIZAVEIS
      },
      {
        'codigo': ContasBaseConfig.IMPOSTOS_RECUPERAR,
        'nome': nomes['impostosRecuperar'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DIREITOS_REALIZAVEIS
      },

      // ESTOQUES
      {
        'codigo': ContasBaseConfig.ESTOQUES,
        'nome': nomes['estoques'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_INSUMOS,
        'nome': nomes['estoqueInsumos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_SEMENTES,
        'nome': nomes['estoqueSementes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_DEFENSIVOS,
        'nome': nomes['estoqueDefensivos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_FERTILIZANTES,
        'nome': nomes['estoqueFertilizantes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_EMBALAGENS,
        'nome': nomes['estoqueEmbalagens'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },
      {
        'codigo': ContasBaseConfig.ESTOQUE_PRODUCAO,
        'nome': nomes['estoqueProducao'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ESTOQUES
      },

      // ATIVO NÃO CIRCULANTE
      {
        'codigo': ContasBaseConfig.ATIVO_NAO_CIRCULANTE,
        'nome': nomes['ativoNaoCirculante'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO
      },
      {
        'codigo': ContasBaseConfig.REALIZAVEL_LONGO_PRAZO,
        'nome': nomes['realizavelLongoPrazo'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.INVESTIMENTOS,
        'nome': nomes['investimentos'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.IMOBILIZADO,
        'nome': nomes['imobilizado'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.MAQUINAS_EQUIPAMENTOS,
        'nome': nomes['maquinasEquipamentos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.IMOBILIZADO
      },
      {
        'codigo': ContasBaseConfig.VEICULOS,
        'nome': nomes['veiculos'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.IMOBILIZADO
      },
      {
        'codigo': ContasBaseConfig.INSTALACOES,
        'nome': nomes['instalacoes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.IMOBILIZADO
      },
      {
        'codigo': ContasBaseConfig.TERRAS,
        'nome': nomes['terras'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.IMOBILIZADO
      },
      {
        'codigo': ContasBaseConfig.CULTURAS_PERMANENTES,
        'nome': nomes['culturasPermanentes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.IMOBILIZADO
      },
      {
        'codigo': ContasBaseConfig.ATIVOS_BIOLOGICOS,
        'nome': nomes['ativosBiologicos'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.GADO,
        'nome': nomes['gado'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVOS_BIOLOGICOS
      },
      {
        'codigo': ContasBaseConfig.FLORESTAS,
        'nome': nomes['florestas'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVOS_BIOLOGICOS
      },
      {
        'codigo': ContasBaseConfig.LICENCAS_AMBIENTAIS,
        'nome': nomes['licencasAmbientais'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.DIREITOS_EXPLORACAO_AGRICOLA,
        'nome': nomes['direitosExploracaoAgricola'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.ATIVO_NAO_CIRCULANTE
      },

      // GRUPO 2 - PASSIVOS
      {
        'codigo': ContasBaseConfig.PASSIVO,
        'nome': nomes['passivo'],
        'tipo': 'sintetica',
        'natureza': 'credora'
      },
      {
        'codigo': ContasBaseConfig.PASSIVO_CIRCULANTE,
        'nome': nomes['passivoCirculante'],
        'tipo': 'sintetica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO
      },
      {
        'codigo': ContasBaseConfig.FORNECEDORES,
        'nome': nomes['fornecedores'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS,
        'nome': nomes['emprestimosFinanciamentos'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.OBRIGACOES_TRABALHISTAS,
        'nome': nomes['obrigacoesTrabalhistas'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.OBRIGACOES_TRIBUTARIAS,
        'nome': nomes['obrigacoesTributarias'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.ADIANTAMENTOS_CLIENTES,
        'nome': nomes['adiantamentosClientes'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.PASSIVO_NAO_CIRCULANTE,
        'nome': nomes['passivoNaoCirculante'],
        'tipo': 'sintetica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO
      },
      {
        'codigo': ContasBaseConfig.EMPRESTIMOS_LP,
        'nome': nomes['emprestimosLP'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.FINANCIAMENTOS_LP,
        'nome': nomes['financiamentosLP'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.FINANCIAMENTOS_RURAIS,
        'nome': nomes['financiamentosRurais'],
        'tipo': 'sintetica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.PASSIVO_NAO_CIRCULANTE
      },
      {
        'codigo': ContasBaseConfig.PRONAF,
        'nome': nomes['pronaf'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.FINANCIAMENTOS_RURAIS
      },
      {
        'codigo': ContasBaseConfig.DIVIDAS_ARMAZENS,
        'nome': nomes['dividasArmazens'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.FINANCIAMENTOS_RURAIS
      },

      // GRUPO 3 - RECEITAS
      {
        'codigo': ContasBaseConfig.RECEITAS,
        'nome': nomes['receitas'],
        'tipo': 'sintetica',
        'natureza': 'credora'
      },
      {
        'codigo': ContasBaseConfig.RECEITAS_OPERACIONAIS,
        'nome': nomes['receitasOperacionais'],
        'tipo': 'sintetica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS
      },
      {
        'codigo': ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS,
        'nome': nomes['receitasProdutosAgricolas'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS_OPERACIONAIS
      },
      {
        'codigo': ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS,
        'nome': nomes['receitasProdutosPecuarios'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS_OPERACIONAIS
      },
      {
        'codigo': ContasBaseConfig.SUBSIDIOS_GOVERNAMENTAIS,
        'nome': nomes['subsidiosGovernamentais'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS_OPERACIONAIS
      },
      {
        'codigo': ContasBaseConfig.PRESTACAO_SERVICOS,
        'nome': nomes['prestacaoServicos'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS_OPERACIONAIS
      },
      {
        'codigo': ContasBaseConfig.OUTRAS_RECEITAS,
        'nome': nomes['outrasReceitas'],
        'tipo': 'sintetica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.RECEITAS
      },
      {
        'codigo': ContasBaseConfig.RECEITAS_FINANCEIRAS,
        'nome': nomes['receitasFinanceiras'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.OUTRAS_RECEITAS
      },
      {
        'codigo': ContasBaseConfig.RECEITAS_EVENTUAIS,
        'nome': nomes['receitasEventuais'],
        'tipo': 'analitica',
        'natureza': 'credora',
        'contaPaiId': ContasBaseConfig.OUTRAS_RECEITAS
      },

      // GRUPO 4 - CUSTOS E DESPESAS
      {
        'codigo': ContasBaseConfig.CUSTOS,
        'nome': nomes['custos'],
        'tipo': 'sintetica',
        'natureza': 'devedora'
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_PRODUCAO,
        'nome': nomes['custosProducao'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS,
        'nome': nomes['custosAtividadesAgricolas'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_PRODUCAO
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS,
        'nome': nomes['custosAtividadesPecuarias'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_PRODUCAO
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_ARMAZENAMENTO,
        'nome': nomes['custosArmazenamento'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_PRODUCAO
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_TRANSPORTE,
        'nome': nomes['custosTransporte'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_PRODUCAO
      },
      {
        'codigo': ContasBaseConfig.CUSTOS_INDIRETOS,
        'nome': nomes['custosIndiretos'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS
      },
      {
        'codigo': ContasBaseConfig.MANUTENCAO,
        'nome': nomes['manutencao'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_INDIRETOS
      },
      {
        'codigo': ContasBaseConfig.MAO_OBRA_INDIRETA,
        'nome': nomes['maoObraIndireta'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_INDIRETOS
      },
      {
        'codigo': ContasBaseConfig.ENERGIA_COMBUSTIVEIS,
        'nome': nomes['energiaCombustiveis'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_INDIRETOS
      },
      {
        'codigo': ContasBaseConfig.FRETES,
        'nome': nomes['fretes'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS_INDIRETOS
      },
      {
        'codigo': ContasBaseConfig.DESPESAS,
        'nome': nomes['despesas'],
        'tipo': 'sintetica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CUSTOS
      },
      {
        'codigo': ContasBaseConfig.DESPESAS_ADMINISTRATIVAS,
        'nome': nomes['despesasAdministrativas'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DESPESAS
      },
      {
        'codigo': ContasBaseConfig.DESPESAS_COMERCIAIS,
        'nome': nomes['despesasComerciais'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DESPESAS
      },
      {
        'codigo': ContasBaseConfig.DESPESAS_FINANCEIRAS,
        'nome': nomes['despesasFinanceiras'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DESPESAS
      },
      {
        'codigo': ContasBaseConfig.DESPESAS_TRIBUTARIAS,
        'nome': nomes['despesasTributarias'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.DESPESAS
      },

      // GRUPO 5 - CONTAS DE APURAÇÃO
      {
        'codigo': ContasBaseConfig.CONTAS_APURACAO,
        'nome': nomes['contasApuracao'],
        'tipo': 'sintetica',
        'natureza': 'devedora'
      },
      {
        'codigo': ContasBaseConfig.APURACAO_RESULTADO,
        'nome': nomes['apuracaoResultado'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CONTAS_APURACAO
      },
      {
        'codigo': ContasBaseConfig.CULTURAS_FORMACAO,
        'nome': nomes['culturasFormacao'],
        'tipo': 'analitica',
        'natureza': 'devedora',
        'contaPaiId': ContasBaseConfig.CONTAS_APURACAO
      }
    ];
  }


  /// Retorna uma lista com as contas analíticas de um determinado grupo
  static List<Map<String, dynamic>> getContasAnaliticasGrupo(String grupo, String languageCode) {
    final planoCompleto = getPlanoContasPadrao(languageCode);
    return planoCompleto.where((conta) =>
    conta['tipo'] == 'analitica' &&
        conta['codigo'].toString().startsWith(grupo)
    ).toList();
  }

  /// Retorna uma lista com as contas sintéticas de um determinado grupo
  static List<Map<String, dynamic>> getContasSinteticasGrupo(String grupo, String languageCode) {
    final planoCompleto = getPlanoContasPadrao(languageCode);
    return planoCompleto.where((conta) =>
    conta['tipo'] == 'sintetica' &&
        conta['codigo'].toString().startsWith(grupo)
    ).toList();
  }

  /// Retorna todas as contas filhas de uma determinada conta pai
  static List<Map<String, dynamic>> getContasFilhas(String contaPaiId, String languageCode) {
    final planoCompleto = getPlanoContasPadrao(languageCode);
    return planoCompleto.where((conta) =>
    conta['contaPaiId'] == contaPaiId
    ).toList();
  }

  /// Retorna o caminho completo de uma conta até a raiz
  static List<Map<String, dynamic>> getCaminhoContaRaiz(String codigoConta, String languageCode) {
    final planoCompleto = getPlanoContasPadrao(languageCode);
    List<Map<String, dynamic>> caminho = [];

    var contaAtual = planoCompleto.firstWhere(
          (conta) => conta['codigo'] == codigoConta,
      orElse: () => {},
    );

    while (contaAtual.isNotEmpty) {
      caminho.add(contaAtual);
      String? contaPaiId = contaAtual['contaPaiId'];
      if (contaPaiId == null) break;

      contaAtual = planoCompleto.firstWhere(
            (conta) => conta['codigo'] == contaPaiId,
        orElse: () => {},
      );
    }

    return caminho.reversed.toList();
  }
}