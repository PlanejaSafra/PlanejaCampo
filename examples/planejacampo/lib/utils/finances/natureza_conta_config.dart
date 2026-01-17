// lib/utils/finances/natureza_conta_config.dart

/// Configuração das regras de natureza das contas contábeis
/// Define a natureza das contas e suas regras de lançamento
class NaturezaContaConfig {

  /// Retorna a natureza da conta baseada no seu código
  /// 1 e 4 são contas devedoras (Ativos e Custos/Despesas)
  /// 2 e 3 são contas credoras (Passivos e Receitas)
  static String getNaturezaConta(String codigo) {
    String grupo = codigo.substring(0, 1);
    switch(grupo) {
      case '1': // Ativos
      case '4': // Custos/Despesas
        return 'devedora';
      case '2': // Passivos
      case '3': // Receitas
        return 'credora';
      case '5': // Contas de Apuração - natureza variável
        return _getNaturezaContaApuracao(codigo);
      default:
        throw Exception('Grupo de contas inválido: $grupo');
    }
  }

  /// Retorna a natureza das contas de apuração
  static String _getNaturezaContaApuracao(String codigo) {
    // Regras específicas para contas de apuração
    if (codigo.startsWith('5.1')) { // Apuração de Resultado
      return 'devedora';
    } else if (codigo.startsWith('5.2')) { // Culturas em Formação
      return 'devedora';
    } else {
      return 'devedora'; // Padrão para outras contas de apuração
    }
  }

  /// Verifica se um lançamento é válido para uma conta
  static bool isLancamentoValido({
    required String tipoConta,
    required String natureza,
    required String tipoLancamento,
    double valor = 0.0
  }) {
    // Não permite lançamentos em contas sintéticas
    if (tipoConta != 'analitica') {
      return false;
    }

    // Não permite valores negativos
    if (valor < 0) {
      return false;
    }

    // Valida a natureza do lançamento
    switch (natureza) {
      case 'devedora':
        return tipoLancamento == 'debito';
      case 'credora':
        return tipoLancamento == 'credito';
      default:
        return false;
    }
  }

  /// Verifica se o saldo é normal para a natureza da conta
  static bool isSaldoNormal({
    required String natureza,
    required double saldo
  }) {
    switch (natureza) {
      case 'devedora':
        return saldo >= 0;
      case 'credora':
        return saldo <= 0;
      default:
        return false;
    }
  }

  /// Retorna o saldo ajustado pela natureza da conta
  static double getSaldoAjustado({
    required String natureza,
    required double saldo
  }) {
    switch (natureza) {
      case 'devedora':
        return saldo;
      case 'credora':
        return -saldo;
      default:
        return 0.0;
    }
  }

  /// Verifica se a natureza do lançamento é inversa
  static bool isLancamentoInverso({
    required String naturezaConta,
    required String tipoLancamento
  }) {
    return (naturezaConta == 'devedora' && tipoLancamento == 'credito') ||
        (naturezaConta == 'credora' && tipoLancamento == 'debito');
  }

  /// Retorna o tipo de lançamento normal para a natureza da conta
  static String getTipoLancamentoNormal(String natureza) {
    switch (natureza) {
      case 'devedora':
        return 'debito';
      case 'credora':
        return 'credito';
      default:
        throw Exception('Natureza inválida: $natureza');
    }
  }

  /// Retorna o tipo de lançamento inverso para a natureza da conta
  static String getTipoLancamentoInverso(String natureza) {
    switch (natureza) {
      case 'devedora':
        return 'credito';
      case 'credora':
        return 'debito';
      default:
        throw Exception('Natureza inválida: $natureza');
    }
  }

  /// Valida se um estorno está correto em relação à natureza da conta
  static bool isEstornoValido({
    required String naturezaConta,
    required String tipoLancamentoOriginal,
    required String tipoLancamentoEstorno,
    required double valorOriginal,
    required double valorEstorno
  }) {
    // Verifica se o tipo do estorno é inverso ao original
    if (tipoLancamentoOriginal == tipoLancamentoEstorno) {
      return false;
    }

    // Verifica se o valor do estorno não excede o original
    if (valorEstorno > valorOriginal) {
      return false;
    }

    // Verifica se o estorno mantém a natureza da conta
    return isLancamentoValido(
        tipoConta: 'analitica',
        natureza: naturezaConta,
        tipoLancamento: tipoLancamentoEstorno,
        valor: valorEstorno
    );
  }

  /// Verifica se a transferência é válida considerando a natureza das contas
  static bool isTransferenciaValida({
    required String naturezaContaOrigem,
    required String naturezaContaDestino,
    required String tipoLancamentoOrigem,
    required String tipoLancamentoDestino,
    required double valor
  }) {
    // Valida os lançamentos individuais
    bool origemValida = isLancamentoValido(
        tipoConta: 'analitica',
        natureza: naturezaContaOrigem,
        tipoLancamento: tipoLancamentoOrigem,
        valor: valor
    );

    bool destinoValida = isLancamentoValido(
        tipoConta: 'analitica',
        natureza: naturezaContaDestino,
        tipoLancamento: tipoLancamentoDestino,
        valor: valor
    );

    // Verifica se os lançamentos são complementares
    bool lancamentosComplementares =
        tipoLancamentoOrigem != tipoLancamentoDestino;

    return origemValida && destinoValida && lancamentosComplementares;
  }

  /// Retorna o efeito do lançamento no saldo da conta
  static double getEfeitoLancamento({
    required String naturezaConta,
    required String tipoLancamento,
    required double valor
  }) {
    // Para contas DEVEDORAS:
    // - Débito aumenta o saldo (efeito positivo)
    // - Crédito diminui o saldo (efeito negativo)
    if (naturezaConta == 'devedora') {
      return tipoLancamento == 'debito' ? valor : -valor;
    }

    // Para contas CREDORAS:
    // - Crédito aumenta o saldo (efeito positivo)
    // - Débito diminui o saldo (efeito negativo)
    else {
      return tipoLancamento == 'credito' ? valor : -valor;
    }
  }

  /// Valida se o saldo está compatível com a natureza da conta
  static bool isSaldoCompativel({
    required String naturezaConta,
    required double saldo
  }) {
    if (naturezaConta == 'devedora') {
      return saldo >= 0; // Saldo devedor é positivo
    } else {
      return saldo <= 0; // Saldo credor é negativo
    }
  }
}