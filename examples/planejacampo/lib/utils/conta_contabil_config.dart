/*
import 'package:flutter/material.dart';

class ContaContabilConfig {
  // GRUPO 1 - ATIVOS
  static const String ATIVO = "1";
  static const String ATIVO_CIRCULANTE = "1.1";
  static const String DISPONIVEL = "1.1.1";
  static const String CAIXA = "1.1.1.01";
  static const String BANCOS = "1.1.1.02";
  static const String APLICACOES = "1.1.1.03";
  static const String DIREITOS_REALIZAVEIS = "1.1.2";
  static const String CLIENTES = "1.1.2.01";
  static const String ADIANTAMENTOS = "1.1.2.02";
  static const String IMPOSTOS_RECUPERAR = "1.1.2.03";
  static const String ESTOQUES = "1.1.3";
  static const String ESTOQUE_INSUMOS = "1.1.3.01";
  static const String ESTOQUE_SEMENTES = "1.1.3.02";
  static const String ESTOQUE_DEFENSIVOS = "1.1.3.03";
  static const String ESTOQUE_FERTILIZANTES = "1.1.3.04";
  static const String ESTOQUE_EMBALAGENS = "1.1.3.05";
  static const String ESTOQUE_PRODUCAO = "1.1.3.06";
  static const String ATIVO_NAO_CIRCULANTE = "1.2";
  static const String REALIZAVEL_LONGO_PRAZO = "1.2.1";
  static const String INVESTIMENTOS = "1.2.2";
  static const String IMOBILIZADO = "1.2.3";
  static const String MAQUINAS_EQUIPAMENTOS = "1.2.3.01";
  static const String VEICULOS = "1.2.3.02";
  static const String INSTALACOES = "1.2.3.03";
  static const String TERRAS = "1.2.3.04";
  static const String CULTURAS_PERMANENTES = "1.2.3.05";
  static const String ATIVOS_BIOLOGICOS = "1.2.4";
  static const String GADO = "1.2.4.01";
  static const String FLORESTAS = "1.2.4.02";
  static const String LICENCAS_AMBIENTAIS = "1.2.5";
  static const String DIREITOS_EXPLORACAO_AGRICOLA = "1.2.6";


  // GRUPO 2 - PASSIVOS
  static const String PASSIVO = "2";
  static const String PASSIVO_CIRCULANTE = "2.1";
  static const String FORNECEDORES = "2.1.1";
  static const String EMPRESTIMOS_FINANCIAMENTOS = "2.1.2";
  static const String OBRIGACOES_TRABALHISTAS = "2.1.3";
  static const String OBRIGACOES_TRIBUTARIAS = "2.1.4";
  static const String ADIANTAMENTOS_CLIENTES = "2.1.5";
  static const String PASSIVO_NAO_CIRCULANTE = "2.2";
  static const String EMPRESTIMOS_LP = "2.2.1";
  static const String FINANCIAMENTOS_LP = "2.2.2";
  static const String FINANCIAMENTOS_RURAIS = "2.2.3";
  static const String PRONAF = "2.2.3.01";
  static const String DIVIDAS_ARMAZENS = "2.2.3.02";

  // GRUPO 3 - RECEITAS
  static const String RECEITAS = "3";
  static const String RECEITAS_OPERACIONAIS = "3.1";
  static const String VENDA_PRODUCAO = "3.1.1";
  static const String VENDA_SOJA = "3.1.1.01";
  static const String VENDA_MILHO = "3.1.1.02";
  static const String VENDA_ALGODAO = "3.1.1.03";
  static const String VENDA_TRIGO = "3.1.1.04";
  static const String VENDA_CANA = "3.1.1.05";
  static const String SUBSIDIOS_GOVERNAMENTAIS = "3.1.3"; // Added missing constant
  static const String PRESTACAO_SERVICOS = "3.1.4";
  static const String OUTRAS_RECEITAS = "3.2";
  static const String RECEITAS_FINANCEIRAS = "3.2.1";
  static const String RECEITAS_EVENTUAIS = "3.2.2";

  // GRUPO 4 - CUSTOS E DESPESAS
  static const String CUSTOS = "4";
  static const String CUSTOS_PRODUCAO = "4.1";
  static const String CUSTOS_SOJA = "4.1.1";
  static const String CUSTOS_MILHO = "4.1.2";
  static const String CUSTOS_ALGODAO = "4.1.3";
  static const String CUSTOS_TRIGO = "4.1.4"; // Added missing constant
  static const String CUSTOS_ARMAZENAMENTO = "4.1.5"; // Added missing constant
  static const String CUSTOS_TRANSPORTE = "4.1.6"; // Added missing constant

  static const String CUSTOS_INDIRETOS = "4.2";
  static const String MANUTENCAO = "4.2.1";
  static const String MAO_OBRA_INDIRETA = "4.2.2";
  static const String ENERGIA_COMBUSTIVEIS = "4.2.3";
  static const String FRETES = "4.2.4";

  static const String DESPESAS = "4.3";
  static const String DESPESAS_ADMINISTRATIVAS = "4.3.1";
  static const String DESPESAS_COMERCIAIS = "4.3.2";
  static const String DESPESAS_FINANCEIRAS = "4.3.3";
  static const String DESPESAS_TRIBUTARIAS = "4.3.4";


  // GRUPO 5 - CONTAS DE APURAÇÃO
  static const String CONTAS_APURACAO = "5";
  static const String APURACAO_RESULTADO = "5.1";
  static const String CULTURAS_FORMACAO = "5.2";


  // MAPEAMENTOS DE OPERAÇÕES
  static Map<String, Map<String, dynamic>> getMapeamentoOperacoes(String languageCode) {
    print("Entrou em contaContabilConfig.getMapeamentoOperacoes - languageCode: $languageCode");
    switch (languageCode) {
      case 'pt':
        return {
          // Compras
          'CompraInsumos': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_INSUMOS, 'historico': 'Compra de Insumos'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Fornecedor - Compra de Insumos'}
            ]
          },
          'CompraSementes': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_SEMENTES, 'historico': 'Compra de Sementes'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Fornecedor - Compra de Sementes'}
            ]
          },
          'CompraDefensivos': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_DEFENSIVOS, 'historico': 'Compra de Defensivos'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Fornecedor - Compra de Defensivos'}
            ]
          },
          'CompraFertilizantes': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_FERTILIZANTES, 'historico': 'Compra de Fertilizantes'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Fornecedor - Compra de Fertilizantes'}
            ]
          },
          'Financiamento': {
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': BANCOS, 'historico': 'Entrada de Recursos'}
            ],
            'creditos': [
              {'conta': FINANCIAMENTOS_RURAIS, 'historico': 'Captação de Financiamento'}
            ]
          },
          'DividasArmazens': {
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': BANCOS, 'historico': 'Captação de Recursos para Armazéns'}
            ],
            'creditos': [
              {'conta': DIVIDAS_ARMAZENS, 'historico': 'Contratação de dívida para armazéns'}
            ]
          },
          'SubsidiosGovernamentais': {
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': CAIXA, 'historico': 'Entrada de Subsídio no Caixa'}
            ],
            'creditos': [
              {'conta': SUBSIDIOS_GOVERNAMENTAIS, 'historico': 'Recebimento de Subsídio Governamental'}
            ]
          },


          // Consumos
          'ConsumoInsumos': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Consumo de Insumos - Soja'}
            ],
            'creditos': [
              {'conta': ESTOQUE_INSUMOS, 'historico': 'Baixa de Estoque - Insumos'}
            ]
          },
          'ConsumoSementes': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Consumo de Sementes - Soja'}
            ],
            'creditos': [
              {'conta': ESTOQUE_SEMENTES, 'historico': 'Baixa de Estoque - Sementes'}
            ]
          },
          'ConsumoDefensivos': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Consumo de Defensivos - Soja'}
            ],
            'creditos': [
              {'conta': ESTOQUE_DEFENSIVOS, 'historico': 'Baixa de Estoque - Defensivos'}
            ]
          },
          'ConsumoFertilizantes': { // Added missing operation
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Consumo de Fertilizantes - Soja'}
            ],
            'creditos': [
              {'conta': ESTOQUE_FERTILIZANTES, 'historico': 'Baixa de Estoque - Fertilizantes'}
            ]
          },

          // Serviços
          'ServicosContratados': {
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Serviços Contratados - Soja'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Fornecedor - Serviços'}
            ]
          },

          // Produção
          'ProducaoAgricola': { // Added missing operation.  It was present in english but not in portuguese
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_PRODUCAO, 'historico': 'Produção Agrícola'}
            ],
            'creditos': [
              {'conta': CUSTOS_PRODUCAO, 'historico': 'Apuração do Custo de Produção'}
            ]
          },

          // Venda Produção
          'VendaProducao': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': CLIENTES, 'historico': 'Venda de Soja'},
              {'conta': CUSTOS_PRODUCAO, 'historico': 'Custo da Produção Vendida'}
            ],
            'creditos': [
              {'conta': VENDA_SOJA, 'historico': 'Receita - Venda de Soja'},
              {'conta': ESTOQUE_PRODUCAO, 'historico': 'Baixa de Estoque - Produção'}
            ]
          }
        };


      default: // inglês
        return {
          // Purchases
          'InputPurchase': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_INSUMOS, 'historico': 'Input Purchase'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Supplier - Input Purchase'}
            ]
          },
          'SeedPurchase': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_SEMENTES, 'historico': 'Seed Purchase'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Supplier - Seed Purchase'}
            ]
          },
          'PesticidePurchase': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_DEFENSIVOS, 'historico': 'Pesticide Purchase'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Supplier - Pesticide Purchase'}
            ]
          },
          'FertilizerPurchase': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_FERTILIZANTES, 'historico': 'Fertilizer Purchase'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Supplier - Fertilizer Purchase'}
            ]
          },
          'PronafFinancing': { // Added missing operation
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': BANCOS, 'historico': 'Resources Entry'}
            ],
            'creditos': [
              {'conta': FINANCIAMENTOS_RURAIS, 'historico': 'Financing Acquisition'}
            ]
          },
          'WarehouseDebts': { // Added missing operation
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': BANCOS, 'historico': 'Warehouse Resources Acquisition'}
            ],
            'creditos': [
              {'conta': DIVIDAS_ARMAZENS, 'historico': 'Warehouse Debt Incurred'}
            ]
          },
          'GovernmentSubsidies': { // Added missing operation
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': CAIXA, 'historico': 'Subsidy Entry in Cash'}
            ],
            'creditos': [
              {'conta': SUBSIDIOS_GOVERNAMENTAIS, 'historico': 'Government Subsidy Received'}
            ]
          },

          // Consumption
          'InputConsumption': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Input Consumption - Soybean'}
            ],
            'creditos': [
              {'conta': ESTOQUE_INSUMOS, 'historico': 'Inventory Output - Inputs'}
            ]
          },
          'SeedConsumption': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Seed Consumption - Soybean'}
            ],
            'creditos': [
              {'conta': ESTOQUE_SEMENTES, 'historico': 'Inventory Output - Seeds'}
            ]
          },
          'PesticideConsumption': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Pesticide Consumption - Soybean'}
            ],
            'creditos': [
              {'conta': ESTOQUE_DEFENSIVOS, 'historico': 'Inventory Output - Pesticides'}
            ]
          },
          'FertilizerConsumption': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Fertilizer Consumption - Soybean'}
            ],
            'creditos': [
              {'conta': ESTOQUE_FERTILIZANTES, 'historico': 'Inventory Output - Fertilizers'}
            ]
          },

          // Services
          'ContractedServices': {
            'tipo': 'financeiro',
            'geraEstoque': false,
            'debitos': [
              {'conta': CUSTOS_SOJA, 'historico': 'Contracted Services - Soybean'}
            ],
            'creditos': [
              {'conta': FORNECEDORES, 'historico': 'Supplier - Services'}
            ]
          },

          // Production
          'AgriculturalProduction': {
            'tipo': 'estoque',
            'geraEstoque': true,
            'debitos': [
              {'conta': ESTOQUE_PRODUCAO, 'historico': 'Agricultural Production'}
            ],
            'creditos': [
              {'conta': CUSTOS_PRODUCAO, 'historico': 'Production Cost Settlement'}
            ]
          },

          // Sales
          'ProductionSale': {
            'tipo': 'financeiro',
            'geraEstoque': true,
            'debitos': [
              {'conta': CLIENTES, 'historico': 'Soybean Sale'},
              {'conta': CUSTOS_PRODUCAO, 'historico': 'Cost of Production Sold'}
            ],
            'creditos': [
              {'conta': VENDA_SOJA, 'historico': 'Revenue - Soybean Sale'},
              {'conta': ESTOQUE_PRODUCAO, 'historico': 'Inventory Output - Production'}
            ]
          }
        };
    }
  }


  // PLANO DE CONTAS PADRÃO
  static List<Map<String, dynamic>> getPlanoContasPadrao(String languageCode) {
    final nomes = _getNomesContas(languageCode);
    return [
      // Ativos
      {'codigo': ATIVO, 'nome': nomes['ativo'], 'tipo': 'sintetica', 'natureza': 'devedora'},
      {'codigo': ATIVO_CIRCULANTE, 'nome': nomes['ativoCirculante'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO},
      {'codigo': DISPONIVEL, 'nome': nomes['disponivel'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_CIRCULANTE},
      {'codigo': CAIXA, 'nome': nomes['caixa'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DISPONIVEL},
      {'codigo': BANCOS, 'nome': nomes['bancos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DISPONIVEL},
      {'codigo': APLICACOES, 'nome': nomes['aplicacoes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DISPONIVEL},
      {'codigo': DIREITOS_REALIZAVEIS, 'nome': nomes['direitosRealizaveis'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_CIRCULANTE},
      {'codigo': CLIENTES, 'nome': nomes['clientes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DIREITOS_REALIZAVEIS},
      {'codigo': ADIANTAMENTOS, 'nome': nomes['adiantamentos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DIREITOS_REALIZAVEIS},
      {'codigo': IMPOSTOS_RECUPERAR, 'nome': nomes['impostosRecuperar'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DIREITOS_REALIZAVEIS},
      {'codigo': ESTOQUES, 'nome': nomes['estoques'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_CIRCULANTE},
      {'codigo': ESTOQUE_INSUMOS, 'nome': nomes['estoqueInsumos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ESTOQUE_SEMENTES, 'nome': nomes['estoqueSementes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ESTOQUE_DEFENSIVOS, 'nome': nomes['estoqueDefensivos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ESTOQUE_FERTILIZANTES, 'nome': nomes['estoqueFertilizantes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ESTOQUE_EMBALAGENS, 'nome': nomes['estoqueEmbalagens'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ESTOQUE_PRODUCAO, 'nome': nomes['estoqueProducao'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ESTOQUES},
      {'codigo': ATIVO_NAO_CIRCULANTE, 'nome': nomes['ativoNaoCirculante'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO},

      {'codigo': REALIZAVEL_LONGO_PRAZO, 'nome': nomes['realizavelLongoPrazo'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},

      {'codigo': INVESTIMENTOS, 'nome': nomes['investimentos'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},

      {'codigo': IMOBILIZADO, 'nome': nomes['imobilizado'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},
      {'codigo': MAQUINAS_EQUIPAMENTOS, 'nome': nomes['maquinasEquipamentos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': IMOBILIZADO},
      {'codigo': VEICULOS, 'nome': nomes['veiculos'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': IMOBILIZADO},
      {'codigo': INSTALACOES, 'nome': nomes['instalacoes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': IMOBILIZADO},
      {'codigo': TERRAS, 'nome': nomes['terras'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': IMOBILIZADO},
      {'codigo': CULTURAS_PERMANENTES, 'nome': nomes['culturasPermanentes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': IMOBILIZADO},

      {'codigo': ATIVOS_BIOLOGICOS, 'nome': nomes['ativosBiologicos'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},
      {'codigo': GADO, 'nome': nomes['gado'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ATIVOS_BIOLOGICOS},
      {'codigo': FLORESTAS, 'nome': nomes['florestas'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ATIVOS_BIOLOGICOS},

      {'codigo': LICENCAS_AMBIENTAIS, 'nome': nomes['licencasAmbientais'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},
      {'codigo': DIREITOS_EXPLORACAO_AGRICOLA, 'nome': nomes['direitosExploracaoAgricola'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': ATIVO_NAO_CIRCULANTE},


      // Passivos
      {'codigo': PASSIVO, 'nome': nomes['passivo'], 'tipo': 'sintetica', 'natureza': 'credora'},
      {'codigo': PASSIVO_CIRCULANTE, 'nome': nomes['passivoCirculante'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': PASSIVO},
      {'codigo': FORNECEDORES, 'nome': nomes['fornecedores'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_CIRCULANTE},
      {'codigo': EMPRESTIMOS_FINANCIAMENTOS, 'nome': nomes['emprestimosFinanciamentos'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_CIRCULANTE},
      {'codigo': OBRIGACOES_TRABALHISTAS, 'nome': nomes['obrigacoesTrabalhistas'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_CIRCULANTE},
      {'codigo': OBRIGACOES_TRIBUTARIAS, 'nome': nomes['obrigacoesTributarias'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_CIRCULANTE},
      {'codigo': ADIANTAMENTOS_CLIENTES, 'nome': nomes['adiantamentosClientes'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_CIRCULANTE},

      {'codigo': PASSIVO_NAO_CIRCULANTE, 'nome': nomes['passivoNaoCirculante'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': PASSIVO},
      {'codigo': EMPRESTIMOS_LP, 'nome': nomes['emprestimosLp'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_NAO_CIRCULANTE},
      {'codigo': FINANCIAMENTOS_LP, 'nome': nomes['financiamentosLp'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': PASSIVO_NAO_CIRCULANTE},
      {'codigo': FINANCIAMENTOS_RURAIS, 'nome': nomes['financiamentosRurais'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': PASSIVO_NAO_CIRCULANTE}, // Added missing account
      {'codigo': PRONAF, 'nome': nomes['pronaf'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': FINANCIAMENTOS_RURAIS},
      {'codigo': DIVIDAS_ARMAZENS, 'nome': nomes['dividasArmazens'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': FINANCIAMENTOS_RURAIS},


      // Receitas
      {'codigo': RECEITAS, 'nome': nomes['receitas'], 'tipo': 'sintetica', 'natureza': 'credora'},
      {'codigo': RECEITAS_OPERACIONAIS, 'nome': nomes['receitasOperacionais'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': RECEITAS},
      {'codigo': VENDA_PRODUCAO, 'nome': nomes['vendaProducao'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': RECEITAS_OPERACIONAIS},
      {'codigo': VENDA_SOJA, 'nome': nomes['vendaSoja'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': VENDA_PRODUCAO},
      {'codigo': VENDA_MILHO, 'nome': nomes['vendaMilho'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': VENDA_PRODUCAO},
      {'codigo': VENDA_ALGODAO, 'nome': nomes['vendaAlgodao'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': VENDA_PRODUCAO},
      {'codigo': VENDA_TRIGO, 'nome': nomes['vendaTrigo'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': VENDA_PRODUCAO}, // Added missing account
      {'codigo': VENDA_CANA, 'nome': nomes['vendaCana'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': VENDA_PRODUCAO}, // Added missing account
      {'codigo': SUBSIDIOS_GOVERNAMENTAIS, 'nome': nomes['subsidiosGovernamentais'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': RECEITAS_OPERACIONAIS}, // Added missing account


      {'codigo': PRESTACAO_SERVICOS, 'nome': nomes['prestacaoServicos'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': RECEITAS_OPERACIONAIS},

      {'codigo': OUTRAS_RECEITAS, 'nome': nomes['outrasReceitas'], 'tipo': 'sintetica', 'natureza': 'credora', 'contaPaiId': RECEITAS},
      {'codigo': RECEITAS_FINANCEIRAS, 'nome': nomes['receitasFinanceiras'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': OUTRAS_RECEITAS},
      {'codigo': RECEITAS_EVENTUAIS, 'nome': nomes['receitasEventuais'], 'tipo': 'analitica', 'natureza': 'credora', 'contaPaiId': OUTRAS_RECEITAS},



      // Custos e Despesas
      {'codigo': CUSTOS, 'nome': nomes['custos'], 'tipo': 'sintetica', 'natureza': 'devedora'},
      {'codigo': CUSTOS_PRODUCAO, 'nome': nomes['custosProducao'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': CUSTOS},
      {'codigo': CUSTOS_SOJA, 'nome': nomes['custosSoja'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO},
      {'codigo': CUSTOS_MILHO, 'nome': nomes['custosMilho'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO},
      {'codigo': CUSTOS_ALGODAO, 'nome': nomes['custosAlgodao'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO},
      {'codigo': CUSTOS_TRIGO, 'nome': nomes['custosTrigo'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO}, // Added missing account
      {'codigo': CUSTOS_ARMAZENAMENTO, 'nome': nomes['custosArmazenamento'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO}, // Added missing account
      {'codigo': CUSTOS_TRANSPORTE, 'nome': nomes['custosTransporte'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_PRODUCAO}, // Added missing account



      {'codigo': CUSTOS_INDIRETOS, 'nome': nomes['custosIndiretos'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': CUSTOS},
      {'codigo': MANUTENCAO, 'nome': nomes['manutencao'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_INDIRETOS},
      {'codigo': MAO_OBRA_INDIRETA, 'nome': nomes['maoObraIndireta'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_INDIRETOS},
      {'codigo': ENERGIA_COMBUSTIVEIS, 'nome': nomes['energiaCombustiveis'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_INDIRETOS},
      {'codigo': FRETES, 'nome': nomes['fretes'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CUSTOS_INDIRETOS},

      {'codigo': DESPESAS, 'nome': nomes['despesas'], 'tipo': 'sintetica', 'natureza': 'devedora', 'contaPaiId': CUSTOS},
      {'codigo': DESPESAS_ADMINISTRATIVAS, 'nome': nomes['despesasAdministrativas'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DESPESAS},
      {'codigo': DESPESAS_COMERCIAIS, 'nome': nomes['despesasComerciais'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DESPESAS},
      {'codigo': DESPESAS_FINANCEIRAS, 'nome': nomes['despesasFinanceiras'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DESPESAS},
      {'codigo': DESPESAS_TRIBUTARIAS, 'nome': nomes['despesasTributarias'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': DESPESAS},

      // Contas de Apuração
      {'codigo': CONTAS_APURACAO, 'nome': nomes['contasApuracao'], 'tipo': 'sintetica', 'natureza': 'devedora'},
      {'codigo': APURACAO_RESULTADO, 'nome': nomes['apuracaoResultado'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CONTAS_APURACAO},
      {'codigo': CULTURAS_FORMACAO, 'nome': nomes['culturasFormacao'], 'tipo': 'analitica', 'natureza': 'devedora', 'contaPaiId': CONTAS_APURACAO}
    ];
  }

  // Traduções
  static Map<String, String> _getNomesContas(String languageCode) {
    switch (languageCode) {
      case 'pt':
        return {
          'ativo': 'Ativo',
          'ativoCirculante': 'Ativo Circulante',
          'disponivel': 'Disponível',
          'caixa': 'Caixa',
          'bancos': 'Bancos',
          'aplicacoes': 'Aplicações Financeiras',
          'direitosRealizaveis': 'Direitos Realizáveis',
          'clientes': 'Clientes',
          'adiantamentos': 'Adiantamentos',
          'impostosRecuperar': 'Impostos a Recuperar',
          'estoques': 'Estoques',
          'estoqueInsumos': 'Estoque de Insumos',
          'estoqueSementes': 'Estoque de Sementes',
          'estoqueDefensivos': 'Estoque de Defensivos',
          'estoqueFertilizantes': 'Estoque de Fertilizantes',
          'estoqueEmbalagens': 'Estoque de Embalagens',
          'estoqueProducao': 'Estoque de Produção',
          'ativoNaoCirculante': 'Ativo Não Circulante',
          'realizavelLongoPrazo': 'Realizável a Longo Prazo',
          'investimentos': 'Investimentos',
          'imobilizado': 'Imobilizado',
          'maquinasEquipamentos': 'Máquinas e Equipamentos',
          'veiculos': 'Veículos',
          'instalacoes': 'Instalações',
          'terras': 'Terras',
          'culturasPermanentes': 'Culturas Permanentes',
          'ativosBiologicos': 'Ativos Biológicos',
          'gado': 'Gado',
          'florestas': 'Florestas',
          'licencasAmbientais': 'Licenças Ambientais',
          'direitosExploracaoAgricola': 'Direitos de Exploração Agrícola',


          'passivo': 'Passivo',
          'passivoCirculante': 'Passivo Circulante',
          'fornecedores': 'Fornecedores',
          'emprestimosFinanciamentos': 'Empréstimos e Financiamentos',
          'obrigacoesTrabalhistas': 'Obrigações Trabalhistas',
          'obrigacoesTributarias': 'Obrigações Tributárias',
          'adiantamentosClientes': 'Adiantamentos de Clientes',
          'passivoNaoCirculante': 'Passivo Não Circulante',
          'emprestimosLp': 'Empréstimos a Longo Prazo',
          'financiamentosLp': 'Financiamentos a Longo Prazo',
          'financiamentosRurais': 'Financiamentos Rurais', // Added missing translation
          'pronaf': 'PRONAF', // Added missing translation
          'dividasArmazens': 'Dívidas com Armazéns',  // Added missing translation


          'receitas': 'Receitas',
          'receitasOperacionais': 'Receitas Operacionais',
          'vendaProducao': 'Venda de Produção',
          'vendaSoja': 'Venda de Soja',
          'vendaMilho': 'Venda de Milho',
          'vendaAlgodao': 'Venda de Algodão',
          'vendaTrigo': 'Venda de Trigo', // Added missing translation
          'vendaCana': 'Venda de Cana', // Added missing translation
          'subsidiosGovernamentais': 'Subsídios Governamentais', // Added missing translation
          'prestacaoServicos': 'Prestação de Serviços',
          'outrasReceitas': 'Outras Receitas',
          'receitasFinanceiras': 'Receitas Financeiras',
          'receitasEventuais': 'Receitas Eventuais',

          'custos': 'Custos',
          'custosProducao': 'Custos de Produção',
          'custosSoja': 'Custos - Soja',
          'custosMilho': 'Custos - Milho',
          'custosAlgodao': 'Custos - Algodão',
          'custosTrigo': 'Custos - Trigo',  // Added missing translation
          'custosArmazenamento': 'Custos de Armazenamento', // Added missing translation
          'custosTransporte': 'Custos de Transporte', // Added missing translation


          'custosIndiretos': 'Custos Indiretos',
          'manutencao': 'Manutenção',
          'maoObraIndireta': 'Mão de Obra Indireta',
          'energiaCombustiveis': 'Energia e Combustíveis',
          'fretes': 'Fretes',

          'despesas': 'Despesas',
          'despesasAdministrativas': 'Despesas Administrativas',
          'despesasComerciais': 'Despesas Comerciais',
          'despesasFinanceiras': 'Despesas Financeiras',
          'despesasTributarias': 'Despesas Tributárias',

          'contasApuracao': 'Contas de Apuração',
          'apuracaoResultado': 'Apuração do Resultado',
          'culturasFormacao': 'Culturas em Formação'
        };

      default: // inglês
        return {
          'ativo': 'Assets',
          'ativoCirculante': 'Current Assets',
          'disponivel': 'Available',
          'caixa': 'Cash',
          'bancos': 'Banks',
          'aplicacoes': 'Financial Investments',
          'direitosRealizaveis': 'Receivables',
          'clientes': 'Customers',
          'adiantamentos': 'Advances',
          'impostosRecuperar': 'Recoverable Taxes',
          'estoques': 'Inventory',
          'estoqueInsumos': 'Input Inventory',
          'estoqueSementes': 'Seed Inventory',
          'estoqueDefensivos': 'Pesticide Inventory',
          'estoqueFertilizantes': 'Fertilizer Inventory',
          'estoqueEmbalagens': 'Packaging Inventory',
          'estoqueProducao': 'Production Inventory',
          'ativoNaoCirculante': 'Non-Current Assets',
          'realizavelLongoPrazo': 'Long-term Receivables',
          'investimentos': 'Investments',
          'imobilizado': 'Fixed Assets',
          'maquinasEquipamentos': 'Machinery and Equipment',
          'veiculos': 'Vehicles',
          'instalacoes': 'Facilities',
          'terras': 'Land',
          'culturasPermanentes': 'Permanent Crops',
          'ativosBiologicos': 'Biological Assets',
          'gado': 'Cattle',
          'florestas': 'Forests',
          'licencasAmbientais': 'Environmental Licenses',
          'direitosExploracaoAgricola': 'Agricultural Exploration Rights',

          'passivo': 'Liabilities',
          'passivoCirculante': 'Current Liabilities',
          'fornecedores': 'Suppliers',
          'emprestimosFinanciamentos': 'Loans and Financing',
          'obrigacoesTrabalhistas': 'Labor Obligations',
          'obrigacoesTributarias': 'Tax Obligations',
          'adiantamentosClientes': 'Customer Advances',
          'passivoNaoCirculante': 'Non-Current Liabilities',
          'emprestimosLp': 'Long-term Loans',
          'financiamentosLp': 'Long-term Financing',
          'financiamentosRurais': 'Rural Financing', // Added missing translation
          'pronaf': 'PRONAF', // Added missing translation
          'dividasArmazens': 'Warehouse Debts', // Added missing translation

          'receitas': 'Revenue',
          'receitasOperacionais': 'Operating Revenue',
          'vendaProducao': 'Production Sales',
          'vendaSoja': 'Soybean Sales',
          'vendaMilho': 'Corn Sales',
          'vendaAlgodao': 'Cotton Sales',
          'vendaTrigo': 'Wheat Sales', // Added missing translation
          'vendaCana': 'Sugarcane Sales', // Added missing translation
          'subsidiosGovernamentais': 'Government Subsidies', // Added missing translation

          'prestacaoServicos': 'Service Revenue',
          'outrasReceitas': 'Other Revenue',
          'receitasFinanceiras': 'Financial Revenue',
          'receitasEventuais': 'Miscellaneous Revenue',

          'custos': 'Costs',
          'custosProducao': 'Production Costs',
          'custosSoja': 'Costs - Soybean',
          'custosMilho': 'Costs - Corn',
          'custosAlgodao': 'Costs - Cotton',
          'custosTrigo': 'Costs - Wheat', // Added missing translation
          'custosArmazenamento': 'Storage Costs', // Added missing translation
          'custosTransporte': 'Transportation Costs', // Added missing translation

          'custosIndiretos': 'Indirect Costs',
          'manutencao': 'Maintenance',
          'maoObraIndireta': 'Indirect Labor',
          'energiaCombustiveis': 'Energy and Fuel',
          'fretes': 'Freight',

          'despesas': 'Expenses',
          'despesasAdministrativas': 'Administrative Expenses',
          'despesasComerciais': 'Commercial Expenses',
          'despesasFinanceiras': 'Financial Expenses',
          'despesasTributarias': 'Tax Expenses',

          'contasApuracao': 'Settlement Accounts',
          'apuracaoResultado': 'Income Statement',
          'culturasFormacao': 'Developing Crops'
        };
    }
  }

  // VALIDAÇÕES BÁSICAS

  // Verifica se é conta analítica
  static bool isContaAnalitica(String tipo) {
    return tipo == 'analitica';
  }

  // Verifica se é conta sintética
  static bool isContaSintetica(String tipo) {
    return tipo == 'sintetica';
  }

  // Verifica se permite lançamentos
  static bool permiteLancamento(String tipo) {
    return isContaAnalitica(tipo);
  }

  // Verifica se item movimenta estoque
  static bool isMovimentaEstoque(String operacao, Map<String, dynamic> mapeamento) {
    return mapeamento['geraEstoque'] ?? false;
  }

  // Verifica se operação gera lançamento contábil
  static bool geraLancamentoContabil(String operacao, Map<String, dynamic> mapeamento) {
    return mapeamento['tipo'] == 'financeiro';
  }

  // AGRUPAMENTOS PARA RELATÓRIOS

  // Retorna todas as contas de uma cultura específica
  static List<String> getContasCultura(String cultura) {
    switch(cultura.toUpperCase()) {
      case 'SOJA':
        return [
          CUSTOS_SOJA,
          VENDA_SOJA,
          CULTURAS_FORMACAO
        ];
      case 'MILHO':
        return [
          CUSTOS_MILHO,
          VENDA_MILHO,
          CULTURAS_FORMACAO
        ];
      case 'ALGODAO':
        return [
          CUSTOS_ALGODAO,
          VENDA_ALGODAO,
          CULTURAS_FORMACAO
        ];
      case 'TRIGO':
        return [
          CUSTOS_TRIGO,
          VENDA_TRIGO,
          CULTURAS_FORMACAO
        ];
      case 'CANAVIAL':
        return [
          CUSTOS_TRANSPORTE,
          CUSTOS_ARMAZENAMENTO,
          VENDA_CANA
        ];
      case 'FLORESTAS':
        return [
          FLORESTAS,
          LICENCAS_AMBIENTAIS,
          ATIVOS_BIOLOGICOS
        ];
      default:
        return [];
    }
  }

  // Retorna contas de estoque por tipo
  static List<String> getContasEstoque(String tipo) {
    switch(tipo.toUpperCase()) {
      case 'INSUMOS':
        return [ESTOQUE_INSUMOS];
      case 'SEMENTES':
        return [ESTOQUE_SEMENTES];
      case 'DEFENSIVOS':
        return [ESTOQUE_DEFENSIVOS];
      case 'FERTILIZANTES':
        return [ESTOQUE_FERTILIZANTES];
      case 'PRODUCAO':
        return [ESTOQUE_PRODUCAO];
      case 'FLORESTAS':
        return [FLORESTAS];
      default:
        return [];
    }
  }

  // Retorna contas por grupo
  static List<String> getContasGrupo(String grupo) {
    switch(grupo) {
      case '1':
        return [ATIVO, ATIVO_CIRCULANTE, ATIVO_NAO_CIRCULANTE, ATIVOS_BIOLOGICOS];
      case '2':
        return [PASSIVO, PASSIVO_CIRCULANTE, PASSIVO_NAO_CIRCULANTE, FINANCIAMENTOS_RURAIS];
      case '3':
        return [RECEITAS, RECEITAS_OPERACIONAIS, OUTRAS_RECEITAS];
      case '4':
        return [CUSTOS, CUSTOS_PRODUCAO, CUSTOS_INDIRETOS, DESPESAS];
      case '5':
        return [CONTAS_APURACAO, APURACAO_RESULTADO, CULTURAS_FORMACAO];
      default:
        return [];
    }
  }

  // MÉTODOS AUXILIARES

  // Gera histórico padrão da operação
  static String gerarHistorico({
    required String operacao,
    required String tipo,
    String? complemento
  }) {
    String historico = operacao.replaceAll('_', ' ');
    if (tipo.isNotEmpty) {
      historico += ' - $tipo';
    }
    if (complemento != null && complemento.isNotEmpty) {
      historico += ' - $complemento';
    }
    return historico;
  }

  // Retorna a natureza da conta baseada no seu código
  static String getNaturezaConta(String codigo) {
    String grupo = codigo.substring(0,1);
    switch(grupo) {
      case '1': // Ativos
      case '4': // Custos/Despesas
        return 'devedora';
      case '2': // Passivos
      case '3': // Receitas
        return 'credora';
      default:
        throw Exception('Grupo de contas inválido');
    }
  }

  // Verifica se o lançamento é consistente com a natureza da conta
  static bool isLancamentoValido({
    required String tipoConta,
    required String natureza,
    required String tipoLancamento
  }) {
    if (!permiteLancamento(tipoConta)) {
      return false;
    }

    if (natureza == 'devedora') {
      return tipoLancamento == 'debito';
    } else {
      return tipoLancamento == 'credito';
    }
  }

  // Retorna o nível da conta baseado no seu código
  static int getNivelConta(String codigo) {
    return codigo.split('.').length;
  }

  // Retorna o código da conta pai
  static String? getContaPai(String codigo) {
    List<String> partes = codigo.split('.');
    if (partes.length <= 1) return null;
    partes.removeLast();
    return partes.join('.');
  }
}
*/