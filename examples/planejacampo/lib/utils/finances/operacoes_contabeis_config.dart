import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/utils/finances/contas_agrupamento_config.dart';

/// Configuração das operações contábeis disponíveis no sistema
class OperacoesContabeisConfig {

  /// Retorna o mapeamento das operações contábeis baseado no idioma
  static Map<String, Map<String, dynamic>> getMapeamentoOperacoes(String languageCode) {
    return {
      // Compras e Estoque
      'CompraEstoque': {
        'tipo': 'financeiro',
        'geraEstoque': true,
        'templates': {
          'debitos': [
            {'contaTemplate': '{ESTOQUE}', 'historico': 'Compra de Insumos'}
          ],
          'creditos': [] // Não gera crédito
        },
        'contasPadrao': {
          'ESTOQUE': ContasBaseConfig.ESTOQUE_INSUMOS
        }
      },
      'CompraCusto': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'templates': {
          'debitos': [
            {'conta': ContasBaseConfig.CUSTOS_PRODUCAO, 'historico': 'Custo de Produção'}
          ],
          'creditos': [] // Não gera crédito
        }
      },
      'EstornoEstoque': {
        'tipo': 'financeiro',
        'geraEstoque': true,
        'templates': {
          'creditos': [
            {'conta': ContasBaseConfig.ESTOQUE_INSUMOS, 'historico': 'Estorno - Baixa de Estoque'}
          ],
          'debitos': []
        }
      },
      'EstornoCusto': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'templates': {
          'creditos': [
            {'conta': ContasBaseConfig.CUSTOS_PRODUCAO, 'historico': 'Estorno - Baixa de Despesa'}
          ],
          'debitos': []
        }
      },

      'CreditoParcela': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'templates': {
          'debitos': [], // Não gera débito
          'creditos': [
            {'contaTemplate': '{MEIO_PAGAMENTO}', 'historico': 'Pagamento via {DESCRICAO_MEIO}'}
          ]
        }
      },

      'ConsumoInsumos': {
        'tipo': 'estoque',
        'geraEstoque': true,
        'requerAtividade': true,
        'templates': {
          'debitos': [
            {'contaTemplate': '{CUSTOS_ATIVIDADE}', 'historico': 'Consumo de Insumos'}
          ],
          'creditos': [
            {'conta': ContasBaseConfig.ESTOQUE_INSUMOS, 'historico': 'Baixa de Estoque - Insumos'}
          ]
        },
        'contasPadrao': {
          'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_INDIRETOS
        }
      },

      'ServicosContratados': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'requerAtividade': true,
        'templates': {
          'debitos': [
            {'contaTemplate': '{CUSTOS_ATIVIDADE}', 'historico': 'Serviços Contratados'}
          ],
          'creditos': [
            {'conta': ContasBaseConfig.FORNECEDORES, 'historico': 'Fornecedor - Serviços'}
          ]
        },
        'contasPadrao': {
          'CUSTOS_ATIVIDADE': ContasBaseConfig.CUSTOS_INDIRETOS
        }
      },

      'VendaProducao': {
        'tipo': 'financeiro',
        'geraEstoque': true,
        'requerAtividade': true,
        'templates': {
          'debitos': [
            {'conta': ContasBaseConfig.CLIENTES, 'historico': 'Venda de Produção'},
            {'conta': ContasBaseConfig.CUSTOS_PRODUCAO, 'historico': 'Custo da Produção Vendida'}
          ],
          'creditos': [
            {'contaTemplate': '{RECEITAS_ATIVIDADE}', 'historico': 'Receita de Venda'},
            {'conta': ContasBaseConfig.ESTOQUE_PRODUCAO, 'historico': 'Baixa de Estoque - Produção'}
          ]
        },
        'contasPadrao': {
          'RECEITAS_ATIVIDADE': ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS
        }
      },

      'PagamentoFornecedor': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'requerAtividade': false,
        'templates': {
          'debitos': [
            {'conta': ContasBaseConfig.FORNECEDORES, 'historico': 'Pagamento a Fornecedor'}
          ],
          'creditos': [
            {'conta': ContasBaseConfig.BANCOS, 'historico': 'Banco - Pagamento Efetuado'}
          ]
        }
      },

      'RecebimentoCliente': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'requerAtividade': false,
        'templates': {
          'debitos': [
            {'conta': ContasBaseConfig.BANCOS, 'historico': 'Banco - Recebimento de Cliente'}
          ],
          'creditos': [
            {'conta': ContasBaseConfig.CLIENTES, 'historico': 'Recebimento de Cliente'}
          ]
        }
      },
      'EstornoContaPagar': {
        'tipo': 'financeiro',
        'geraEstoque': false,
        'templates': {
          'debitos': [
            {'contaTemplate': '{MEIO_PAGAMENTO}', 'historico': 'Estorno de conta a pagar'}
          ],
          'creditos': []
        },
        'contasPadrao': {   // Adicionar este mapeamento
          'MEIO_PAGAMENTO': ''  // Será preenchido com o ID da conta contábil
        }
      }
    };
  }

  /// Resolve as contas baseadas na atividade rural
  static Map<String, String> resolverContasAtividade(
      String operacao,
      AtividadeRural? atividadeRural,
      Map<String, String> contasPadrao
      ) {
    if (atividadeRural == null) {
      return contasPadrao;
    }

    Map<String, String> contasResolvidas = Map.from(contasPadrao);

    // Resolve conta de custos
    if (contasPadrao.containsKey('CUSTOS_ATIVIDADE')) {
      contasResolvidas['CUSTOS_ATIVIDADE'] =
          ContasAgrupamentoConfig.getContaCustosAtividade(atividadeRural.tipo);
    }

    // Resolve conta de receitas
    if (contasPadrao.containsKey('RECEITAS_ATIVIDADE')) {
      contasResolvidas['RECEITAS_ATIVIDADE'] =
          ContasAgrupamentoConfig.getContaReceitasAtividade(atividadeRural.tipo);
    }

    // Resolve conta de estoque
    if (contasPadrao.containsKey('ESTOQUE')) {
      contasResolvidas['ESTOQUE'] = _resolverContaEstoque(operacao, atividadeRural);
    }

    return contasResolvidas;
  }

  /// Resolve a conta de estoque baseada na operação e atividade
  static String _resolverContaEstoque(String operacao, AtividadeRural atividade) {
    switch (operacao) {
      case 'CompraInsumos':
        return ContasBaseConfig.ESTOQUE_INSUMOS;
      case 'CompraSementes':
        return ContasBaseConfig.ESTOQUE_SEMENTES;
      case 'CompraDefensivos':
        return ContasBaseConfig.ESTOQUE_DEFENSIVOS;
      case 'CompraFertilizantes':
        return ContasBaseConfig.ESTOQUE_FERTILIZANTES;
      case 'EstornoCompra':
        return ContasBaseConfig.ESTOQUE_INSUMOS; // Usa mesmo estoque da compra
      default:
        return ContasBaseConfig.ESTOQUE_INSUMOS;
    }
  }

  /// Gera partidas contábeis para uma operação
  /// Gera partidas contábeis para uma operação
  static List<Map<String, dynamic>> gerarPartidas({
    required String operacao,
    required Map<String, dynamic> configuracao,
    required AtividadeRural? atividadeRural,
    required double valor,
    String? complemento,
  }) {
    List<Map<String, dynamic>> partidas = [];

    // Converte o configuracao['contasPadrao'] para Map<String, String>
    Map<String, String> contasPadrao = {};
    (configuracao['contasPadrao'] ?? {}).forEach((key, value) {
      contasPadrao[key.toString()] = value.toString();
    });

    // Resolve as contas baseadas na atividade
    Map<String, String> contasResolvidas = resolverContasAtividade(
      operacao,
      atividadeRural,
      contasPadrao,
    );

    // Processa débitos
    // Processa débitos
    for (var debito in configuracao['templates']['debitos']) {
      String conta;
      if (debito['contaTemplate'] != null) {
        String chave = debito['contaTemplate']
            .substring(1, debito['contaTemplate'].length - 1);
        if (contasResolvidas[chave] == null) {
          throw Exception("Conta não encontrada para o template '$chave' nos débitos");
        }
        conta = contasResolvidas[chave]!;
      } else {
        conta = debito['conta'];
      }

      // ADICIONAR: Substituir placeholders no histórico
      String historico = debito['historico'];
      contasResolvidas.forEach((key, value) {
        historico = historico.replaceAll('{$key}', value);
      });

      partidas.add({
        'contaContabilId': conta,
        'tipo': 'Debito',
        'valor': valor,
        'historico': '$historico${complemento != null ? ' - $complemento' : ''}'
      });
    }

// Processa créditos
    for (var credito in configuracao['templates']['creditos']) {
      String conta;
      if (credito['contaTemplate'] != null) {
        String chave = credito['contaTemplate']
            .substring(1, credito['contaTemplate'].length - 1);
        if (contasResolvidas[chave] == null) {
          throw Exception("Conta não encontrada para o template '$chave' nos créditos");
        }
        conta = contasResolvidas[chave]!;
      } else {
        conta = credito['conta'];
      }

      // ADICIONAR: Substituir placeholders no histórico
      String historico = credito['historico'];
      contasResolvidas.forEach((key, value) {
        historico = historico.replaceAll('{$key}', value);
      });

      partidas.add({
        'contaContabilId': conta,
        'tipo': 'Credito',
        'valor': valor,
        'historico': '$historico${complemento != null ? ' - $complemento' : ''}'
      });
    }

    return partidas;
  }


}