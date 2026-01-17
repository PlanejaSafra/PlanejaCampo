import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/dias_uteis_options.dart';

class ContaBancariaOptions {
  // Tipos de contas
  static const List<String> tipos = <String>[
    'Caixa',
    'Corrente',
    'Poupança',
    'Crédito'
  ];

  // Status de conta
  static const List<String> status = <String>['Ativa', 'Inativa'];

  // Mapeamento dos valores internos para as strings internacionalizadas
  static Map<String, String> getLocalizedTipos(BuildContext context) {
    return {
      'Caixa': S.of(context).cash,
      'Corrente': S.of(context).checking_account,
      'Poupança': S.of(context).savings_account,
      'Crédito': S.of(context).credit_card,
    };
  }

  static Map<String, String> getLocalizedStatus(BuildContext context) {
    return {
      'Ativa': S.of(context).active,
      'Inativa': S.of(context).inactive,
    };
  }

  // Função auxiliar para retornar lista de tipos internacionalizados
  static List<String> getLocalizedTiposString(BuildContext context) {
    return ContaBancariaOptions.getLocalizedTipos(context).values.toList();
  }

  // Função auxiliar para retornar lista de status internacionalizados
  static List<String> getLocalizedStatusString(BuildContext context) {
    return ContaBancariaOptions.getLocalizedStatus(context).values.toList();
  }

  /// Método para obter a conta padrão com base na forma de pagamento selecionada
  static Conta? getDefaultContaBancaria(String meioPagamento, List<Conta> contas) {
    String? defaultNumeroConta;
    List<String> allowedTipos = [];

    switch (meioPagamento) {
      case 'Cheque':
      case 'Débito':
      case 'Pix/TED':
        defaultNumeroConta = '0002'; // Conta Corrente
        allowedTipos = ['Corrente', 'Poupança'];
        break;
      case 'Crédito':
        defaultNumeroConta = '0003'; // Cartão de Crédito
        allowedTipos = ['Crédito'];
        break;
      case 'Dinheiro':
        defaultNumeroConta = '0001'; // Caixa
        allowedTipos = ['Caixa'];
        break;
      default:
        return null; // Para 'Boleto' e 'Outros', não há meio de pagamento
    }

    // Tentar encontrar a conta com numeroConta específico
    try {
      Conta conta = contas.firstWhere(
        (c) => c.numeroConta == defaultNumeroConta && allowedTipos.contains(c.tipo),
      );
      return conta;
    } catch (e) {
      // Não encontrou a conta específica, proceder com a seleção padrão
    }

    // Selecionar a primeira conta disponível do tipo permitido
    for (String tipo in allowedTipos) {
      try {
        Conta conta = contas.firstWhere((c) => c.tipo == tipo);
        return conta;
      } catch (e) {
        // Não encontrou conta do tipo atual, continuar
        continue;
      }
    }

    // Se nenhuma conta for encontrada, retornar null
    return null;
  }

  /// Método para verificar se uma conta é permitida para uma determinada forma de pagamento
  static bool isContaAllowedForPagamento(String meioPagamento, Conta conta) {
    switch (meioPagamento) {
      case 'Cheque':
      case 'Débito':
      case 'Pix/TED':
        return conta.tipo == 'Corrente' || conta.tipo == 'Poupança';
      case 'Crédito':
        return conta.tipo == 'Crédito';
      case 'Dinheiro':
        return conta.tipo == 'Caixa';
      default:
        return false;
    }
  }

  /// Método para buscar as contas usando o ContaService e getByAttributes
  static Future<List<Conta>> buscarContasBancarias(ContaService contaService, String produtorId) async {
    try {
      BancoService bancoService = BancoService();
      List<Banco> bancos = await bancoService.getByAttributes({
        'produtorId': produtorId,
        'siglaPais': AppStateManager().appLocale.countryCode,
      });

      List<Conta> contas = await Future.wait(
        bancos.map((banco) => contaService.getByAttributes({
              'produtorId': produtorId,
              'bancoId': banco.id,
            }))
      ).then((listOfLists) => listOfLists.expand((list) => list).toList());

      //for (Conta conta in contas) {
      //  print('Contas adicionadas em buscarContas: conta.id: ${conta.id}, conta.nome: ${conta.nome}');
      //}
      return contas;
    } catch (e) {
      throw Exception('Erro ao buscar contas: $e');
    }
  }

  /// Novo Método para obter nomes de contas permitidas para uma forma de pagamento
  static List<String> getAllowedContaBancariaNames(String meioPagamento, List<Conta> contas) {
    return contas
        .where((conta) => isContaAllowedForPagamento(meioPagamento, conta))
        .map((conta) => conta.nome)
        .toList();
  }

  /// Calcula a data de vencimento da parcela considerando o ciclo de faturamento ou
  /// os meios de pagamento que não possuem ciclo de faturamento.
  static DateTime calcularDataVencimento(
      DateTime dataCompra,
      Conta? conta,
      int numeroParcela,
      bool hasFaturamento,
      ) {
    // Data base da parcela sempre baseada na data da compra
    DateTime dataCalculada;

    if (numeroParcela == 1) {
      // Primeira parcela na data da compra
      dataCalculada = dataCompra;
    } else {
      // Parcelas subsequentes no mesmo dia dos próximos meses
      int ano = dataCompra.month + (numeroParcela - 1) > 12
          ? dataCompra.year + ((dataCompra.month + numeroParcela - 1) ~/ 12)
          : dataCompra.year;

      int mes = (dataCompra.month + (numeroParcela - 1) - 1) % 12 + 1;

      // Ajusta para o último dia do mês se necessário
      int ultimoDiaMes = DateUtils.getDaysInMonth(ano, mes);
      int dia = dataCompra.day > ultimoDiaMes ? ultimoDiaMes : dataCompra.day;

      dataCalculada = DateTime(ano, mes, dia);
    }

    // Ajusta para próximo dia útil se cair em fim de semana
    return DiasUteisOptions.ajustarParaDiaUtil(dataCalculada);
  }

// Novo método para calcular data de vencimento da fatura
  static DateTime calcularDataVencimentoFatura(
      DateTime dataCompra,
      Conta conta
      ) {
    // Determina o fechamento atual
    DateTime dataFechamento = DateTime(
        dataCompra.year,
        dataCompra.month,
        conta.diaFechamentoFatura ?? 1
    );

    // Se a compra for após o fechamento, usa o próximo fechamento
    if (dataCompra.isAfter(dataFechamento)) {
      if (dataCompra.month == 12) {
        dataFechamento = DateTime(dataCompra.year + 1, 1, conta.diaFechamentoFatura ?? 1);
      } else {
        dataFechamento = DateTime(dataCompra.year, dataCompra.month + 1, conta.diaFechamentoFatura ?? 1);
      }
    }

    // Calcula o vencimento da fatura
    int mesVencimento = dataFechamento.month == 12 ? 1 : dataFechamento.month + 1;
    int anoVencimento = dataFechamento.month == 12 ? dataFechamento.year + 1 : dataFechamento.year;

    return DateTime(anoVencimento, mesVencimento, conta.diaVencimentoFatura ?? 10);
  }

}
