// lib/services/agro/adubacao/calculators/nutriente_calculator.dart

import 'dart:math' as Math;

import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_exception.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';

class NutrienteCalculator {

  Future<Map<String, RecomendacaoNutriente>> calcularDoses({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required double produtividadeEsperada,
    required TexturaSolo texturaSolo,
    required ClasseResposta classeResposta,
    required bool irrigado,
    required String produtorId,
    required String propriedadeId,
  }) async {
    final recomendacoes = <String, RecomendacaoNutriente>{};

    // --- Tratamento de N ---
    // Verifica se a cultura usa FBN primariamente
    bool usarFBN = parametros.cultura == TipoCultura.SOJA; // Adicione outras leguminosas se necessário

    if (usarFBN) {
      // Cria entrada FBN diretamente
      recomendacoes['N'] = RecomendacaoNutriente(
        id: '',
        recomendacaoId: '',
        produtorId: produtorId,
        propriedadeId: propriedadeId,
        nutriente: 'N',
        teor: analise.mo, // MO como referência
        interpretacao: 'Fixação Biológica de Nitrogênio (FBN) como fonte principal.',
        doseRecomendada: 0.0,
        fonte: 'FBN',
        eficiencia: 0.0,
        restricoes: [],
        observacoes: ['Utilizar inoculante específico e realizar coinoculação se necessário.'],
      );
    } else {
      // Calcula N para não-leguminosas
      recomendacoes['N'] = await _calcularDoseN(
        analise: analise,
        parametros: parametros,
        produtividadeEsperada: produtividadeEsperada,
        classeResposta: classeResposta,
        irrigado: irrigado,
        produtorId: produtorId,
        propriedadeId: propriedadeId,
      );
    }
    // ----------------------


    // Calcula P2O5
    recomendacoes['P2O5'] = await _calcularDoseP(
      analise: analise,
      parametros: parametros,
      produtividadeEsperada: produtividadeEsperada,
      texturaSolo: texturaSolo, // Passar textura para possíveis ajustes futuros
      produtorId: produtorId,
      propriedadeId: propriedadeId,
    );

    // Calcula K2O
    recomendacoes['K2O'] = await _calcularDoseK(
      analise: analise,
      parametros: parametros,
      produtividadeEsperada: produtividadeEsperada,
      texturaSolo: texturaSolo, // Passar textura para ajustes de parcelamento
      produtorId: produtorId,
      propriedadeId: propriedadeId,
    );

    // Calcula micronutrientes
    final micronutrientes = await _calcularDosesMicro(
      analise: analise,
      parametros: parametros,
      produtorId: produtorId,
      propriedadeId: propriedadeId,
    );

    recomendacoes.addAll(micronutrientes);

    return recomendacoes;
  }

  // *** FUNÇÃO AUXILIAR DE INTERPRETAÇÃO (DEFINIDA DENTRO DA CLASSE) ***
  /// Interpreta o teor do macronutriente no solo usando os parâmetros da cultura.
  String _interpretarTeorSolo(String nutriente, double valorAnalise, CulturaParametros parametros) {
    final limites = parametros.teoresCriticosMacro[nutriente];

    if (limites == null || limites.isEmpty) {
      print('Aviso: Teores críticos ausentes para $nutriente na cultura ${parametros.cultura}. Usando interpretação padrão.');
      return 'medio'; // Retorna um padrão genérico
    }

    // Ordem de verificação: do mais baixo para o mais alto
    // Usar ?? double.negativeInfinity e ?? double.infinity para tratar limites ausentes
    // Certifique-se que as chaves ('muito_baixo', 'baixo', etc.) correspondem exatamente às definidas no factory
    if (limites.containsKey('muito_baixo') && valorAnalise <= limites['muito_baixo']!) {
      return 'muito_baixo';
    } else if (limites.containsKey('baixo') && valorAnalise <= limites['baixo']!) {
      return 'baixo';
    } else if (limites.containsKey('medio') && valorAnalise <= limites['medio']!) {
      return 'medio';
    } else if (limites.containsKey('alto') && valorAnalise <= limites['alto']!) {
      return 'alto';
    } else if (limites.containsKey('adequado') && valorAnalise <= limites['adequado']!) { // 'adequado' pode ser igual a 'alto'
      return 'adequado';
    } else {
      // Se for maior que todos os limites definidos
      return limites.containsKey('muito_alto') ? 'muito_alto' :
      limites.containsKey('alto') ? 'alto' :
      limites.containsKey('adequado') ? 'adequado' : 'alto'; // Fallback final (geralmente 'alto' ou 'adequado')
    }
  }
  // *** FIM DA FUNÇÃO AUXILIAR ***


  // Método utilitário para buscar a dose de um nutriente baseado na produtividade
  double _buscarDoseNutriente(
      CulturaParametros parametros,
      String nutriente,
      double produtividadeEsperada,
      double valorAnalise, // Teor do nutriente (ou MO para N)
      ) {
    final doseMap = parametros.recomendacaoNPK[nutriente];
    if (doseMap == null || doseMap.isEmpty) {
      print('Mapa de doses ausente para $nutriente.');
      return 0.0;
    }

    final sortedKeys = doseMap.keys.toList()..sort();

    // Determina a interpretação do solo usando a nova função auxiliar
    // Passa o teor correto (MO para N, P para P2O5, K para K2O)
    // ** IMPORTANTE: A função chamadora (_calcularDoseN/P/K) DEVE passar o valor correto aqui **
    final String interpretacao = _interpretarTeorSolo(nutriente, valorAnalise, parametros);

    double dose = 0.0;
    bool doseEncontrada = false;

    // Função interna para buscar e interpolar (poderia ser um método separado também)
    double buscarEInterpolar(String chaveInterpretacao) {
      // Implementação da lógica de busca e interpolação (como na resposta anterior)
      // Retorna a dose encontrada ou -1.0 se a chaveInterpretacao não existir para a(s) produtividade(s)
      double doseResultado = 0.0;
      bool encontrada = false;

      // Caso 1: Produtividade exata ou menor que a primeira chave
      if (produtividadeEsperada <= sortedKeys.first) {
        doseResultado = doseMap[sortedKeys.first]?[chaveInterpretacao] ?? 0.0;
        encontrada = doseMap[sortedKeys.first]?.containsKey(chaveInterpretacao) ?? false;
        return encontrada ? doseResultado : -1.0; // Retorna -1 se a chave não existe
      }

      // Caso 2: Produtividade maior que a última chave
      if (produtividadeEsperada >= sortedKeys.last) {
        doseResultado = doseMap[sortedKeys.last]?[chaveInterpretacao] ?? 0.0;
        encontrada = doseMap[sortedKeys.last]?.containsKey(chaveInterpretacao) ?? false;
        return encontrada ? doseResultado : -1.0;
      }

      // Caso 3: Interpolar entre duas chaves
      for (int i = 0; i < sortedKeys.length - 1; i++) {
        double lowerKey = sortedKeys[i];
        double upperKey = sortedKeys[i + 1];

        if (produtividadeEsperada >= lowerKey && produtividadeEsperada <= upperKey) {
          double? doseLower = doseMap[lowerKey]?[chaveInterpretacao];
          double? doseUpper = doseMap[upperKey]?[chaveInterpretacao];

          // Verifica se ambas as chaves existem para a interpolação
          if (doseLower != null && doseUpper != null) {
            double fator = (produtividadeEsperada - lowerKey) / (upperKey - lowerKey);
            doseResultado = doseLower + (doseUpper - doseLower) * fator;
            encontrada = true;
            return doseResultado; // Retorna a dose interpolada
          } else {
            // Se uma das chaves não existe, não pode interpolar para esta interpretação
            return -1.0;
          }
        }
      }
      return -1.0; // Não encontrou intervalo
    } // Fim buscarEInterpolar

    // Tentativa 1: Buscar pela interpretação específica do solo
    dose = buscarEInterpolar(interpretacao);
    if (dose != -1.0) {
      doseEncontrada = true;
    }

    // Tentativa 2: Buscar pela chave 'geral' se a específica falhou
    if (!doseEncontrada) {
      dose = buscarEInterpolar('geral');
      if (dose != -1.0) {
        doseEncontrada = true;
      }
    }

    // Tentativa 3: Usar fallback se nada foi encontrado
    if (!doseEncontrada) {
      print('Aviso: Não foi possível encontrar dose para $nutriente com interpretação "$interpretacao" ou "geral". Usando fallback.');
      dose = _getFallbackDose(nutriente, parametros.cultura, valorAnalise, produtividadeEsperada);
    }

    return Math.max(0.0, dose); // Garante dose não negativa
  }


  // --- _calcularDoseN ---
  Future<RecomendacaoNutriente> _calcularDoseN({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required double produtividadeEsperada,
    required ClasseResposta classeResposta,
    required bool irrigado,
    required String produtorId,
    required String propriedadeId,
  }) async {
    double dose = 0.0;
    List<String> observacoes = [];
    List<String> restricoes = [];
    List<String> avisos = [];
    String interpretacao = '';
    String fonte = 'N/A';
    double eficiencia = 0.0;

    // Mapeia ClasseResposta para a interpretação
    String interpretacaoClasse;
    if (classeResposta == ClasseResposta.ALTA) {
      interpretacaoClasse = 'baixo'; // Alta resposta = maior demanda de N (equivalente a V% < 50%)
      interpretacao = 'Classe de resposta Alta (V% < 50%)';
      observacoes.add('Classe de resposta Alta: maior demanda de N.');
    } else {
      interpretacaoClasse = 'medio'; // Média/baixa resposta = demanda padrão (equivalente a V% >= 50%)
      interpretacao = 'Classe de resposta Média/Baixa (V% >= 50%)';
      observacoes.add('Classe de resposta Média/Baixa: demanda padrão de N.');
    }

    // Busca a dose usando um placeholder para valorAnalise (não usado para N)
    dose = _buscarDoseNutriente(parametros, 'N', produtividadeEsperada, 0.0);

    if (dose > 0) {
      interpretacao += ' - Dose baseada na classe de resposta.';

      // Ajustes por irrigação e parcelamento
      if (irrigado) {
        observacoes.add('Área irrigada: Recomenda-se parcelar N em 3-4 aplicações.');
      } else if (parametros.permiteParcelamentoN && dose > 60) {
        observacoes.add('Dose de N > 60 kg/ha: Recomenda-se parcelar em 2 aplicações.');
      }

      fonte = parametros.fontesNutrientes['N']?.first ?? 'Ureia/Sulfato de Amônio';
      eficiencia = 0.7;

      // Verifica limites máximos
      final limiteMaxN = parametros.limitesMaximosNutrientes['N'];
      if (limiteMaxN != null && dose > limiteMaxN) {
        avisos.add('AVISO: Dose de N (${dose.toStringAsFixed(1)} kg/ha) excede o limite máximo (${limiteMaxN} kg/ha).');
      }
    } else {
      interpretacao = 'Adubação nitrogenada não recomendada ou não aplicável.';
      fonte = 'N/A';
      eficiencia = 0.0;
      observacoes.add('Verificar parâmetros de produtividade e classe de resposta.');
    }

    // Adiciona avisos às observações
    if (avisos.isNotEmpty) {
      observacoes.addAll(avisos);
    }

    return RecomendacaoNutriente(
      id: '',
      recomendacaoId: '',
      produtorId: produtorId,
      propriedadeId: propriedadeId,
      nutriente: 'N',
      teor: analise.mo, // Mantém MO como referência informativa
      interpretacao: interpretacao,
      doseRecomendada: Math.max(0.0, dose),
      fonte: fonte,
      eficiencia: eficiencia,
      restricoes: restricoes,
      observacoes: observacoes,
    );
  }


  // --- _calcularDoseP ---
  Future<RecomendacaoNutriente> _calcularDoseP({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required double produtividadeEsperada,
    required TexturaSolo texturaSolo, // Usado para observações
    required String produtorId,
    required String propriedadeId,
  }) async {
    double dose = 0.0;
    List<String> observacoes = [];
    List<String> restricoes = [];
    String interpretacao = '';

    double pValor = analise.fosforo; // Usar o valor de Fósforo da análise

    // Busca a dose usando o método principal, passando o teor de P
    dose = _buscarDoseNutriente(parametros, 'P2O5', produtividadeEsperada, pValor);

    // Obtém a interpretação correta para P
    interpretacao = _interpretarTeorSolo('P2O5', pValor, parametros);
    interpretacao += ' teor de P'; // Adiciona descrição

    // Adicionar observações sobre manejo de P
    if (texturaSolo == TexturaSolo.ARGILOSO) {
      observacoes.add('Em solo argiloso, preferir aplicação localizada de P para reduzir fixação.');
    } else if (texturaSolo == TexturaSolo.ARENOSO) {
      observacoes.add('Em solo arenoso, aplicar P no sulco de plantio para reduzir perdas por lixiviação.');
    }
    observacoes.add('Aplicar todo o fósforo no plantio para melhor aproveitamento pela cultura.');

    // Verificação para solos com P muito alto (ex: > 80 mg/dm³)
    // O limite pode variar, pegar dos parâmetros se definido, senão usar um padrão
    double limiteAltoP = parametros.teoresCriticosMacro['P2O5']?['alto'] ?? // Tenta pegar 'alto'
        parametros.teoresCriticosMacro['P2O5']?['adequado'] ?? // Senão 'adequado'
        80.0; // Senão padrão 80
    if (pValor > limiteAltoP) {
      // Limita a dose de arranque/manutenção
      double doseManutencao = 40.0; // Valor comum, pode vir dos parâmetros se existir
      dose = Math.min(dose, doseManutencao);
      observacoes.add('Em solos com teores muito altos de P (> ${limiteAltoP.toStringAsFixed(1)} mg/dm³), aplicar apenas ${dose.toStringAsFixed(1)} kg/ha como adubação de arranque/manutenção.');
    }

    // Verificação de Limites (avisos)
    final limiteMaxP = parametros.limitesMaximosNutrientes['P2O5'];
    if (limiteMaxP != null && dose > limiteMaxP) {
      observacoes.add('AVISO: Dose calculada de P2O5 (${dose.toStringAsFixed(1)}) excede o limite (${limiteMaxP}).');
    }

    return RecomendacaoNutriente(
      id: '',
      recomendacaoId: '',
      produtorId: produtorId,
      propriedadeId: propriedadeId,
      nutriente: 'P2O5',
      teor: pValor,
      interpretacao: interpretacao,
      doseRecomendada: Math.max(0.0, dose),
      fonte: parametros.fontesNutrientes['P2O5']?.first ?? 'Superfosfato Simples/Triplo',
      eficiencia: 0.7, // Ajustar se necessário
      restricoes: restricoes,
      observacoes: observacoes,
    );
  }


  // --- _calcularDoseK ---
  Future<RecomendacaoNutriente> _calcularDoseK({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required double produtividadeEsperada,
    required TexturaSolo texturaSolo,
    required String produtorId,
    required String propriedadeId,
  }) async {
    if (analise.potassio == null || analise.potassio < 0) {
      throw RecomendacaoException('Teor de K+ não disponível na análise de solo');
    }

    double dose = 0.0;
    List<String> observacoes = [];
    List<String> restricoes = [];
    List<String> avisos = [];
    String interpretacao = '';

    double kValor = analise.potassio; // Usar o valor de Potássio da análise

    // Busca a dose usando o método principal, passando o teor de K
    dose = _buscarDoseNutriente(parametros, 'K2O', produtividadeEsperada, kValor);

    // Obtém a interpretação correta para K
    interpretacao = _interpretarTeorSolo('K2O', kValor, parametros);
    interpretacao += ' teor de K'; // Adiciona descrição

    // Ajustes e observações para K
    // Verificar teor muito alto (ex: > 6.0 mmolc/dm³)
    double limiteMuitoAltoK = parametros.teoresCriticosMacro['K2O']?['muito_alto'] ?? 6.0;
    if (kValor > limiteMuitoAltoK) {
      dose = 0.0; // Suprime adubação para teores muito altos
      observacoes.add(
          'Teor muito alto de K (> ${limiteMuitoAltoK.toStringAsFixed(1)} mmolc/dm³): adubação potássica não recomendada ou apenas manutenção mínima.'
      );
    }

    // Adiciona restrições e observações apenas se a dose for > 0
    if (dose > 0) {
      // Restrição de K2O no sulco
      final limiteSulcoK = parametros.limitesMaximosSulco['K2O'];
      if (limiteSulcoK != null) {
        restricoes.add('Não aplicar mais de ${limiteSulcoK} kg/ha de K2O no sulco de plantio/semeadura.');
        // Aviso se a dose total excede o limite do sulco (implica parcelamento ou pré-plantio)
        if(dose > limiteSulcoK) {
          avisos.add('Dose total de K2O (${dose.toStringAsFixed(1)}) excede o limite do sulco (${limiteSulcoK}). Necessário aplicar parte em cobertura ou pré-plantio.');
        }
      }

      // Recomendação para pré-plantio em teor baixo e dose alta
      double limiteBaixoK = parametros.teoresCriticosMacro['K2O']?['baixo'] ?? 1.6;
      if (kValor < limiteBaixoK && dose >= 80) { // Usar limite 'baixo' dos parâmetros
        observacoes.add(
            'Com teor baixo de K (< ${limiteBaixoK.toStringAsFixed(1)}) e dose ≥ 80 kg/ha, considerar transferir parte ou toda adubação para pré-plantio a lanço.'
        );
      }

      // Recomendação para parcelamento em solo arenoso
      if (texturaSolo == TexturaSolo.ARENOSO) {
        observacoes.add('Solo arenoso: Recomenda-se parcelar K2O para reduzir perdas por lixiviação (aplicar parte no plantio/sulco respeitando limite, e restante em cobertura).');
      }

      // Recomendação para parcelamento em solo de baixa CTC (opcional)
      if (analise.ctc < 5.0) { // Usar um limite de CTC baixo (ex: 5 ou 4)
        observacoes.add('Solo com baixa CTC (< 5 cmolc/dm³): Maior risco de perdas de K por lixiviação. Parcelamento recomendado.');
      }
    }

    // Adiciona avisos às observações
    if (avisos.isNotEmpty) {
      observacoes.addAll(avisos);
    }

    // Verificação de Limites Gerais (avisos)
    final limiteMaxK = parametros.limitesMaximosNutrientes['K2O'];
    if (limiteMaxK != null && dose > limiteMaxK) {
      observacoes.add('AVISO: Dose calculada de K2O (${dose.toStringAsFixed(1)}) excede o limite geral (${limiteMaxK}).');
    }


    return RecomendacaoNutriente(
      id: '',
      recomendacaoId: '',
      produtorId: produtorId,
      propriedadeId: propriedadeId,
      nutriente: 'K2O',
      teor: kValor,
      interpretacao: interpretacao,
      doseRecomendada: Math.max(0.0, dose),
      fonte: parametros.fontesNutrientes['K2O']?.first ?? 'Cloreto de Potássio',
      eficiencia: 0.8, // Ajustar se necessário
      restricoes: restricoes,
      observacoes: observacoes,
    );
  }


  // --- _calcularDosesMicro ---
  // (Manter a versão anterior ou ajustá-la conforme necessário)
  Future<Map<String, RecomendacaoNutriente>> _calcularDosesMicro({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required String produtorId,
    required String propriedadeId,
  }) async {
    // ... (código de _calcularDosesMicro como na resposta anterior) ...
    try {
      print('Calculando doses de micronutrientes:');
      print('Teores críticos micro: ${parametros.teoresCriticosMicro}');
      print('Recomendação micro: ${parametros.recomendacaoMicro}');

      Map<String, RecomendacaoNutriente> micronutrientes = {};

      // Mapeia o nome do nutriente para o valor correspondente na análise
      final Map<String, double?> valoresSolo = {
        'B': analise.boro,
        'Cu': analise.cobre,
        'Fe': analise.ferro,
        'Mn': analise.manganes,
        'Zn': analise.zinco,
        // Adicionar Mo e Co se forem relevantes e presentes na análise/parâmetros
        // 'Mo': analise.molibdenio,
        // 'Co': analise.cobalto,
      };

      for (var entry in valoresSolo.entries) {
        final nutriente = entry.key;
        final teor = entry.value;

        // Pula se o teor for nulo ou se não houver parâmetros para este micro
        if (teor == null ||
            !parametros.teoresCriticosMicro.containsKey(nutriente) ||
            !parametros.recomendacaoMicro.containsKey(nutriente)) {
          continue;
        }

        var limites = parametros.teoresCriticosMicro[nutriente]!; // Mapa de limites ('baixo', 'medio')
        var recomendacoes = parametros.recomendacaoMicro[nutriente]!; // Mapa de recomendação ('<0.2', '0.2-0.6', etc.)

        double dose = 0.0;
        String interpretacao = 'Não Definido'; // Inicializa interpretação

        // Determinar interpretação baseada nos limites específicos do nutriente
        // Usar ?? double.infinity para garantir que a comparação funcione se 'medio' não existir
        if (teor <= (limites['baixo'] ?? double.negativeInfinity)) {
          interpretacao = 'Baixo';
        } else if (teor <= (limites['medio'] ?? double.infinity)) {
          interpretacao = 'Médio';
        } else {
          interpretacao = 'Adequado'; // Ou 'Alto' se definido
        }

        // Busca a dose correspondente usando a função auxiliar
        dose = _buscarDoseMicronutriente(recomendacoes, teor, limites);

        // Adicionar observações específicas para micros, se houver (ex: toxidez de Boro)

        micronutrientes[nutriente] = RecomendacaoNutriente(
          id: '',
          recomendacaoId: '',
          produtorId: produtorId,
          propriedadeId: propriedadeId,
          nutriente: nutriente,
          teor: teor,
          interpretacao: interpretacao,
          doseRecomendada: Math.max(0.0, dose),
          fonte: _definirFonteMicronutriente(nutriente),
          eficiencia: 0.6, // Eficiência média para micros, ajustar se necessário
          restricoes: [],
          observacoes: [], // Adicionar obs específicas aqui se necessário
        );
      }

      return micronutrientes;
    } catch (e, stackTrace) {
      print('Erro ao calcular doses de micronutrientes: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Propaga o erro para ser tratado no processor
    }
  }

  // --- _buscarDoseMicronutriente ---
  double _buscarDoseMicronutriente(Map<String, double> recomendacoes, double teor, Map<String, double> limites) {
    // ... (código de _buscarDoseMicronutriente como na resposta anterior) ...
    // Tentar encontrar a chave exata para a faixa do teor
    // Usar limites para determinar a faixa correta
    double? limiteBaixo = limites['baixo'];
    double? limiteMedio = limites['medio']; // Pode não existir

    if (limiteBaixo != null && teor < limiteBaixo) {
      // Teor baixo: procurar chave como '<X.X'
      final chave = recomendacoes.keys.firstWhere((k) => k.startsWith('<'), orElse: () => '');
      return recomendacoes[chave] ?? 0.0;
    } else if (limiteBaixo != null && limiteMedio != null && teor >= limiteBaixo && teor <= limiteMedio) {
      // Teor médio: procurar chave como 'X.X-Y.Y'
      final chave = recomendacoes.keys.firstWhere((k) => k.contains('-'), orElse: () => '');
      return recomendacoes[chave] ?? 0.0;
    } else {
      // Teor adequado/alto: procurar chave como '>Y.Y'
      final chave = recomendacoes.keys.firstWhere((k) => k.startsWith('>'), orElse: () => '');
      return recomendacoes[chave] ?? 0.0;
    }
  }

  // --- _definirFonteMicronutriente ---
  String _definirFonteMicronutriente(String nutriente) {
    // ... (código de _definirFonteMicronutriente como na resposta anterior) ...
    switch (nutriente) {
      case 'B':
        return 'Ácido Bórico/Ulexita'; // Oferecer opções comuns
      case 'Cu':
        return 'Sulfato de Cobre';
      case 'Fe':
        return 'Sulfato Ferroso'; // Raramente aplicado ao solo
      case 'Mn':
        return 'Sulfato de Manganês';
      case 'Zn':
        return 'Sulfato de Zinco';
      case 'Mo':
        return 'Molibdato de Sódio/Amônio';
      case 'Co':
        return 'Sulfato/Cloreto de Cobalto';
      default:
        return 'Fonte não definida';
    }
  }

  // --- _getFallbackDose ---
  // Manter a função de fallback, mas ela será menos utilizada agora
  double _getFallbackDose(String nutriente, TipoCultura cultura, double valorAnalise, double produtividade) {
    if (nutriente == 'P2O5') {
      return _getFallbackDoseP(cultura, valorAnalise, produtividade);
    } else if (nutriente == 'K2O') {
      // Implementar fallback para K2O se necessário (ex: usando tabelas genéricas)
      print('Fallback K2O não implementado.');
    } else if (nutriente == 'N') {
      // N não deve precisar de fallback se 'geral' for usado corretamente
      print('Fallback N não esperado.');
    }
    return 0.0; // Retorna 0 se não houver fallback definido
  }

  // --- _getFallbackDoseP ---
  // Manter a função de fallback para P
  double _getFallbackDoseP(TipoCultura cultura, double pValor, double produtividadeEsperada) {
    // ... (código de _getFallbackDoseP como na resposta anterior) ...
    // Implementação direta das tabelas do Boletim 100 como exemplo
    print('Usando fallback para P2O5 com base em tabelas genéricas.');
    if (cultura == TipoCultura.SOJA) {
      if (pValor < 16.0) { // Interpretação genérica Boletim 100
        if (produtividadeEsperada <= 3.0) return 120.0;
        if (produtividadeEsperada <= 4.0) return 140.0;
        return 160.0;
      } else if (pValor <= 40.0) { // Interpretação genérica Boletim 100
        if (produtividadeEsperada <= 3.0) return 80.0;
        if (produtividadeEsperada <= 4.0) return 100.0;
        return 120.0;
      } else { // Interpretação genérica Boletim 100
        if (produtividadeEsperada <= 3.0) return 30.0;
        if (produtividadeEsperada <= 4.0) return 40.0;
        return 60.0;
      }
    }
    // Adicionar fallbacks para outras culturas se necessário
    return 0.0;
  }

} // Fim da classe NutrienteCalculator