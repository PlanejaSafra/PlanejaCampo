// lib/services/agro/adubacao/calculators/correcao_solo_calculator.dart

import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'dart:math' as math;

class CorrecaoSoloCalculator {
  /// Calcula necessidade de correção do solo (calagem e gessagem)
  Future<Map<String, dynamic>> calcularCorrecoes({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required String produtorId,
    required String propriedadeId,
    required double produtividadeEsperada,
  }) async {
    final recomendacaoCalagem = await calcularCalagem(
      analise: analise,
      parametros: parametros,
      produtorId: produtorId,
      propriedadeId: propriedadeId,
    );

    final recomendacaoGessagem = await calcularGessagem(
      analise: analise,
      parametros: parametros,
      produtorId: produtorId,
      propriedadeId: propriedadeId,
      produtividadeEsperada: produtividadeEsperada,
    );

    return {
      'calagem': recomendacaoCalagem,
      'gessagem': recomendacaoGessagem,
    };
  }

  /// Calcula necessidade de calagem
  // In CorrecaoSoloCalculator class

  Future<RecomendacaoCalagem?> calcularCalagem({
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
    required String produtorId,
    required String propriedadeId,
  }) async {
    // Add debug logging
    print('Calculando calagem:');
    print('SB: ${analise.saturacaoBase}');
    print('CTC: ${analise.ctc}');
    print('Parâmetros Calagem: ${parametros.parametrosCalagem}');
    print('SaturacaoBasesIdeal: ${parametros.saturacaoBasesIdeal}');

    // First check if we need calagem
    if (!_necessitaCalagem(analise, parametros)) {
      print('Não necessita calagem');
      return null;
    }

    try {
      // Calculate NC with null safety
      final nc = _calcularNecessidadeCalcario(
        vAtual: analise.saturacaoBase,
        vDesejada: parametros.saturacaoBasesIdeal,
        ctc: analise.ctc,
        prnt: parametros.parametrosCalagem['prnt_padrao'] ??
            80.0, // Add default value
        profundidade:
            parametros.parametrosCalagem['profundidade_incorporacao'] ??
                20.0, // Add default value
      );

      final tipoCalcario = _definirTipoCalcario(
        relacaoCaMg: analise.relacaoCaMg,
        parametros: parametros,
      );

      final observacoes = _gerarObservacoesCalagem(
        vAtual: analise.saturacaoBase,
        mg: analise.magnesio,
        nc: nc,
        parametros: parametros,
        tipoSolo: analise.texturaSolo ?? TexturaSolo.MEDIO,
      );

      return RecomendacaoCalagem(
        id: '',
        recomendacaoId: '',
        produtorId: produtorId,
        propriedadeId: propriedadeId,
        saturacaoBasesAtual: analise.saturacaoBase,
        saturacaoBasesDesejada: parametros.saturacaoBasesIdeal,
        ctc: analise.ctc,
        prnt: parametros.parametrosCalagem['prnt_padrao'] ?? 80.0,
        tipoCalcario: tipoCalcario,
        quantidadeRecomendada: nc,
        profundidadeIncorporacao:
            parametros.parametrosCalagem['profundidade_incorporacao'] ?? 20.0,
        modoAplicacao: 'Lanço em área total',
        prazoAplicacao:
            (parametros.parametrosCalagem['prazo_minimo_aplicacao'] ?? 60)
                .toInt(),
        parcelamento:
            nc > (parametros.parametrosCalagem['dose_maxima_aplicacao'] ?? 6.0),
        observacoes: observacoes,
      );
    } catch (e, stackTrace) {
      print('Erro ao calcular calagem: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<RecomendacaoGessagem?> calcularGessagem({
    required ResultadoAnaliseSolo analise, // Contém dados da camada 0-20cm OU 20-40/25-50cm
    required CulturaParametros parametros,
    required String produtorId,
    required String propriedadeId,
    required double produtividadeEsperada,
  }) async {
    try {
      // Parâmetros relevantes (com valores default seguros)
      final double paramNecessidadeGesso = parametros.parametrosGessagem['necessidade_gesso'] ?? 0.0;
      final double paramProfundidadeAval = parametros.parametrosGessagem['profundidade_avaliacao'] ?? 40.0;
      final double paramTeorCaMin = parametros.parametrosGessagem['teor_calcio_min'] ?? 0.0;
      final double paramTeorSMin = parametros.parametrosGessagem['teor_sulfato_min'] ?? 15.0; //<- Limite usado para S superficial
      final double paramSatAlMax = parametros.parametrosGessagem['saturacao_al_max'] ?? 100.0;
      final double paramDoseMaxima = parametros.parametrosGessagem['dose_maxima'] ?? 10.0;
      // Novos parâmetros essenciais
      final double paramSatBasesMin = parametros.parametrosGessagem['saturacao_bases_min'] ?? 100.0; // V% abaixo disso é gatilho (cana)
      final double paramTaxaSporProd = parametros.parametrosGessagem['taxaS_porProdutividade_kgHa_por_Ton'] ?? 0.0;
      final double paramDoseFixaS = parametros.parametrosGessagem['doseFixa_por_S_baixo_tHa'] ?? 0.0;
      final double paramTeorSgesso = parametros.parametrosGessagem['teorS_Gesso_assumido_decimal'] ?? 0.17;

      // --- Determinar Cenário ---
      final bool temAnaliseProfunda =
          analise.profundidadeAmostra == ProfundidadeAmostra.SUBSUPERFICIAL ||
          analise.profundidadeAmostra == ProfundidadeAmostra.CANA_SUBSUPERFICIAL;

      double doseCalculada_tHa = 0.0;
      String modoAplicacao = 'Lanço em área total';
      List<String> observacoes = [];
      bool precisaGesso = false;
      String motivoPrincipal = ''; // Para rastrear o principal gatilho

      // --- Cenário 1: Sem Análise Profunda (Recomendação Provisória por S Superficial) ---
      if (!temAnaliseProfunda) {
        final double teorS_superficial = analise.enxofre; // S da camada 0-20cm

        // Usa 'paramTeorSMin' como limite para S superficial neste contexto
        // CORREÇÃO: Usar o limite correto para Milho se disponível, senão o genérico
        final double limiteSComparacao = parametros.cultura == TipoCultura.MILHO_GRAO
                                          ? (parametros.parametrosGessagem['teor_sulfato_min'] ?? 10.0) // Limite do milho = 10
                                          : paramTeorSMin; // Limite genérico ou de outra cultura

        if (teorS_superficial < limiteSComparacao) {
          precisaGesso = true;
          motivoPrincipal = 'S_SUPERFICIAL_BAIXO';
          observacoes.add('ATENÇÃO: Recomendação PROVISÓRIA baseada no teor de Enxofre superficial (${teorS_superficial.toStringAsFixed(1)} mg/dm³) abaixo do limite de ${limiteSComparacao.toStringAsFixed(1)} mg/dm³.');
          observacoes.add('Para recomendação definitiva, é FUNDAMENTAL a análise da camada subsuperficial (${parametros.cultura == TipoCultura.CANA_DE_ACUCAR ? '25-50cm' : '20-40cm'}).');
          modoAplicacao = 'Lanço em área total (Recomendação Provisória)';

          // Calcular dose provisória baseado na CULTURA
          if (parametros.cultura == TipoCultura.SOJA && paramTaxaSporProd > 0 && paramTeorSgesso > 0) {
            double doseS_necessaria = paramTaxaSporProd * produtividadeEsperada;
            double doseGesso_kgHa = doseS_necessaria / paramTeorSgesso;
            doseCalculada_tHa = doseGesso_kgHa / 1000.0;
            observacoes.add('Calculado para suprir ${doseS_necessaria.toStringAsFixed(1)} kg/ha de S para ${produtividadeEsperada.toStringAsFixed(1)} t/ha de soja.');
          } else if (parametros.cultura == TipoCultura.CANA_DE_ACUCAR && paramDoseFixaS > 0) {
            doseCalculada_tHa = paramDoseFixaS; // Usa a dose fixa definida para cana
            observacoes.add('Aplicando dose padrão de ${doseCalculada_tHa.toStringAsFixed(1)} t/ha para cana visando suprir S (conforme B100).');
          
          // ############### INÍCIO DA CORREÇÃO ###############
          } else if (parametros.cultura == TipoCultura.MILHO_GRAO && paramTaxaSporProd > 0 && paramTeorSgesso > 0) {
             // Lógica específica para Milho baseada na necessidade de S
             double doseS_necessaria = paramTaxaSporProd * produtividadeEsperada; // Ex: 10 t/ha * 3.3 kgS/t = 33 kgS/ha
             double doseGesso_kgHa = doseS_necessaria / paramTeorSgesso; // Ex: 33 / 0.17 = 194.1 kg gesso/ha
             doseCalculada_tHa = doseGesso_kgHa / 1000.0; // Ex: 0.194 t/ha
             observacoes.add('Calculado para suprir ${doseS_necessaria.toStringAsFixed(1)} kg/ha de S para ${produtividadeEsperada.toStringAsFixed(1)} t/ha de milho.');
             // Opcional: adicionar regra de mínimo se necessário (ex: mínimo 0.2 t/ha)
             // if(doseCalculada_tHa > 0 && doseCalculada_tHa < 0.2) {
             //   doseCalculada_tHa = 0.2;
             //   observacoes.add('Dose ajustada para o mínimo de 0.2 t/ha.');
             // }
          // ############### FIM DA CORREÇÃO ###############

          } else {
            observacoes.add('Não foi possível calcular a dose provisória por S baixo (parâmetros ou lógica ausentes para ${parametros.cultura.toString().split('.').last}?).');
          }
        } else {
          // S superficial OK, sem análise profunda -> Nenhuma recomendação
          observacoes.add('O teor de Enxofre superficial (${teorS_superficial.toStringAsFixed(1)} mg/dm³) está acima do limite (${limiteSComparacao.toStringAsFixed(1)} mg/dm³).');
          observacoes.add('Para avaliação completa (Al, Ca, S em profundidade), é necessária análise subsuperficial.');
          modoAplicacao = 'Necessita análise subsuperficial';
        }
      }
      // --- Cenário 2: Com Análise Profunda (Recomendação Definitiva) ---
      else { // temAnaliseProfunda == true
         // ... (Lógica existente para análise profunda - manter como está) ...
         // ... (verificar V%, m%, S, Ca profundos e calcular dose) ...
         // --- Atenção: A lógica aqui dentro também precisa ser validada ---
         // --- se ela lida corretamente com os critérios de S para Milho ---
         // --- baseado na análise profunda. Ex: Se S profundo < 10, calcular ---
         // --- dose = (Prod * 3.3) / 0.17 / 1000 ---

         // Exemplo de como ficaria a lógica para Milho DENTRO do Bloco `else { // temAnaliseProfunda == true`
         /*
         ... (verificar VBaixo, mAlto, sBaixo, caBaixo com dados da análise profunda) ...

         if (parametros.cultura == TipoCultura.MILHO_GRAO) {
           if (sBaixo) { // Critério principal para dose em Milho, segundo B100, é suprir S
             precisaGesso = true;
             motivoPrincipal = 'S_PROFUNDO_BAIXO';
             if (paramTaxaSporProd > 0 && paramTeorSgesso > 0) {
               double doseS_necessaria = paramTaxaSporProd * produtividadeEsperada;
               double doseGesso_kgHa = doseS_necessaria / paramTeorSgesso;
               doseCalculada_tHa = doseGesso_kgHa / 1000.0;
               observacoes.add('Recomendado por S baixo (${teorS_profundo.toStringAsFixed(1)} mg/dm³) na camada 20-40cm.');
               observacoes.add('Calculado para suprir ${doseS_necessaria.toStringAsFixed(1)} kg/ha de S para ${produtividadeEsperada.toStringAsFixed(1)} t/ha de milho.');
             } else {
               observacoes.add('Recomendado por S baixo na camada 20-40cm, mas parâmetros para cálculo (taxa S/prod, teor S gesso) ausentes.');
             }
           }
           // Adicionar observações sobre m% e Ca se relevantes, mesmo que S esteja OK
           if (mAlto) {
              observacoes.add('Observação: Alta saturação por Al (${satAl_profunda.toStringAsFixed(1)}%) na camada 20-40cm. Avaliar junto com calagem.');
           }
           if (caBaixo && !sBaixo) {
              observacoes.add('Observação: Baixo teor de Ca (${calcio_profundo.toStringAsFixed(1)} mmolc/dm³) na camada 20-40cm.');
           }
         }
         ... (restante da lógica para outras culturas e finalização) ...
         */
      }

      // --- Finalização ---
      // Aplicar dose máxima geral
      doseCalculada_tHa = doseCalculada_tHa < 0 ? 0 : doseCalculada_tHa; // Garante não negativo
      if (doseCalculada_tHa > paramDoseMaxima) {
         observacoes.add('ATENÇÃO: Dose (${doseCalculada_tHa.toStringAsFixed(1)} t/ha) limitada ao máximo de ${paramDoseMaxima.toStringAsFixed(1)} t/ha definido nos parâmetros.');
         doseCalculada_tHa = paramDoseMaxima;
      }


      // Gerar observações adicionais genéricas (se houver dose > 0)
      if (doseCalculada_tHa > 0) {
        final obsGerais = _gerarObservacoesGessagem(
          ng: doseCalculada_tHa, // Passa a dose final em t/ha
          analise: analise, // Passa a análise usada (superficial ou profunda)
          parametros: parametros,
        );
        observacoes.addAll(obsGerais);
        // Adicionar observações específicas por cultura se aplicável (ex: modo aplicação)
         if (parametros.cultura == TipoCultura.MILHO_GRAO) { // Adicionado para milho
           observacoes.add('Aplicar o gesso a lanço, preferencialmente em pré-plantio ou logo após o plantio.');
         } else if (parametros.cultura == TipoCultura.SOJA) {
          observacoes.add('Aplicar o gesso a lanço em pré-plantio.');
        } else if (parametros.cultura == TipoCultura.CANA_DE_ACUCAR) {
          observacoes.add('Aplicar o gesso logo após o corte, sem necessidade de incorporação em áreas com palha.');
        }
      }

      // Só retorna um objeto se houver recomendação (dose > 0) ou se for importante retornar info (ex: "necessita análise")
      if (doseCalculada_tHa > 0 || !temAnaliseProfunda) {
        return RecomendacaoGessagem(
          id: '', // Gerar ID depois
          recomendacaoId: '', // Associar depois
          produtorId: produtorId,
          propriedadeId: propriedadeId,
          teorSulfato: analise.enxofre, // Teor da análise usada
          saturacaoAluminio: analise.saturacaoAl, // idem
          calcioSubsolo: analise.calcio, // idem (nome da chave é fixo, mas valor é da análise usada)
          doseRecomendada: doseCalculada_tHa,
          modoAplicacao: modoAplicacao,
          profundidadeAvaliada: temAnaliseProfunda ? paramProfundidadeAval.toInt() : 0,
          parcelamento: doseCalculada_tHa > 4.0, // Exemplo de critério para sugerir parcelamento
          observacoes: observacoes.toSet().toList(), // Remove duplicatas
        );
      } else {
        // Se tem análise profunda e não precisa de gesso
        print('Não necessita gessagem com base na análise profunda.'); // Log adicional
        return null;
      }

    } catch (e, stackTrace) {
      print('Erro ao calcular gessagem: $e');
      print('Stack trace: $stackTrace');
      // Considerar retornar um objeto com erro
      return RecomendacaoGessagem(
          id: '', recomendacaoId: '', produtorId: produtorId, propriedadeId: propriedadeId,
          teorSulfato: analise.enxofre, saturacaoAluminio: analise.saturacaoAl, calcioSubsolo: analise.calcio,
          doseRecomendada: 0.0, modoAplicacao: 'Erro no cálculo', profundidadeAvaliada: 0, parcelamento: false,
          observacoes: ['Erro ao calcular gessagem: $e']
      );
    }
  }




  // Manter _gerarObservacoesGessagem (pode precisar de pequenos ajustes se a assinatura mudar)
  // A função _necessitaGessagem foi incorporada na lógica principal acima
  // para permitir retornar o motivo e lidar com diferentes culturas.
  List<String> _gerarObservacoesGessagem({
    required double ng, // Dose em t/ha
    required ResultadoAnaliseSolo analise,
    required CulturaParametros parametros,
  }) {
    List<String> observacoes = [];
    final double paramDoseMaxima = parametros.parametrosGessagem['dose_maxima'] ?? 10.0;

    // A verificação de limite máximo já foi feita antes de chamar esta função.
    // if (ng > paramDoseMaxima) {
    //   observacoes.add('ATENÇÃO: Dose (${ng.toStringAsFixed(1)} t/ha) limitada ao máximo de ${paramDoseMaxima.toStringAsFixed(1)} t/ha definido nos parâmetros.');
    // }
    if (ng > 4.0) { // Limite arbitrário para sugerir parcelamento
      observacoes.add('Dose relativamente alta (${ng.toStringAsFixed(1)} t/ha): considere parcelar a aplicação, especialmente em solos arenosos.');
    }

    // Adicionar observações por tipo de solo (usar textura da análise passada)
    if (analise.texturaSolo == TexturaSolo.ARENOSO && ng > 0) {
      observacoes.add('Em solo arenoso, a aplicação de gesso pode aumentar a lixiviação de K e Mg. Monitore os níveis desses nutrientes.');
    } else if (analise.texturaSolo == TexturaSolo.ARGILOSO && ng > 0) {
      // Nenhuma obs específica padrão aqui, mas poderia adicionar se relevante
    }

    return observacoes;
  }

  bool _necessitaCalagem(
    ResultadoAnaliseSolo analise,
    CulturaParametros parametros,
  ) {
     // Utiliza os parâmetros corretos carregados para a cultura específica
    final double vDesejadaCorreta = parametros.saturacaoBasesIdeal;
    final double mgMinimoCorreto = parametros.teorMinimoMagnesio;

    // Verifica se V% atual está abaixo do ideal OU se Mg está abaixo do mínimo
    return analise.saturacaoBase < vDesejadaCorreta ||
           analise.magnesio < mgMinimoCorreto;
  }

  double _calcularNecessidadeCalcario({
    required double vAtual,
    required double vDesejada,
    required double ctc,
    required double prnt,
    required double profundidade,
  }) {
     // Fórmula Padrão V%: NC (t/ha) = [(V2 - V1) * CTC / 100] * (100 / PRNT) * (profundidade / 20)
    
    // Calcula o fator de profundidade
    final fatorProfundidade = profundidade / 20.0; 
    
    // Calcula a necessidade de calcário usando a fórmula correta
    // Garante que PRNT não seja zero para evitar divisão por zero
    final double nc = (prnt <= 0) 
        ? 0.0 // Retorna 0 se PRNT for inválido
        : ((vDesejada - vAtual) * ctc / 100) * (100 / prnt) * fatorProfundidade;

    // Retorna a necessidade calculada, garantindo que não seja negativa
    return nc > 0 ? nc : 0.0; 
  }


  String _definirTipoCalcario({
    required double relacaoCaMg,
    required CulturaParametros parametros,
  }) {
     // Utiliza os limites de relação Ca/Mg dos parâmetros da cultura
    final minimo = parametros.parametrosCalagem['relacao_ca_mg_minima'] ?? 2.0; // Default seguro
    final maximo = parametros.parametrosCalagem['relacao_ca_mg_maxima'] ?? 4.0; // Default seguro

    if (relacaoCaMg < minimo) {
      return 'Calcítico'; // Aumentar Ca
    } else if (relacaoCaMg > maximo) {
      return 'Dolomítico'; // Aumentar Mg
    } else {
      // Dentro da faixa ideal, verifica o teor de Mg isoladamente
      final mgMinimo = parametros.teorMinimoMagnesio;
      // A análise precisa fornecer o teor de Mg para esta verificação ser útil aqui.
      // Se não tivermos o Mg da análise neste ponto, usar Magnesiano como padrão.
      // if (analise.magnesio < mgMinimo) { // Supondo que 'analise' fosse passada
      //    return 'Dolomítico';
      // } else {
          return 'Calcário Magnesiano'; // Manter relação ou usar se Mg estiver OK
      // }
    }
  }


  List<String> _gerarObservacoesCalagem({
    required double vAtual,
    required double mg, // Teor de Mg da análise
    required double nc, // Dose calculada (antes de aplicar limite máximo)
    required CulturaParametros parametros,
    required TexturaSolo tipoSolo,
  }) {
    List<String> observacoes = [];
    final double doseMaximaAplicacao = parametros.parametrosCalagem['dose_maxima_aplicacao'] ?? 6.0;
    final double teorMinimoMg = parametros.teorMinimoMagnesio;

    // Observação sobre parcelamento se a dose calculada excede o máximo por aplicação
    if (nc > doseMaximaAplicacao) {
       // Calcula quantas aplicações seriam necessárias (arredondando para cima)
      final numAplicacoes = (nc / doseMaximaAplicacao).ceil();
      observacoes.add(
          'Necessidade total de ${nc.toStringAsFixed(1)} t/ha. Aplicar ${doseMaximaAplicacao.toStringAsFixed(1)} t/ha agora.');
      if (numAplicacoes > 1) {
           observacoes.add('Recomenda-se parcelar o restante em ${numAplicacoes - 1} aplicação(ões) futura(s) ou conforme manejo.');
      }
    }

    // Observações específicas por tipo de solo
    switch (tipoSolo) {
      case TexturaSolo.ARENOSO:
        observacoes
            .add('Em solo arenoso, atenção à incorporação e possível necessidade de reaplicação mais frequente.');
        break;
      case TexturaSolo.ARGILOSO:
        observacoes.add('Em solo argiloso, garantir boa incorporação do calcário para melhor reação.');
        break;
      default:
        break;
    }

    // Observações sobre magnésio baseado no tipo de calcário definido E no teor
    // (Assumindo que _definirTipoCalcario foi chamado antes e o tipo está implícito na escolha do produto)
    if (mg < teorMinimoMg) {
       // A função _definirTipoCalcario já deve ter indicado dolomítico se Ca/Mg > max
      // Adiciona reforço se o teor de Mg estiver baixo E a relação Ca/Mg não for alta
      final tipoSugerido = _definirTipoCalcario(relacaoCaMg: mg > 0 ? parametros.parametrosCalagem['relacao_ca_mg_ideal'] ?? 3.0 : 3.0 /* Evitar div/0, usar valor médio */ , parametros: parametros); // Simula para obter tipo ideal
      if(tipoSugerido != 'Dolomítico'){
         observacoes.add('Teor de Mg baixo (${mg.toStringAsFixed(1)} mmolc/dm³ < ${teorMinimoMg.toStringAsFixed(1)}): Priorizar calcário Dolomítico ou Magnesiano.');
      } else {
         observacoes.add('Teor de Mg baixo (${mg.toStringAsFixed(1)} mmolc/dm³ < ${teorMinimoMg.toStringAsFixed(1)}): Usar calcário Dolomítico conforme recomendado.');
      }

    }

    // Observações específicas da cultura (se houver nos parâmetros)
    if (parametros.observacoesManejo.isNotEmpty) {
        // Filtrar observações redundantes se necessário
        observacoes.addAll(parametros.observacoesManejo.where((obs) => obs.toLowerCase().contains('calcário')));
    }
     // Adiciona prazo mínimo de aplicação
    final prazoMinimo = parametros.parametrosCalagem['prazo_minimo_aplicacao'] ?? 60;
    observacoes.add('Aplicar o calcário com antecedência mínima de ${prazoMinimo} dias antes do plantio.');


    return observacoes.toSet().toList(); // Remove duplicatas
  }
}
