class ContasBaseConfig {
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

  // Constante auxiliar para a conta "Conta Corrente" dentro dos bancos (Ativo)
  static const String CONTA_CORRENTE = "CONTA_CORRENTE";

  // GRUPO 2 - PASSIVOS
  static const String PASSIVO = "2";
  static const String PASSIVO_CIRCULANTE = "2.1";
  static const String FORNECEDORES = "2.1.1";
  static const String EMPRESTIMOS_FINANCIAMENTOS = "2.1.2";
  // Constantes auxiliares para os tipos de subcontas em EMPRESTIMOS_FINANCIAMENTOS:
  static const String EMPRESTIMOS_SUB = "EMPRESTIMOS";
  static const String CARTAO_SUB = "CARTAO";

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
  static const String RECEITAS_PRODUTOS_AGRICOLAS = "3.1.1";
  static const String RECEITAS_PRODUTOS_PECUARIOS = "3.1.2";
  static const String SUBSIDIOS_GOVERNAMENTAIS = "3.1.3";
  static const String PRESTACAO_SERVICOS = "3.1.4";

  static const String OUTRAS_RECEITAS = "3.2";
  static const String RECEITAS_FINANCEIRAS = "3.2.1";
  static const String RECEITAS_EVENTUAIS = "3.2.2";

  // GRUPO 4 - CUSTOS E DESPESAS
  static const String CUSTOS = "4";
  static const String CUSTOS_PRODUCAO = "4.1";
  static const String CUSTOS_ATIVIDADES_AGRICOLAS = "4.1.1";
  static const String CUSTOS_ATIVIDADES_PECUARIAS = "4.1.2";
  static const String CUSTOS_ARMAZENAMENTO = "4.1.3";
  static const String CUSTOS_TRANSPORTE = "4.1.4";

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

  // Lista de grupos principais
  static const List<String> GRUPOS_PRINCIPAIS = [
    ATIVO,
    PASSIVO,
    RECEITAS,
    CUSTOS,
    CONTAS_APURACAO
  ];

  // Lista de subgrupos do Ativo Circulante
  static const List<String> SUBGRUPOS_ATIVO_CIRCULANTE = [
    DISPONIVEL,
    DIREITOS_REALIZAVEIS,
    ESTOQUES
  ];

  // Lista de subgrupos do Ativo Não Circulante
  static const List<String> SUBGRUPOS_ATIVO_NAO_CIRCULANTE = [
    REALIZAVEL_LONGO_PRAZO,
    INVESTIMENTOS,
    IMOBILIZADO,
    ATIVOS_BIOLOGICOS,
    LICENCAS_AMBIENTAIS,
    DIREITOS_EXPLORACAO_AGRICOLA
  ];

  // Lista de subgrupos do Passivo Circulante
  static const List<String> SUBGRUPOS_PASSIVO_CIRCULANTE = [
    FORNECEDORES,
    EMPRESTIMOS_FINANCIAMENTOS,
    OBRIGACOES_TRABALHISTAS,
    OBRIGACOES_TRIBUTARIAS,
    ADIANTAMENTOS_CLIENTES
  ];

  // Lista de subgrupos do Passivo Não Circulante
  static const List<String> SUBGRUPOS_PASSIVO_NAO_CIRCULANTE = [
    EMPRESTIMOS_LP,
    FINANCIAMENTOS_LP,
    FINANCIAMENTOS_RURAIS
  ];

  // Lista de subgrupos das Receitas
  static const List<String> SUBGRUPOS_RECEITAS = [
    RECEITAS_OPERACIONAIS,
    OUTRAS_RECEITAS
  ];

  // Lista de subgrupos dos Custos
  static const List<String> SUBGRUPOS_CUSTOS = [
    CUSTOS_PRODUCAO,
    CUSTOS_INDIRETOS,
    DESPESAS
  ];

  // Lista de todas as contas que podem receber lançamentos
  static const List<String> CONTAS_ANALITICAS = [
    CAIXA,
    BANCOS,
    APLICACOES,
    CLIENTES,
    ADIANTAMENTOS,
    IMPOSTOS_RECUPERAR,
    ESTOQUE_INSUMOS,
    ESTOQUE_SEMENTES,
    ESTOQUE_DEFENSIVOS,
    ESTOQUE_FERTILIZANTES,
    ESTOQUE_EMBALAGENS,
    ESTOQUE_PRODUCAO,
    MAQUINAS_EQUIPAMENTOS,
    VEICULOS,
    INSTALACOES,
    TERRAS,
    CULTURAS_PERMANENTES,
    GADO,
    FLORESTAS,
    FORNECEDORES,
    EMPRESTIMOS_FINANCIAMENTOS,
    OBRIGACOES_TRABALHISTAS,
    OBRIGACOES_TRIBUTARIAS,
    ADIANTAMENTOS_CLIENTES,
    PRONAF,
    DIVIDAS_ARMAZENS,
    RECEITAS_PRODUTOS_AGRICOLAS,
    RECEITAS_PRODUTOS_PECUARIOS,
    SUBSIDIOS_GOVERNAMENTAIS,
    PRESTACAO_SERVICOS,
    RECEITAS_FINANCEIRAS,
    RECEITAS_EVENTUAIS,
    CUSTOS_ATIVIDADES_AGRICOLAS,
    CUSTOS_ATIVIDADES_PECUARIAS,
    CUSTOS_ARMAZENAMENTO,
    CUSTOS_TRANSPORTE,
    MANUTENCAO,
    MAO_OBRA_INDIRETA,
    ENERGIA_COMBUSTIVEIS,
    FRETES,
    DESPESAS_ADMINISTRATIVAS,
    DESPESAS_COMERCIAIS,
    DESPESAS_FINANCEIRAS,
    DESPESAS_TRIBUTARIAS,
    APURACAO_RESULTADO,
    CULTURAS_FORMACAO
  ];
}
