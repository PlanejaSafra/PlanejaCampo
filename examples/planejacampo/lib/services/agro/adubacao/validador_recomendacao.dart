// lib/services/agro/adubacao/validators/validador_recomendacao.dart

import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/enums.dart';
import 'dart:math' as Math;

class ValidadorRecomendacao {
  Map<String, dynamic> validarRecomendacao({
    required Recomendacao recomendacao,
    required Map<String, RecomendacaoNutriente> nutrientes,
    required CulturaParametros parametros,
    RecomendacaoCalagem? calagem,
    RecomendacaoGessagem? gessagem,
  }) {
    List<String> erros = [];
    List<String> avisos = [];

    // Validar potássio se presente nos nutrientes
    if (nutrientes.containsKey('K2O')) {
      _validarPotassio(
          nutrientes['K2O']!,
          parametros,          // Passando os parâmetros da cultura
          recomendacao.texturaSolo,
          avisos
      );
    } else if (recomendacao.tipoCultura != TipoCultura.CANA_DE_ACUCAR) {
      // Para culturas que não são cana, K2O sempre deve estar presente
      erros.add('Recomendação de K2O não encontrada');
    }


    // 1. Validações básicas
    _validarProdutividade(
      recomendacao.produtividadeEsperada,
      parametros,
      erros,
      avisos,
    );

    // 2. Validar correções do solo
    if (calagem != null) {
      _validarCalagem(calagem, parametros, erros, avisos);
    }

    if (gessagem != null) {
      _validarGessagem(gessagem, parametros, erros, avisos);
    }

    // 3. Validar recomendações de nutrientes
    _validarNutrientes(nutrientes, parametros, erros, avisos);

    // 4. Validar interações entre nutrientes
    _validarInteracoesNutrientes(nutrientes, erros, avisos);

    // 5. Validar épocas de aplicação
    _validarEpocasAplicacao(
      recomendacao.dataPlantio,
      nutrientes,
      parametros,
      erros,
      avisos,
    );

    return {
      'valido': erros.isEmpty,
      'erros': erros,
      'avisos': avisos,
    };
  }

  void _validarProdutividade(
      double produtividadeEsperada,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    if (produtividadeEsperada < parametros.produtividadeMinima) {
      erros.add(
          'Produtividade esperada (${produtividadeEsperada.toStringAsFixed(1)}) abaixo do mínimo recomendado (${parametros.produtividadeMinima.toStringAsFixed(1)})'
      );
    }

    if (produtividadeEsperada > parametros.produtividadeMaxima) {
      avisos.add(
          'Produtividade esperada muito alta - verificar condições de cultivo e histórico da área'
      );
    }
  }

  void _validarCalagem(
      RecomendacaoCalagem calagem,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    // Validar dose máxima
    double doseMaxima = parametros.parametrosCalagem['dose_maxima_aplicacao']!;
    if (calagem.quantidadeRecomendada > doseMaxima) {
      erros.add(
          'Dose de calcário (${calagem.quantidadeRecomendada.toStringAsFixed(1)} t/ha) excede o máximo recomendado ($doseMaxima t/ha)'
      );
    }

    // Validar PRNT
    double prntMinimo = 70.0; // Valor padrão mínimo
    if (calagem.prnt < prntMinimo) {
      avisos.add('PRNT do calcário abaixo do recomendado');
    }

    // Validar profundidade
    double profundidadeMinima = parametros.parametrosCalagem['profundidade_minima']!;
    if (calagem.profundidadeIncorporacao < profundidadeMinima) {
      erros.add('Profundidade de incorporação insuficiente');
    }

    // Validar parcelamento
    if (calagem.quantidadeRecomendada > 5.0 && !calagem.parcelamento) {
      avisos.add('Recomenda-se parcelar doses de calcário acima de 5 t/ha');
    }
  }

  void _validarGessagem(
      RecomendacaoGessagem gessagem,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    // Validar dose máxima
    double doseMaxima = parametros.parametrosGessagem['dose_maxima']!;
    if (gessagem.doseRecomendada > doseMaxima) {
      erros.add(
          'Dose de gesso (${gessagem.doseRecomendada.toStringAsFixed(1)} t/ha) excede o máximo recomendado ($doseMaxima t/ha)'
      );
    }

    // Validar necessidade real
    double satAlMaxima = parametros.parametrosGessagem['saturacao_al_max']!;
    double terorCalcioMin = parametros.parametrosGessagem['teor_calcio_min']!;

    if (gessagem.doseRecomendada > 0 &&
        gessagem.saturacaoAluminio < satAlMaxima &&
        gessagem.calcioSubsolo > terorCalcioMin) {
      avisos.add('Verificar real necessidade de gessagem');
    }

    // Validar parcelamento
    if (gessagem.doseRecomendada > 4.0 && !gessagem.parcelamento) {
      avisos.add('Recomenda-se parcelar doses de gesso acima de 4 t/ha');
    }
  }

  void _validarNutrientes(
      Map<String, RecomendacaoNutriente> nutrientes,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    for (var entry in nutrientes.entries) {
      final nutriente = entry.key;
      final recomendacao = entry.value;

      // 1. Validar limites máximos
      final limiteMaximo = parametros.limitesMaximosNutrientes[nutriente];
      if (limiteMaximo != null && recomendacao.doseRecomendada > limiteMaximo) {
        erros.add(
            'Dose de $nutriente (${recomendacao.doseRecomendada.toStringAsFixed(1)}) excede o limite máximo seguro ($limiteMaximo)'
        );
      }

      // 2. Validar doses no sulco
      final limiteMaximoSulco = parametros.limitesMaximosSulco[nutriente];
      if (limiteMaximoSulco != null &&
          recomendacao.doseRecomendada > limiteMaximoSulco &&
          recomendacao.fonte?.toLowerCase().contains('sulco') == true) {
        erros.add(
            'Dose de $nutriente no sulco excede o limite recomendado'
        );
      }

      // 3. Validar fontes
      if (recomendacao.fonte != null) {
        final fontesPermitidas = parametros.fontesNutrientes[nutriente];
        if (fontesPermitidas != null &&
            !fontesPermitidas.contains(recomendacao.fonte)) {
          avisos.add('Fonte de $nutriente pode não ser a mais adequada');
        }
      }

      // 4. Validações específicas por nutriente
      _validarNutrienteEspecifico(
        nutriente,
        recomendacao,
        parametros,
        erros,
        avisos,
      );
    }
  }

  void _validarNutrienteEspecifico(
      String nutriente,
      RecomendacaoNutriente recomendacao,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    switch (nutriente) {
      case 'N':
        if (parametros.cultura.toString().contains('SOJA') &&
            recomendacao.doseRecomendada > 0) {
          erros.add('Não recomendado N mineral para soja - usar FBN');
        }
        if (recomendacao.doseRecomendada > 100 &&
            !recomendacao.observacoes.any((obs) => obs.contains('parcelar'))) {
          avisos.add('Doses de N acima de 100 kg/ha devem ser parceladas');
        }
        break;

      case 'P2O5':
        if (recomendacao.teor < parametros.teoresCriticosMacro['P2O5']!['muito_baixo']! &&
            recomendacao.doseRecomendada > 120) {
          avisos.add('Alto investimento em P em solo muito pobre - verificar viabilidade');
        }
        break;

      case 'K2O':
        if (recomendacao.doseRecomendada > 60 &&
            !recomendacao.observacoes.any((obs) => obs.contains('cobertura'))) {
          avisos.add('Doses altas de K devem ter parte aplicada em cobertura');
        }
        break;

    // Micronutrientes
      case 'B':
      case 'Zn':
      case 'Cu':
      case 'Mn':
      case 'Mo':
        if (recomendacao.doseRecomendada > 0 &&
            !parametros.fontesNutrientes.containsKey(nutriente)) {
          avisos.add('Definir fonte específica para $nutriente');
        }
        break;
    }
  }

  void _validarInteracoesNutrientes(
      Map<String, RecomendacaoNutriente> nutrientes,
      List<String> erros,
      List<String> avisos,
      ) {
    // 1. Interação N x K
    if (nutrientes.containsKey('N') && nutrientes.containsKey('K2O')) {
      final relacaoNK = nutrientes['N']!.doseRecomendada /
          nutrientes['K2O']!.doseRecomendada;

      if (relacaoNK > 3) {
        avisos.add('Alta relação N/K pode prejudicar absorção de potássio');
      }
    }

    // 2. Soma N + K2O no sulco
    if (nutrientes.containsKey('N') && nutrientes.containsKey('K2O')) {
      // Considerar apenas a dose de K2O no sulco (máx 60 kg/ha)
      final doseKSulco = Math.min(nutrientes['K2O']!.doseRecomendada, 60.0);
      final somaNK = nutrientes['N']!.doseRecomendada + doseKSulco;

      if (somaNK > 120) {
        erros.add('Soma N + K2O muito elevada para aplicação no sulco');
      }
    }

    // 3. Interações com micronutrientes
    if (nutrientes.containsKey('Zn') && nutrientes.containsKey('P2O5')) {
      final relacaoPZn = nutrientes['P2O5']!.doseRecomendada /
          nutrientes['Zn']!.doseRecomendada;

      if (relacaoPZn > 500) {
        avisos.add('Alta relação P/Zn pode induzir deficiência de zinco');
      }
    }
  }

  void _validarEpocasAplicacao(
      DateTime dataPlantio,
      Map<String, RecomendacaoNutriente> nutrientes,
      CulturaParametros parametros,
      List<String> erros,
      List<String> avisos,
      ) {
    final epoca = _calcularEpocaAplicacao(dataPlantio, DateTime.now());

    for (var entry in nutrientes.entries) {
      final nutriente = entry.key;
      final recomendacao = entry.value;

      // Verifica se existem épocas definidas para o nutriente
      final epocasPermitidas = parametros.epocasAplicacao
          .entries
          .where((e) => e.key.startsWith(nutriente))
          .map((e) => e.value);

      if (epocasPermitidas.isEmpty) {
        continue; // Se não há épocas definidas, não validar
      }

      // Verifica se a época atual está entre as permitidas
      final epocaPermitida = epocasPermitidas.any((e) =>
      e.dias >= _diasAposPlantio(dataPlantio, DateTime.now()));

      if (!epocaPermitida) {
        erros.add('Época inadequada para aplicação de $nutriente');
      }

      // Verifica limites máximos no sulco/plantio se aplicável
      if (epoca == 'plantio') {
        final limiteMaximoSulco = parametros.limitesMaximosSulco[nutriente];
        if (limiteMaximoSulco != null && recomendacao.doseRecomendada > limiteMaximoSulco) {
          erros.add('Dose de $nutriente excede o limite máximo permitido no sulco (${limiteMaximoSulco} kg/ha)');
        }
      }

      // Verifica necessidade de parcelamento baseado nos limites definidos
      final limiteParcelamento = parametros.limitesMaximosNutrientes[nutriente];
      if (limiteParcelamento != null && recomendacao.doseRecomendada > limiteParcelamento) {
        avisos.add('Considerar parcelamento para dose de $nutriente');
      }
    }
  }

  int _diasAposPlantio(DateTime dataPlantio, DateTime dataAtual) {
    return dataAtual.difference(dataPlantio).inDays;
  }

  String _calcularEpocaAplicacao(DateTime dataPlantio, DateTime dataAplicacao) {
    final dias = _diasAposPlantio(dataPlantio, dataAplicacao);

    if (dias <= 0) return 'plantio';
    if (dias <= 30) return 'inicial';
    if (dias <= 60) return 'desenvolvimento';
    return 'tardia';
  }

  void _validarPotassio(
      RecomendacaoNutriente recomendacao,
      CulturaParametros parametros,
      TexturaSolo texturaSolo,
      List<String> avisos) {

    // Obter limite de K₂O no sulco a partir dos parâmetros da cultura
    final limiteK2OSulco = parametros.limitesMaximosSulco['K2O'];

    // Validar limite máximo para aplicação no sulco (se definido)
    if (limiteK2OSulco != null && recomendacao.doseRecomendada > limiteK2OSulco) {
      avisos.add('Dose de K2O excede o limite para aplicação no sulco');
    }

    // Validação específica para solos arenosos
    if (texturaSolo == TexturaSolo.ARENOSO && limiteK2OSulco != null) {
      avisos.add('Em solo arenoso, doses de K2O acima de $limiteK2OSulco kg/ha devem ser parceladas');
    }

    // Obter teores críticos específicos da cultura
    final teoresCriticosK = parametros.teoresCriticosMacro['K2O'];

    if (teoresCriticosK != null) {
      // Encontrar o teor baixo apropriado para a cultura
      final teorBaixo = teoresCriticosK['baixo'] ?? teoresCriticosK['muito_baixo'];

      // Determinar limite dinâmico para recomendação de pré-plantio
      final limitePrePlantio = limiteK2OSulco ??
          (parametros.limitesMaximosNutrientes['K2O'] != null ?
          parametros.limitesMaximosNutrientes['K2O']! * 0.45 :
          recomendacao.doseRecomendada * 0.5);

      if (teorBaixo != null && recomendacao.teor < teorBaixo && recomendacao.doseRecomendada >= limitePrePlantio) {
        avisos.add('Com teor baixo de K (< $teorBaixo) e dose ≥ ${limitePrePlantio.toStringAsFixed(0)} kg/ha, considerar transferir parte ou toda adubação para pré-plantio a lanço');
      }

      // Encontrar o teor alto apropriado para a cultura
      final teorAlto = teoresCriticosK['alto'] ?? teoresCriticosK['adequado'];

      if (teorAlto != null && recomendacao.teor > teorAlto) {
        avisos.add('Teor de K no solo já adequado, reavaliar necessidade de adubação potássica');
      }
    }

    // Adicionar restrições específicas da cultura relacionadas a potássio
    for (final restricao in parametros.restricoesAplicacao) {
      if (restricao.toLowerCase().contains('k2o') ||
          restricao.toLowerCase().contains('potássi') ||
          restricao.toLowerCase().contains('potassio')) {

        // Evita adicionar mensagens duplicadas
        if (!avisos.any((aviso) => aviso.toLowerCase() == restricao.toLowerCase())) {
          avisos.add(restricao);
        }
      }
    }
  }
}