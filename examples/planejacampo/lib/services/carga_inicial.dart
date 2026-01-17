import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart'; // Supondo que exista
import 'package:flutter/material.dart';
import 'package:planejacampo/utils/finances/contas_base_config.dart';
import 'package:planejacampo/utils/finances/plano_contas_config.dart';
//import 'package:planejacampo/utils/conta_contabil_config.dart';

class CargaInicial {
  // Método para carregar os bancos iniciais, contas e tipos de operações rurais
  static Future<void> carregarDadosIniciaisLanguageCode(
      String produtorId, bool isPessoaJuridica, Locale locale) async {
    print('Entrou em carregarDadosIniciaisLanguageCode');

    final produtorService = ProdutorService();
    final contaContabilService = ContaContabilService();
    final appStateManager = AppStateManager();

    final produtor = await produtorService.getById(produtorId);
    if (produtor == null) {
      print('Produtor não encontrado.');
      return;
    }

    final siglaPais = locale.countryCode ?? '';

    // Verificação do status da carga inicial
    Map<String, Map<String, dynamic>> cargaInicialMap = {};
    for (var entry in produtor.cargaInicial) {
      if (entry['siglaPais'] != null) {
        cargaInicialMap[entry['siglaPais']] = Map<String, dynamic>.from(entry);
      }
    }

    if (!cargaInicialMap.containsKey(siglaPais)) {
      cargaInicialMap[siglaPais] = {'siglaPais': siglaPais, 'status': 'in_progress'};
    } else {
      String status = cargaInicialMap[siglaPais]!['status'];
      if (status == 'completed') {
        print('Carga inicial já concluída para siglaPais: $siglaPais');
        return;
      }
      cargaInicialMap[siglaPais]!['status'] = 'in_progress';
    }

    // Atualiza o produtor COM o status 'in_progress' ANTES de iniciar a carga
    await produtorService.update(produtorId, produtor.copyWith(cargaInicial: cargaInicialMap.values.toList()));

    try {
      // 1. Carregar bancos para todas as licenças
      List<Banco> bancos = _carregarBancosPorIdioma(locale.languageCode, produtorId)
          .where((banco) => banco.nome != 'Outros' && banco.nome != 'Others')
          .toList();

      for (Banco banco in bancos) {
        await _salvarOuAtualizarBanco(banco);
      }

      // 2. Carregar tipos de operação rural para todas as licenças
      await _carregarTiposOperacaoRural(produtorId, siglaPais, locale);

      // 3. Verificar acesso ao módulo contábil
      if (appStateManager.hasModuleAccess('contabil')) {
        print('Produtor tem acesso ao módulo contábil. Carregando dados contábeis...');

        // 3.1 Carregar plano de contas (módulo contábil)
        await _inicializarPlanoContas(produtorId, siglaPais, locale.languageCode);

        // 3.2 Criar associações entre bancos e contas contábeis (módulo contábil)
        for (Banco banco in bancos) {
          await _criarContasContabeisBanco(produtorId, banco.nome, locale.languageCode, contaContabilService);
        }

        // 3.3 Criar contas bancárias com associações a contas contábeis (módulo contábil)
        await _criarContasPadrao(produtorId, isPessoaJuridica, locale);
      } else {
        print('Produtor NÃO tem acesso ao módulo contábil. Criando apenas contas bancárias básicas.');

        // 3.4 Criar contas bancárias sem associações a contas contábeis
        await _criarContasBancariasBasicas(produtorId, isPessoaJuridica, locale);
      }

      // 4. Atualizar status da carga inicial
      final updatedProdutor = await produtorService.getById(produtorId);
      if (updatedProdutor == null) {
        throw Exception('Produtor não encontrado após operações de carga inicial');
      }

      Map<String, Map<String, dynamic>> finalCargaInicialMap = {};
      for (var entry in updatedProdutor.cargaInicial) {
        if (entry['siglaPais'] != null) {
          finalCargaInicialMap[entry['siglaPais']] = Map<String, dynamic>.from(entry);
        }
      }

      finalCargaInicialMap[siglaPais] = {
        'siglaPais': siglaPais,
        'status': 'completed',
      };

      await produtorService.update(produtorId, updatedProdutor.copyWith(
        cargaInicial: finalCargaInicialMap.values.toList(),
      ));

      print('Carga inicial concluída para siglaPais: $siglaPais');

      // 5. Atualizar metadados do produtor
      final produtorAtualizado = await produtorService.getById(produtorId);
      if (produtorAtualizado != null) {
        final Map<String, dynamic> produtorMap = produtorAtualizado.toMap();
        if(produtorMap.containsKey('_metadata')){
          produtorMap['_metadata']['syncStatus'] = 'synced';
          await produtorService.update(produtorId, produtorService.fromMap(produtorMap, produtorId));
        }
      }
    } catch (e) {
      print('Erro durante cargaInicial: $e');
      throw e;
    }
  }

  // Método para criar contas bancárias básicas sem associação contábil
  static Future<void> _criarContasBancariasBasicas(
      String produtorId, bool isPessoaJuridica, Locale locale) async {
    final contaService = ContaService();
    final bancoService = BancoService();

    // Obter banco interno e banco "Outros"
    String nomeBancoInterno = _obterNomeBancoPadrao(isPessoaJuridica, locale.languageCode);
    String nomeBancoOutros = locale.languageCode == 'pt' ? 'Outros' : 'Others';

    String? bancoIdInterno = await _criarOuObterBanco(
        bancoService, nomeBancoInterno, produtorId, locale.countryCode ?? '');

    String? bancoIdOutros = await _criarOuObterBanco(
        bancoService, nomeBancoOutros, produtorId, locale.countryCode ?? '');

    if (bancoIdInterno == null || bancoIdOutros == null) {
      print('Erro ao obter bancos para criação de contas básicas');
      return;
    }

    // Criar contas bancárias básicas sem referência a contas contábeis
    Map<String, String> nomesContas = _obterNomesContas(locale.languageCode);

    List<Conta> contasPadrao = [
      Conta(
        id: '',
        nome: nomesContas['caixa']!,
        tipo: 'Caixa',
        numeroConta: '0001',
        bancoId: bancoIdInterno,
        saldoInicial: 0.0,
        produtorId: produtorId,
      ),
      Conta(
        id: '',
        nome: nomesContas['corrente']!,
        tipo: 'Corrente',
        numeroConta: '0002',
        bancoId: bancoIdOutros,
        saldoInicial: 0.0,
        produtorId: produtorId,
      ),
      Conta(
        id: '',
        nome: nomesContas['cartao']!,
        tipo: 'Crédito',
        numeroConta: '0003',
        bancoId: bancoIdOutros,
        saldoInicial: 0.0,
        limiteCredito: 0.0,
        diaFechamentoFatura: 31,
        diaVencimentoFatura: 10,
        produtorId: produtorId,
      ),
    ];

    for (Conta conta in contasPadrao) {
      try {
        await _salvarOuAtualizarConta(conta, contaService);
      } catch (e) {
        print('Erro ao salvar conta ${conta.nome}: $e');
      }
    }
  }

  static List<Banco> _carregarBancosPorIdioma(String languageCode, String produtorId) {
    print('Entrou em _carregarBancosPorIdioma');
    switch (languageCode) {
      case 'pt':
        return [
          Banco(id: '', nome: 'Banco do Brasil', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Caixa Econômica Federal', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Bradesco', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Itaú', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Santander', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Sicredi', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Sicoob', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Banco Daycoval', siglaPais: 'BR', produtorId: produtorId),
          Banco(id: '', nome: 'Banco Inter', siglaPais: 'BR', produtorId: produtorId),
        ];
      case 'en':
        return [
          Banco(id: '', nome: 'Bank of America', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'Chase Bank', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'Wells Fargo', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'Citibank', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'US Bank', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'Navy Federal Credit Union', siglaPais: 'US', produtorId: produtorId),
          Banco(id: '', nome: 'Agricultural Cooperative Federal Credit', siglaPais: 'US', produtorId: produtorId),
        ];
      default:
        return [];
    }
  }

  // Método atualizado para salvar ou atualizar banco
  static Future<String?> _salvarOuAtualizarBanco(Banco banco) async {
    //print('Entrou em _salvarOuAtualizarBanco');
    final bancoService = BancoService();

    List<Banco> bancosExistentes = await bancoService.getByAttributes({
      'nome': banco.nome,
      'produtorId': banco.produtorId,
      'siglaPais': banco.siglaPais,
    });

    if (bancosExistentes.isNotEmpty) {
      Banco bancoExistente = bancosExistentes.first;
      //print('Atualizando banco existente bancoExistente.id: ${bancoExistente.id}');
      await bancoService.update(bancoExistente.id, bancoExistente.copyWith(
        siglaPais: banco.siglaPais,
        endereco: banco.endereco,
        telefone: banco.telefone,
        contato: banco.contato,
      ));
      return bancoExistente.id;
    } else {
      //print('Criando um novo banco');
      return await bancoService.add(banco, returnId: true);
    }
  }


  // Carrega os bancos e cooperativas do Brasil
  static List<Banco> _carregarBancosBR(String produtorId) {
    print('Entrou em _carregarBancosBR');
    return [
      Banco(id: '', nome: 'Banco do Brasil', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Caixa Econômica Federal', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Bradesco', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Itaú', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Santander', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Sicredi', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Sicoob', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Banco Daycoval', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Banco Inter', siglaPais: 'BR', produtorId: produtorId),
      Banco(id: '', nome: 'Outros', siglaPais: 'BR', produtorId: produtorId),
    ];
  }

  // Carrega os bancos e cooperativas dos EUA (EN-US)
  static List<Banco> _carregarBancosEN(String produtorId) {
    print('Entrou em _carregarBancosEN');
    return [
      Banco(id: '', nome: 'Bank of America', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Chase Bank', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Wells Fargo', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Citibank', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'US Bank', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Navy Federal Credit Union', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Agricultural Cooperative Federal Credit', siglaPais: 'US', produtorId: produtorId),
      Banco(id: '', nome: 'Others', siglaPais: 'US', produtorId: produtorId),
    ];
  }



  // Método auxiliar para internacionalizar o nome do banco padrão
  static String _obterNomeBancoPadrao(bool isPessoaJuridica, String languageCode) {
    if (isPessoaJuridica) {
      return languageCode == 'pt' ? 'Caixa da Empresa' : 'Company Cash';
    } else {
      return languageCode == 'pt' ? 'Carteira' : 'Wallet';
    }
  }

  // Método auxiliar para obter os nomes das contas padrão
  static Map<String, String> _obterNomesContas(String languageCode) {
    switch (languageCode) {
      case 'pt':
        return {
          'caixa': 'Caixa',
          'corrente': 'Conta Corrente',
          'cartao': 'Cartão de Crédito',
        };
      case 'en':
        return {
          'caixa': 'Cash',
          'corrente': 'Checking Account',
          'cartao': 'Credit Card',
        };
      default:
      // Valores padrão podem ser em inglês
        return {
          'caixa': 'Cash',
          'corrente': 'Checking Account',
          'cartao': 'Credit Card',
        };
    }
  }

  // Método para salvar ou atualizar conta
  static Future<void> _salvarOuAtualizarConta(Conta conta, ContaService contaService) async {
    // Buscar conta existente pelo nome, produtorId e numeroConta
    List<Conta> contasExistentes = await contaService.getByAttributes({
      'nome': conta.nome,
      'produtorId': conta.produtorId,
      'numeroConta': conta.numeroConta,
    });

    if (contasExistentes.isNotEmpty) {
      // Atualizar conta existente
      Conta contaExistente = contasExistentes.first;
      await contaService.update(contaExistente.id, contaExistente.copyWith(
        saldoInicial: conta.saldoInicial,
        limiteCredito: conta.limiteCredito,
        diaFechamentoFatura: conta.diaFechamentoFatura,
        diaVencimentoFatura: conta.diaVencimentoFatura,
      ));
    } else {
      // Criar nova conta
      await contaService.add(conta);
    }
  }

  // Método para carregar os tipos de operações rurais
  static Future<void> _carregarTiposOperacaoRural(String produtorId, String siglaPais, Locale locale) async {
    print('Entrou em _carregarTiposOperacaoRural');
    final tipoOperacaoService = TipoOperacaoRuralService();

    // Definir os tipos de operações agrícolas principais
    List<TipoOperacaoRural> tiposOperacao = _definirTiposOperacaoAgricola(locale.languageCode, produtorId, siglaPais);

    // Salvar ou atualizar os tipos de operações rurais
    for (TipoOperacaoRural tipoOperacao in tiposOperacao) {
      await _salvarOuAtualizarTipoOperacaoRural(tipoOperacao, tipoOperacaoService);
    }

    print('Tipos de Operação Rural carregados com sucesso.');
  }

  // Definir os tipos de operações agrícolas principais com base no idioma e siglaPais
  static List<TipoOperacaoRural> _definirTiposOperacaoAgricola(String languageCode, String produtorId, String siglaPais) {
    switch (languageCode) {
      case 'pt':
        return [
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Aração',
            descricao: 'Preparação do solo para o plantio utilizando arado.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Gradagem de Nivelamento',
            descricao: 'Nivelação do solo para uniformizar a superfície.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Gradagem Pesada',
            descricao: 'Trabalhar o solo de forma mais profunda para descompactação.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Roçagem',
            descricao: 'Remoção da vegetação rasteira antes do plantio.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Quebra-lombo',
            descricao: 'Divisão do solo para facilitar o cultivo.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Subsolagem',
            descricao: 'Descompactação do solo em camadas profundas para melhorar a drenagem e a aeração.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Plantio Direto',
            descricao: 'Plantio das sementes diretamente no solo sem revolvimento.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Plantio Convencional',
            descricao: 'Plantio das sementes após o preparo convencional do solo.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Adubação',
            descricao: 'Aplicação de fertilizantes para nutrir as plantas.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Calagem',
            descricao: 'Aplicação de calcário para correção da acidez do solo.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Gessagem',
            descricao: 'Aplicação de gesso para corrigir a toxicidade do alumínio no solo.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Distribuição por Lançamento',
            descricao: 'Distribuição de fertilizantes ou corretivos por lançamento mecânico.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Irrigação por Aspersão',
            descricao: 'Irrigação das culturas utilizando aspersores que simulam a chuva.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Irrigação por Gotejamento',
            descricao: 'Irrigação localizada das plantas através de gotejadores.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Pulverização',
            descricao: 'Aplicação de defensivos agrícolas para controle de pragas e doenças.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Capina Manual',
            descricao: 'Controle manual de ervas daninhas.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Colheita Manual',
            descricao: 'Colheita das culturas de forma manual.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Colheita Mecanizada',
            descricao: 'Colheita das culturas utilizando maquinário.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Outros',
            descricao: 'Outras operações agrícolas.',
          ),
        ];
      case 'en':
        return [
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Plowing',
            descricao: 'Soil preparation for planting using a plow.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Leveling Harrowing',
            descricao: 'Soil leveling to uniform the surface.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Heavy Harrowing',
            descricao: 'Deep soil working to decompact the soil.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Mowing',
            descricao: 'Removal of ground vegetation before planting.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Subdivision',
            descricao: 'Division of soil to facilitate cultivation.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Subsoiling',
            descricao: 'Deep soil decompaction to improve drainage and aeration.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Direct Seeding',
            descricao: 'Planting seeds directly into the soil without tilling.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Conventional Seeding',
            descricao: 'Planting seeds after conventional soil preparation.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Fertilization',
            descricao: 'Application of fertilizers to nourish plants.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Lime Application',
            descricao: 'Application of lime to correct soil acidity.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Gypsum Application',
            descricao: 'Application of gypsum to correct aluminum toxicity in the soil.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Broadcast Application',
            descricao: 'Distribution of fertilizers or soil conditioners via mechanical broadcast.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Sprinkler Irrigation',
            descricao: 'Irrigation using sprinklers that simulate rainfall.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Drip Irrigation',
            descricao: 'Localized irrigation of plants through drip emitters.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Spraying',
            descricao: 'Application of agricultural pesticides for pest and disease control.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Manual Weeding',
            descricao: 'Manual control of weeds.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Manual Harvesting',
            descricao: 'Harvesting crops manually.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Mechanized Harvesting',
            descricao: 'Harvesting crops using machinery.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Others',
            descricao: 'Other agricultural operations.',
          ),
        ];
      default:
      // Padrão em inglês
        return [
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Plowing',
            descricao: 'Soil preparation for planting using a plow.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Leveling Harrowing',
            descricao: 'Soil leveling to uniform the surface.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Heavy Harrowing',
            descricao: 'Deep soil working to decompact the soil.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Mowing',
            descricao: 'Removal of ground vegetation before planting.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Subdivision',
            descricao: 'Division of soil to facilitate cultivation.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Subsoiling',
            descricao: 'Deep soil decompaction to improve drainage and aeration.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Direct Seeding',
            descricao: 'Planting seeds directly into the soil without tilling.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Conventional Seeding',
            descricao: 'Planting seeds after conventional soil preparation.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Fertilization',
            descricao: 'Application of fertilizers to nourish plants.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Lime Application',
            descricao: 'Application of lime to correct soil acidity.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Gypsum Application',
            descricao: 'Application of gypsum to correct aluminum toxicity in the soil.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Broadcast Application',
            descricao: 'Distribution of fertilizers or soil conditioners via mechanical broadcast.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Sprinkler Irrigation',
            descricao: 'Irrigation using sprinklers that simulate rainfall.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Drip Irrigation',
            descricao: 'Localized irrigation of plants through drip emitters.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Spraying',
            descricao: 'Application of agricultural pesticides for pest and disease control.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Manual Weeding',
            descricao: 'Manual control of weeds.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Manual Harvesting',
            descricao: 'Harvesting crops manually.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Mechanized Harvesting',
            descricao: 'Harvesting crops using machinery.',
          ),
          TipoOperacaoRural(
            id: '',
            produtorId: produtorId,
            siglaPais: siglaPais,
            nome: 'Others',
            descricao: 'Other agricultural operations.',
          ),
        ];
    }
  }

  // Método para salvar ou atualizar tipo de operação rural
  static Future<void> _salvarOuAtualizarTipoOperacaoRural(TipoOperacaoRural tipoOperacao, TipoOperacaoRuralService tipoOperacaoService) async {
    // Buscar tipo de operação existente pelo nome, produtorId e siglaPais
    List<TipoOperacaoRural> tiposExistentes = await tipoOperacaoService.getByAttributes({
      'nome': tipoOperacao.nome,
      'produtorId': tipoOperacao.produtorId,
      'siglaPais': tipoOperacao.siglaPais,
    });

    if (tiposExistentes.isNotEmpty) {
      // Atualizar tipo de operação existente
      TipoOperacaoRural tipoExistente = tiposExistentes.first;
      await tipoOperacaoService.update(tipoExistente.id, tipoOperacao.copyWith(
        descricao: tipoOperacao.descricao,
      ));
      print('Tipo de operação atualizada: ${tipoOperacao.nome}');
    } else {
      // Criar novo tipo de operação
      await tipoOperacaoService.add(tipoOperacao);
      print('Novo tipo de operação criado: ${tipoOperacao.nome}');
    }
  }

  // Em CargaInicial, adicionar após _criarContasPadrao:

  // Método para inicializar plano de contas
  static Future<void> _inicializarPlanoContas(
    String produtorId,
    String siglaPais,
    String languageCode
  ) async {
      print('Iniciando carregamento do plano de contas');

      final contaContabilService = ContaContabilService();
      final planoContasPadrao = PlanoContasConfig.getPlanoContasPadrao(languageCode);
      
      // Mapeamento de código para ID real da conta
      Map<String, String> codigoParaId = {};
      
      // Primeira passagem: processar contas sem pai ou com parent ID já mapeado
      for (var nivel = 1; nivel <= 5; nivel++) {
          for (var contaMap in planoContasPadrao) {
              // Verifica se esta conta está no nível atual
              if (contaMap['codigo'].toString().split('.').length == nivel) {
                  String? contaPaiCodigo = contaMap['contaPaiId'];
                  String? contaPaiId;
                  
                  // Se tiver pai, buscar o ID real do mapeamento
                  if (contaPaiCodigo != null) {
                      contaPaiId = codigoParaId[contaPaiCodigo];
                      // Se não encontrou, pular para a próxima iteração
                      if (contaPaiId == null) continue;
                  }
                  
                  ContaContabil conta = ContaContabil(
                      id: '',
                      codigo: contaMap['codigo'],
                      nome: contaMap['nome'],
                      tipo: contaMap['tipo'],
                      natureza: contaMap['natureza'],
                      contaPaiId: contaPaiId ?? '', // Usar ID real ou string vazia
                      ativo: true,
                      produtorId: produtorId,
                      languageCode: languageCode,
                  );
                  
                  // Salvar conta e obter ID
                  String? novoId = await _salvarOuAtualizarContaContabilComId(conta);
                  if (novoId != null) {
                      // Adicionar ao mapeamento
                      codigoParaId[contaMap['codigo']] = novoId;
                  }
              }
          }
      }
      
      print('Plano de contas inicializado com sucesso');
  }

  // Nova função auxiliar para salvar conta e retornar ID
  static Future<String?> _salvarOuAtualizarContaContabilComId(ContaContabil conta) async {
      final contaContabilService = ContaContabilService();
      
      // Buscar conta existente pelo código e produtorId
      final contas = await contaContabilService.getByAttributes({
          'codigo': conta.codigo,
          'produtorId': conta.produtorId,
          'languageCode': conta.languageCode,
      });
      
      if (contas.isNotEmpty) {
          // Atualizar conta existente
          ContaContabil contaExistente = contas.first;
          await contaContabilService.update(contaExistente.id, contaExistente.copyWith(
              nome: conta.nome,
              tipo: conta.tipo,
              natureza: conta.natureza,
              contaPaiId: conta.contaPaiId,
          ));
          return contaExistente.id;
      } else {
          // Criar nova conta
          return await contaContabilService.add(conta, returnId: true);
      }
  }



  // Método atualizado para criar as contas padrão
  // Método para criar as contas padrão
  static Future<void> _criarContasPadrao(
      String produtorId, bool isPessoaJuridica, Locale locale) async {
    final contaService = ContaService();
    final bancoService = BancoService();
    final contaContabilService = ContaContabilService();

    print('Entrou em _criarContasPadrao');

    // 1. Criar banco interno (Caixa/Carteira)
    String nomeBancoInterno = _obterNomeBancoPadrao(isPessoaJuridica, locale.languageCode);
    String? bancoIdInterno = await _criarOuObterBanco(
        bancoService, nomeBancoInterno, produtorId, locale.countryCode ?? '');
    if (bancoIdInterno == null) {
      throw Exception('Falha ao criar/obter banco interno');
    }

    // 2. Criar banco "Outros"
    String nomeBancoOutros = locale.languageCode == 'pt' ? 'Outros' : 'Others';
    String? bancoIdOutros = await _criarOuObterBanco(
        bancoService, nomeBancoOutros, produtorId, locale.countryCode ?? '');
    if (bancoIdOutros == null) {
      throw Exception('Falha ao criar/obter banco Outros');
    }

    // 3. Buscar conta CAIXA para associar ao caixa interno
    List<ContaContabil> contaCaixa = await contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.CAIXA,
      'produtorId': produtorId,
      'languageCode': locale.languageCode,
    });

    if (contaCaixa.isEmpty) {
      throw Exception('Conta CAIXA não encontrada');
    }

    // 4. Criar estrutura hierárquica de contas contábeis para os bancos
    Map<String, String>? contasBancoInterno = await _criarContasContabeisBanco(
        produtorId, nomeBancoInterno, locale.languageCode, contaContabilService);
    if (contasBancoInterno == null) {
      throw Exception('Falha ao criar contas contábeis para banco interno');
    }

    Map<String, String>? contasBancoOutros = await _criarContasContabeisBanco(
        produtorId, nomeBancoOutros, locale.languageCode, contaContabilService);
    if (contasBancoOutros == null) {
      throw Exception('Falha ao criar contas contábeis para banco Outros');
    }

    // 5. Criar as contas bancárias padrão
    Map<String, String> nomesContas = _obterNomesContas(locale.languageCode);

    List<Conta> contasPadrao = [
      // Conta Caixa - Usando o ID da conta contábil
      Conta(
        id: '',
        nome: nomesContas['caixa']!,
        tipo: 'Caixa',
        numeroConta: '0001',
        bancoId: bancoIdInterno,
        saldoInicial: 0.0,
        produtorId: produtorId,
        contaContabilId: contaCaixa.first.id, // ID real da conta contábil
      ),
      // Conta Corrente - Usando o ID da subconta
      Conta(
        id: '',
        nome: nomesContas['corrente']!,
        tipo: 'Corrente',
        numeroConta: '0002',
        bancoId: bancoIdOutros,
        saldoInicial: 0.0,
        produtorId: produtorId,
        contaContabilId: contasBancoOutros['contaCorrenteId']!, // ID real da subconta
      ),
      // Cartão de Crédito - Usando o ID da subconta
      Conta(
        id: '',
        nome: nomesContas['cartao']!,
        tipo: 'Crédito',
        numeroConta: '0003',
        bancoId: bancoIdOutros,
        saldoInicial: 0.0,
        limiteCredito: 0.0,
        diaFechamentoFatura: 31,
        diaVencimentoFatura: 10,
        produtorId: produtorId,
        contaContabilId: contasBancoOutros['contaCartaoId']!, // ID real da subconta
      ),
    ];

    // 6. Salvar ou atualizar as contas
    for (Conta conta in contasPadrao) {
      try {
        await _salvarOuAtualizarConta(conta, contaService);
      } catch (e) {
        print('Erro ao salvar/atualizar conta ${conta.nome}: $e');
        throw Exception('Falha ao criar conta bancária: ${conta.nome}');
      }
    }
  }

  // Método auxiliar para criar ou obter banco
  static Future<String?> _criarOuObterBanco(
      BancoService bancoService,
      String nomeBanco,
      String produtorId,
      String siglaPais) async {

    List<Banco> bancosExistentes = await bancoService.getByAttributes({
      'nome': nomeBanco,
      'produtorId': produtorId,
      'siglaPais': siglaPais,
    });

    if (bancosExistentes.isNotEmpty) {
      return bancosExistentes.first.id;
    }

    Banco novoBanco = Banco(
      id: '',
      nome: nomeBanco,
      siglaPais: siglaPais,
      produtorId: produtorId,
    );

    return await bancoService.add(novoBanco, returnId: true);
  }
  
  // Método para verificar se já existem contas contábeis para um código específico
  static Future<bool> _verificarExistenciaConta(
      String codigo,
      String produtorId,
      ContaContabilService contaContabilService) async {

    List<ContaContabil> contasExistentes = await contaContabilService.getByAttributes({
      'codigo': codigo,
      'produtorId': produtorId,
    });

    return contasExistentes.isNotEmpty;
  }

  // Método para obter próximo número disponível para conta de banco
  static Future<String> _obterProximoNumeroBanco(
      String produtorId,
      ContaContabilService contaContabilService) async {

    // Começar do 1 e incrementar até encontrar um número não utilizado
    int numero = 1;
    bool numeroExiste;

    do {
      String numeroFormatado = numero.toString().padLeft(2, '0');

      // Verificar no Ativo (BANCOS)
      numeroExiste = await _verificarExistenciaConta(
          '${ContasBaseConfig.BANCOS}.$numeroFormatado',
          produtorId,
          contaContabilService
      );

      // Se não existe no Ativo, verificar no Passivo (EMPRESTIMOS_FINANCIAMENTOS)
      if (!numeroExiste) {
        numeroExiste = await _verificarExistenciaConta(
            '${ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS}.$numeroFormatado',
            produtorId,
            contaContabilService
        );
      }

      numero++;
    } while (numeroExiste);

    return (numero - 1).toString().padLeft(2, '0');
  }

  // Método para criar estrutura hierárquica de contas contábeis para banco
  // Método para criar estrutura hierárquica de contas contábeis para banco
  static Future<Map<String, String>?> _criarContasContabeisBanco(
      String produtorId,
      String nomeBanco,
      String languageCode,
      ContaContabilService contaContabilService) async {

    // Verificar contas pai - usar getByAttributes para buscar pelo código
    List<ContaContabil> contaBancosPai = await contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.BANCOS,
      'produtorId': produtorId,
      'languageCode': languageCode,
    });

    List<ContaContabil> contaEmprestimosPai = await contaContabilService.getByAttributes({
      'codigo': ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS,
      'produtorId': produtorId,
      'languageCode': languageCode,
    });

    if (contaBancosPai.isEmpty || contaEmprestimosPai.isEmpty) {
      print('Contas pai não encontradas');
      return null;
    }

    // Importante: Obter os IDs reais, não os códigos
    String contaBancosPaiId = contaBancosPai.first.id;
    String contaEmprestimosPaiId = contaEmprestimosPai.first.id;

    // Obter próximo número disponível
    String numeroBancoFormatado = await _obterProximoNumeroBanco(
        produtorId,
        contaContabilService
    );

    // Verificar se as contas já existem
    String codigoAtivo = '${ContasBaseConfig.BANCOS}.$numeroBancoFormatado';
    String codigoPassivo = '${ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS}.$numeroBancoFormatado';

    bool contaAtivoExiste = await _verificarExistenciaConta(
        codigoAtivo,
        produtorId,
        contaContabilService
    );

    bool contaPassivoExiste = await _verificarExistenciaConta(
        codigoPassivo,
        produtorId,
        contaContabilService
    );

    if (contaAtivoExiste || contaPassivoExiste) {
      print('Já existem contas com os códigos $codigoAtivo ou $codigoPassivo');
      return null;
    }

    // 4. Criar conta sintética do banco no Ativo
    ContaContabil contaBancoAtivo = ContaContabil(
      id: '',
      codigo: '${ContasBaseConfig.BANCOS}.$numeroBancoFormatado',
      nome: nomeBanco,
      tipo: 'sintetica',
      natureza: 'devedora',
      contaPaiId: contaBancosPaiId, // Usar o ID real da conta pai, não o código
      ativo: true,
      produtorId: produtorId,
      languageCode: languageCode,
    );

    String? contaBancoAtivoId = await contaContabilService.add(contaBancoAtivo, returnId: true);
    if (contaBancoAtivoId == null) {
      throw Exception('Falha ao criar conta sintética do banco no Ativo');
    }

    // 5. Criar subcontas no Ativo
    Map<String, ContaContabil> subcontasAtivo = {
      'corrente': ContaContabil(
        id: '',
        codigo: '${contaBancoAtivo.codigo}.01',
        nome: languageCode == 'pt' ? 'Conta Corrente' : 'Checking Account',
        tipo: 'analitica',
        natureza: 'devedora',
        contaPaiId: contaBancoAtivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
      'poupanca': ContaContabil(
        id: '',
        codigo: '${contaBancoAtivo.codigo}.02',
        nome: languageCode == 'pt' ? 'Poupança' : 'Savings Account',
        tipo: 'analitica',
        natureza: 'devedora',
        contaPaiId: contaBancoAtivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
      'investimentos': ContaContabil(
        id: '',
        codigo: '${contaBancoAtivo.codigo}.03',
        nome: languageCode == 'pt' ? 'Investimentos' : 'Investments',
        tipo: 'analitica',
        natureza: 'devedora',
        contaPaiId: contaBancoAtivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
    };

    Map<String, String> subcontasAtivoIds = {};
    for (var entry in subcontasAtivo.entries) {
      String? id = await contaContabilService.add(entry.value, returnId: true);
      if (id == null) {
        throw Exception('Falha ao criar subconta do Ativo: ${entry.key}');
      }
      subcontasAtivoIds[entry.key] = id;
    }

    // 6. Criar conta sintética do banco no Passivo
    ContaContabil contaBancoPassivo = ContaContabil(
      id: '',
      codigo: '${ContasBaseConfig.EMPRESTIMOS_FINANCIAMENTOS}.$numeroBancoFormatado',
      nome: '$nomeBanco - Empréstimos e Financiamentos',
      tipo: 'sintetica',
      natureza: 'credora',
      contaPaiId: contaEmprestimosPaiId, // Usar o ID real da conta pai, não o código
      ativo: true,
      produtorId: produtorId,
      languageCode: languageCode,
    );

    String? contaBancoPassivoId = await contaContabilService.add(contaBancoPassivo, returnId: true);
    if (contaBancoPassivoId == null) {
      throw Exception('Falha ao criar conta sintética do banco no Passivo');
    }

    // 7. Criar subcontas no Passivo
    Map<String, ContaContabil> subcontasPassivo = {
      'emprestimos': ContaContabil(
        id: '',
        codigo: '${contaBancoPassivo.codigo}.01',
        nome: languageCode == 'pt' ? 'Empréstimos' : 'Loans',
        tipo: 'analitica',
        natureza: 'credora',
        contaPaiId: contaBancoPassivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
      'financiamentos': ContaContabil(
        id: '',
        codigo: '${contaBancoPassivo.codigo}.02',
        nome: languageCode == 'pt' ? 'Financiamentos' : 'Financing',
        tipo: 'analitica',
        natureza: 'credora',
        contaPaiId: contaBancoPassivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
      'cartao': ContaContabil(
        id: '',
        codigo: '${contaBancoPassivo.codigo}.03',
        nome: languageCode == 'pt' ? 'Cartão de Crédito' : 'Credit Card',
        tipo: 'analitica',
        natureza: 'credora',
        contaPaiId: contaBancoPassivoId, // Usar ID real, não o código
        ativo: true,
        produtorId: produtorId,
        languageCode: languageCode,
      ),
    };

    Map<String, String> subcontasPassivoIds = {};
    for (var entry in subcontasPassivo.entries) {
      String? id = await contaContabilService.add(entry.value, returnId: true);
      if (id == null) {
        throw Exception('Falha ao criar subconta do Passivo: ${entry.key}');
      }
      subcontasPassivoIds[entry.key] = id;
    }

    // 8. Retornar mapa com todos os IDs
    return {
      'contaAtivoId': contaBancoAtivoId,
      'contaPassivoId': contaBancoPassivoId,
      'contaCorrenteId': subcontasAtivoIds['corrente']!,
      'contaPoupancaId': subcontasAtivoIds['poupanca']!,
      'contaInvestimentosId': subcontasAtivoIds['investimentos']!,
      'contaEmprestimosId': subcontasPassivoIds['emprestimos']!,
      'contaFinanciamentosId': subcontasPassivoIds['financiamentos']!,
      'contaCartaoId': subcontasPassivoIds['cartao']!,
    };
  }


}
