// lib/utils/finances/estrutura_conta_config.dart

import 'package:planejacampo/utils/finances/contas_base_config.dart';

/// Configuração da estrutura hierárquica e organizacional das contas contábeis
class EstruturaContaConfig {

  /// Retorna o nível da conta na hierarquia baseado no código
  static int getNivelConta(String codigo) {
    return codigo.split('.').length;
  }

  /// Retorna o código da conta pai
  static String? getContaPai(String codigo) {
    List<String> partes = codigo.split('.');
    if (partes.length <= 1) return null;
    partes.removeLast();
    return partes.join('.');
  }

  /// Retorna o grupo principal da conta (primeiro nível)
  static String getGrupoPrincipal(String codigo) {
    return codigo.split('.').first;
  }

  /// Verifica se uma conta é filha de outra
  static bool isContaFilha(String codigoPai, String codigoFilha) {
    return codigoFilha.startsWith('$codigoPai.');
  }

  /// Retorna o caminho completo até a conta raiz
  static List<String> getCaminhoRaiz(String codigo) {
    List<String> caminho = [];
    String? codigoAtual = codigo;

    while (codigoAtual != null) {
      caminho.add(codigoAtual);
      codigoAtual = getContaPai(codigoAtual);
    }

    return caminho.reversed.toList();
  }

  /// Verifica se uma conta pode ter filhas
  static bool podeTermFilhas(String tipo) {
    return tipo == 'sintetica';
  }

  /// Verifica se o código da conta é válido estruturalmente
  static bool isCodigoValido(String codigo) {
    // Verifica formato geral (X.X.X.XX)
    RegExp formatoGeral = RegExp(r'^\d+(\.\d+)*$');
    if (!formatoGeral.hasMatch(codigo)) {
      return false;
    }

    // Verifica se o grupo principal é válido (1-5)
    String grupoPrincipal = getGrupoPrincipal(codigo);
    if (!['1', '2', '3', '4', '5'].contains(grupoPrincipal)) {
      return false;
    }

    // Verifica profundidade máxima
    if (getNivelConta(codigo) > 4) {
      return false;
    }

    return true;
  }

  /// Retorna o nível máximo permitido para um grupo
  static int getNivelMaximoGrupo(String grupo) {
    switch (grupo) {
      case '1': // Ativos
      case '2': // Passivos
        return 4;
      case '3': // Receitas
      case '4': // Custos/Despesas
        return 3;
      case '5': // Apuração
        return 2;
      default:
        return 0;
    }
  }

  /// Gera um novo código de conta baseado no pai e número sequencial
  static String gerarCodigoConta({
    required String codigoPai,
    required int sequencial,
  }) {
    // Valida a entrada
    if (!isCodigoValido(codigoPai)) {
      throw Exception('Código pai inválido');
    }

    // Verifica se atingiu nível máximo
    String grupo = getGrupoPrincipal(codigoPai);
    if (getNivelConta(codigoPai) >= getNivelMaximoGrupo(grupo)) {
      throw Exception('Nível máximo atingido para o grupo $grupo');
    }

    // Gera novo código
    String sequencialFormatado = sequencial.toString().padLeft(2, '0');
    return '$codigoPai.$sequencialFormatado';
  }

  /// Retorna todas as contas filhas diretas
  static List<String> getContasFilhasImediatas(String codigoPai) {
    return ContasBaseConfig.CONTAS_ANALITICAS.where(
            (codigo) => getContaPai(codigo) == codigoPai
    ).toList();
  }

  /// Retorna todas as contas descendentes (incluindo subníveis)
  static List<String> getTodasContasDescendentes(String codigoPai) {
    return ContasBaseConfig.CONTAS_ANALITICAS.where(
            (codigo) => isContaFilha(codigoPai, codigo)
    ).toList();
  }

  /// Determina o nível de detalhamento requerido para um tipo de atividade
  static int getNivelDetalheRequerido(String tipoAtividade) {
    switch (tipoAtividade.toUpperCase()) {
      case 'AGRICULTURA':
      case 'PECUARIA':
        return 4;  // Requer detalhamento máximo
      case 'SILVICULTURA':
        return 3;  // Requer detalhamento intermediário
      default:
        return 2;  // Nível básico para outras atividades
    }
  }

  /// Verifica se uma conta está no nível de detalhe adequado para a atividade
  static bool isNivelDetalheAdequado({
    required String codigo,
    required String tipoAtividade
  }) {
    int nivelConta = getNivelConta(codigo);
    int nivelRequerido = getNivelDetalheRequerido(tipoAtividade);
    return nivelConta >= nivelRequerido;
  }

  /// Retorna sugestão de novo código para adequação ao nível de detalhe
  static String getSugestaoCodigoDetalhado({
    required String codigo,
    required String tipoAtividade
  }) {
    int nivelAtual = getNivelConta(codigo);
    int nivelRequerido = getNivelDetalheRequerido(tipoAtividade);

    if (nivelAtual >= nivelRequerido) {
      return codigo;
    }

    String codigoBase = codigo;
    for (int i = nivelAtual + 1; i <= nivelRequerido; i++) {
      codigoBase = gerarCodigoConta(codigoPai: codigoBase, sequencial: 1);
    }

    return codigoBase;
  }
}