// lib/utils/finances/contas_validacao_config.dart

import 'package:planejacampo/utils/finances/contas_base_config.dart';

/// Configuração das validações e regras contábeis
class ContasValidacaoConfig {
  /// Verifica se uma conta é analítica (pode receber lançamentos)
  static bool isContaAnalitica(String tipo) {
    return tipo == 'analitica';
  }

  /// Verifica se uma conta é sintética (agrupa outras contas)
  static bool isContaSintetica(String tipo) {
    return tipo == 'sintetica';
  }

  /// Verifica se a conta pode receber lançamentos
  static bool permiteLancamento(String tipo) {
    return isContaAnalitica(tipo);
  }

  /// Verifica se o lançamento é válido para a natureza da conta
  /// Ex: Débito em conta devedora = OK, Crédito em conta devedora = NOK
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

  /// Verifica se a conta está no grupo de ativos
  static bool isContaAtivo(String codigo) {
    return codigo.startsWith('1');
  }

  /// Verifica se a conta está no grupo de passivos
  static bool isContaPassivo(String codigo) {
    return codigo.startsWith('2');
  }

  /// Verifica se a conta está no grupo de receitas
  static bool isContaReceita(String codigo) {
    return codigo.startsWith('3');
  }

  /// Verifica se a conta está no grupo de custos/despesas
  static bool isContaCusto(String codigo) {
    return codigo.startsWith('4');
  }

  /// Verifica se a conta está no grupo de apuração
  static bool isContaApuracao(String codigo) {
    return codigo.startsWith('5');
  }

  /// Verifica se a conta é de estoque
  static bool isContaEstoque(String codigo) {
    return codigo.startsWith(ContasBaseConfig.ESTOQUES);
  }

  /// Verifica se a conta é de disponibilidades (caixa, bancos)
  static bool isContaDisponivel(String codigo) {
    return codigo.startsWith(ContasBaseConfig.DISPONIVEL);
  }

  /// Verifica se as partidas do lançamento estão balanceadas
  static bool isPartidasBalanceadas(List<Map<String, dynamic>> partidas) {
    double totalDebitos = 0;
    double totalCreditos = 0;

    for (var partida in partidas) {
      if (partida['tipo'] == 'debito') {
        totalDebitos += partida['valor'];
      } else {
        totalCreditos += partida['valor'];
      }
    }

    // Considera uma pequena margem de erro para arredondamentos
    return (totalDebitos - totalCreditos).abs() < 0.01;
  }

  /// Verifica se um lançamento é de estorno válido
  static bool isEstornoValido({
    required String tipoOriginal,
    required String tipoEstorno,
    required double valorOriginal,
    required double valorEstorno
  }) {
    // Estorno deve ser do tipo oposto ao lançamento original
    if (tipoOriginal == tipoEstorno) {
      return false;
    }

    // Valor do estorno não pode ser maior que o valor original
    if (valorEstorno > valorOriginal) {
      return false;
    }

    return true;
  }

  /// Verifica se a combinação de contas para transferência é válida
  static bool isTransferenciaValida({
    required String contaOrigem,
    required String contaDestino
  }) {
    // Transferência só pode ocorrer entre contas do mesmo grupo
    String grupoOrigem = contaOrigem.substring(0, 1);
    String grupoDestino = contaDestino.substring(0, 1);

    if (grupoOrigem != grupoDestino) {
      return false;
    }

    // Verifica se ambas as contas são analíticas
    if (!ContasBaseConfig.CONTAS_ANALITICAS.contains(contaOrigem) ||
        !ContasBaseConfig.CONTAS_ANALITICAS.contains(contaDestino)) {
      return false;
    }

    return true;
  }

  /// Verifica se as contas usadas em uma operação são compatíveis
  static bool isContasOperacaoCompativeis({
    required String operacao,
    required List<String> contas,
    required String tipo
  }) {
    switch (operacao) {
      case 'CompraInsumos':
      // Deve ter uma conta de estoque e uma conta de fornecedor
        bool temEstoque = contas.any((conta) => isContaEstoque(conta));
        bool temFornecedor = contas.any((conta) =>
            conta.startsWith(ContasBaseConfig.FORNECEDORES));
        return temEstoque && temFornecedor;

      case 'PagamentoFornecedor':
      // Deve ter uma conta de disponível e uma conta de fornecedor
        bool temDisponivel = contas.any((conta) => isContaDisponivel(conta));
        bool temFornecedor = contas.any((conta) =>
            conta.startsWith(ContasBaseConfig.FORNECEDORES));
        return temDisponivel && temFornecedor;

      default:
        return true; // Outras operações não têm validações específicas
    }
  }

  /// Verifica se a conta pertence a um determinado tipo de atividade
  static bool isContaAtividade({
    required String codigo,
    required String tipoAtividade
  }) {
    switch (tipoAtividade) {
      case 'Agricultura':
        return codigo.startsWith(ContasBaseConfig.CUSTOS_ATIVIDADES_AGRICOLAS) ||
            codigo.startsWith(ContasBaseConfig.RECEITAS_PRODUTOS_AGRICOLAS);

      case 'Pecuaria':
        return codigo.startsWith(ContasBaseConfig.CUSTOS_ATIVIDADES_PECUARIAS) ||
            codigo.startsWith(ContasBaseConfig.RECEITAS_PRODUTOS_PECUARIOS);

      default:
        return false;
    }
  }
}