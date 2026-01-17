// V03

import 'dart:math' as Math;
import 'package:planejacampo/models/agro/adubacao/aplicacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/epoca_aplicacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/enums.dart';
// Remover import de EpocaAplicacaoDetalhada, pois não será usada nesta versão.

class AjustesDosesCalculator {

  /// Aplica ajustes sequenciais à dose base de um nutriente.
  double ajustarDose({
    required double doseBase,
    required CulturaParametros parametros,
    required TexturaSolo texturaSolo,
    required double materiaOrganica, // Assumir unidade consistente com parâmetros (ex: g/kg)
    required bool irrigado,
    required String nutriente, // Nutriente é obrigatório para ajustes direcionados
  }) {
    double dose = doseBase;

    // 1. Ajuste por textura (se definido para o nutriente)
    dose = _ajustarPorTextura(
      dose: dose,
      texturaSolo: texturaSolo,
      parametros: parametros,
      nutriente: nutriente,
    );

    // 2. Ajuste por matéria orgânica (geralmente só para N)
    dose = _ajustarPorMO(
      dose: dose,
      mo: materiaOrganica,
      parametros: parametros,
      nutriente: nutriente,
    );

    // 3. Ajuste por irrigação (se definido para o nutriente)
    dose = _ajustarPorIrrigacao(
      dose: dose,
      irrigado: irrigado,
      parametros: parametros,
      nutriente: nutriente,
    );

    return Math.max(0.0, dose); // Garante dose não negativa
  }

  /// Ajusta a dose com base na textura do solo, usando fatores dos parâmetros.
  double _ajustarPorTextura({
    required double dose,
    required TexturaSolo texturaSolo,
    required CulturaParametros parametros,
    required String nutriente,
  }) {
    final fatoresTexturaGeral = parametros.fatorAjusteDoses['textura'];

    if (nutriente == 'N' || fatoresTexturaGeral == null || fatoresTexturaGeral.isEmpty) {
      return dose;
    }

    String chaveTextura = texturaSolo.toString().split('.').last.toLowerCase();
    double fator = fatoresTexturaGeral[chaveTextura] ?? 1.0;

    // TODO: Considerar futuramente fatores de textura específicos por nutriente em CulturaParametros.
    return dose * fator;
  }

  /// Ajusta a dose com base na matéria orgânica, principalmente para N.
  double _ajustarPorMO({
    required double dose,
    required double mo,
    required CulturaParametros parametros,
    required String nutriente,
  }) {
    if (nutriente != 'N') {
      return dose;
    }

    final fatoresMO = parametros.fatorAjusteDoses['materia_organica'];
    if (fatoresMO == null || fatoresMO.isEmpty) {
      return dose;
    }

    // TODO: Idealmente, ler limites de MO ('baixo', 'medio') de CulturaParametros.
    // Usando limites fixos por enquanto:
    final double limiteBaixo = 20.0;
    final double limiteMedio = 40.0; // Limite superior da faixa 'média'

    String interpretacaoMO;
    if (mo < limiteBaixo) {
      interpretacaoMO = 'baixo';
    } else if (mo < limiteMedio) {
      interpretacaoMO = 'medio';
    } else {
      interpretacaoMO = 'alto';
    }

    double fator = fatoresMO[interpretacaoMO] ?? 1.0;
    return dose * fator;
  }

  /// Ajusta a dose com base na condição de irrigação, usando fatores dos parâmetros.
  double _ajustarPorIrrigacao({
    required double dose,
    required bool irrigado,
    required CulturaParametros parametros,
    required String nutriente,
  }) {
    if (!irrigado) {
      return dose;
    }

    final fatoresIrrigacao = parametros.fatorAjusteDoses['irrigacao'];
    if (fatoresIrrigacao == null || fatoresIrrigacao.isEmpty) {
      return dose;
    }

    double fator = fatoresIrrigacao[nutriente] ?? fatoresIrrigacao['padrao'] ?? 1.0;
    return dose * fator;
  }

  // --- Geração de Observações e Restrições ---

  /// Gera observações de manejo com base nas condições e doses ajustadas.
  List<String> gerarObservacoesAjuste({
    required TexturaSolo texturaSolo,
    required double materiaOrganica,
    required bool irrigado,
    required Map<String, double> dosesAjustadas,
    required CulturaParametros parametros,
  }) {
    List<String> observacoes = [];

    // TODO: Idealmente, ler limites de MO de CulturaParametros.
    final double limiteBaixoMO = 20.0;
    final double limiteMedioMO = 40.0;

    // TODO: Idealmente, ler doses que disparam observações de CulturaParametros.
    final double doseMinParcelarK = parametros.limitesMaximosSulco['K2O'] ?? 60.0; // Usa limite do sulco como gatilho
    final double doseMinParcelarN = 60.0; // Limite fixo por enquanto
    final double doseDispararObsPArgiloso = 100.0; // Limite fixo por enquanto

    // Observações relacionadas à textura
    if (texturaSolo == TexturaSolo.ARENOSO) {
      double? doseK = dosesAjustadas['K2O'];
      if (doseK != null && doseK > doseMinParcelarK) {
        observacoes.add('Solo arenoso: Recomenda-se parcelar K2O (acima de ${doseMinParcelarK.toStringAsFixed(0)} kg/ha) para reduzir perdas por lixiviação.');
      }
      // Outras obs para arenoso...
    } else if (texturaSolo == TexturaSolo.ARGILOSO) {
      double? doseP = dosesAjustadas['P2O5'];
      if (doseP != null && doseP > doseDispararObsPArgiloso) {
        observacoes.add('Solo argiloso: Para doses altas de P2O5 (> ${doseDispararObsPArgiloso.toStringAsFixed(0)} kg/ha), preferir aplicação localizada para reduzir fixação.');
      }
    }

    // Observações relacionadas à MO
    if (materiaOrganica < limiteBaixoMO) {
      observacoes.add('Baixo teor de MO (< ${limiteBaixoMO.toStringAsFixed(1)}) - Potencial de maior resposta à adubação N.');
    } else if (materiaOrganica > limiteMedioMO) {
      observacoes.add('Alto teor de MO (> ${limiteMedioMO.toStringAsFixed(1)}) - Considerar contribuição de N da mineralização, especialmente para adubações de cobertura.');
    }

    // Observações para área irrigada / parcelamento N
    double? doseN = dosesAjustadas['N'];
    if (irrigado) {
      observacoes.add('Área irrigada: Avaliar parcelamento da adubação (especialmente N e K) em mais aplicações.');
      if (doseN != null && doseN > doseMinParcelarN) { // Usando limite fixo 60
        observacoes.add('Área irrigada: Para doses de N > ${doseMinParcelarN.toStringAsFixed(0)} kg/ha, parcelar em 3 ou mais aplicações.');
      }
    } else {
      if (parametros.permiteParcelamentoN && doseN != null && doseN > doseMinParcelarN) {
        observacoes.add('Sequeiro: Para doses de N > ${doseMinParcelarN.toStringAsFixed(0)} kg/ha, recomenda-se parcelar em 2 ou mais aplicações (ex: plantio e cobertura).');
      }
    }

    return observacoes;
  }

  /// Gera restrições de aplicação (mensagens mais fortes) com base nas doses e parâmetros.
  List<String> gerarRestricoesAjuste({
    required Map<String, double> dosesAjustadas,
    required CulturaParametros parametros,
    required TexturaSolo texturaSolo, // Pode ser útil para restrições específicas
  }) {
    List<String> restricoes = [];

    // Restrição de K2O no sulco
    double? limiteSulcoK = parametros.limitesMaximosSulco['K2O'];
    if (limiteSulcoK != null) {
      restricoes.add('Restrição: Não aplicar mais de ${limiteSulcoK.toStringAsFixed(0)} kg/ha de K2O no sulco de plantio/semeadura.');
      // Verifica se a dose total EXIGE aplicação fora do sulco
      double? doseK = dosesAjustadas['K2O'];
      if (doseK != null && doseK > limiteSulcoK) {
        restricoes.add('ATENÇÃO: Dose total de K2O (${doseK.toStringAsFixed(1)}) excede o limite do sulco (${limiteSulcoK.toStringAsFixed(0)}). É OBRIGATÓRIO aplicar o excedente em cobertura ou pré-plantio.');
      }
    }

    // Exemplo de outra restrição (se parametrizado)
    // double? limiteNAplicacao = parametros.limiteMaximoNAplicacaoUnica; // Campo hipotético
    // double? doseN = dosesAjustadas['N'];
    // if (limiteNAplicacao != null && doseN != null && doseN > limiteNAplicacao) {
    //   restricoes.add('Restrição: Dose total de N (${doseN.toStringAsFixed(1)}) excede o limite por aplicação (${limiteNAplicacao.toStringAsFixed(0)}). Parcelamento obrigatório.');
    // }

    return restricoes;
  }

  // --- Cálculo de Parcelamento (Simplificado) ---

  /// Calcula o parcelamento das doses ajustadas de forma simplificada.
  /// A lógica detalhada deveria vir dos parâmetros (estrutura EpocaAplicacaoDetalhada).
  Map<String, Map<String, double>> _calcularParcelamento({
    required Map<String, double> dosesAjustadas,
    required CulturaParametros parametros,
    required TexturaSolo texturaSolo,
    required bool irrigado,
  }) {
    Map<String, Map<String, double>> parcelamentoFinal = {};

    dosesAjustadas.forEach((nutriente, doseTotal) {
      if (doseTotal <= 0) {
        parcelamentoFinal[nutriente] = {};
        return;
      }

      // Lógica simplificada de parcelamento aqui
      parcelamentoFinal[nutriente] = _calcularParcelamentoSimplificado(
        dose: doseTotal,
        nutriente: nutriente,
        texturaSolo: texturaSolo,
        irrigado: irrigado,
        parametros: parametros,
      );
    });

    return parcelamentoFinal;
  }

  /// Lógica de parcelamento SIMPLIFICADA baseada nos parâmetros atuais.
  /// O ideal seria usar uma estrutura detalhada em CulturaParametros.
  /// Lógica de parcelamento que utiliza exclusivamente os parâmetros do manual
  Map<String, double> _calcularParcelamentoSimplificado({
    required double dose,
    required String nutriente,
    required TexturaSolo texturaSolo,
    required bool irrigado,
    required CulturaParametros parametros,
  }) {
    Map<String, double> parcelas = {};
    if (dose <= 0) return parcelas;

    // 1. EXTRAIR CHAVES DE ÉPOCAS DE APLICAÇÃO DO MANUAL
    Map<String, String> chavesPorFase = {}; // mapeia 'plantio', 'cobertura1', etc para chaves do manual
    Map<String, EpocaAplicacao> epocaPorFase = {}; // guarda objeto completo por fase
    List<String> fasesOrdenadas = []; // mantém a ordem de processamento das fases

    // Simplificar para buscar nutriente principal
    String nutrientePrincipal = nutriente;
    if (nutriente == 'P2O5') nutrientePrincipal = 'P';
    if (nutriente == 'K2O') nutrientePrincipal = 'K';

    // Procurar chaves para cada fase nos parâmetros
    for (var entry in parametros.epocasAplicacao.entries) {
      String chave = entry.key;
      EpocaAplicacao epoca = entry.value;

      // Verificar se a chave é relevante para este nutriente
      if (chave.startsWith('${nutrientePrincipal}_') || chave.startsWith(nutriente)) {
        String fase = '';

        // Identificar fase baseado na chave
        if (chave.contains('PLANT') || chave.contains('_PLANT')) {
          fase = 'plantio';
        } else if (chave.contains('PRE') || chave.contains('_PRE')) {
          fase = 'pre_plantio';
        } else if (chave.contains('COB1') || (chave.contains('_COB') && !chave.contains('COB2'))) {
          fase = 'cobertura1';
        } else if (chave.contains('COB2')) {
          fase = 'cobertura2';
        } else if (chave.contains('COB3')) {
          fase = 'cobertura3';
        }

        if (fase.isNotEmpty) {
          chavesPorFase[fase] = chave;
          epocaPorFase[fase] = epoca;

          // Adicionar à lista de fases, seguindo ordem de prioridade
          if (!fasesOrdenadas.contains(fase)) {
            fasesOrdenadas.add(fase);
          }
        }
      }
    }

    // Ordenar fases por prioridade (pré-plantio -> plantio -> coberturas)
    fasesOrdenadas.sort((a, b) {
      int prioridadeA = epocaPorFase[a]?.prioridade ?? _getPrioridadePadrao(a);
      int prioridadeB = epocaPorFase[b]?.prioridade ?? _getPrioridadePadrao(b);
      return prioridadeA.compareTo(prioridadeB);
    });

    // 2. VERIFICAR PERCENTUAIS PRÉ-DEFINIDOS
    bool temPercentuaisDefinidos = false;
    double somaPercentuais = 0.0;

    // Verificar se todas as fases têm percentuais definidos
    if (fasesOrdenadas.isNotEmpty) {
      temPercentuaisDefinidos = true;
      for (var fase in fasesOrdenadas) {
        if (epocaPorFase[fase]?.percentualDose == null) {
          temPercentuaisDefinidos = false;
          break;
        } else {
          somaPercentuais += epocaPorFase[fase]!.percentualDose!;
        }
      }
    }

    // 3. APLICAR PERCENTUAIS PRÉ-DEFINIDOS SE DISPONÍVEIS
    if (temPercentuaisDefinidos && (somaPercentuais - 100.0).abs() < 2.0) {
      // Usar percentuais pré-definidos no parâmetro
      for (var fase in fasesOrdenadas) {
        String chave = chavesPorFase[fase]!;
        double percentual = epocaPorFase[fase]!.percentualDose!;
        parcelas[chave] = (percentual / 100.0) * dose;
      }
      return parcelas;
    }

    // 4. VERIFICAR CONDIÇÕES PARA APLICAÇÃO TOTAL EM PRÉ-PLANTIO
    if (chavesPorFase.containsKey('pre_plantio')) {
      String chavePrePlantio = chavesPorFase['pre_plantio']!;
      EpocaAplicacao epocaPrePlantio = epocaPorFase['pre_plantio']!;

      // Verificar regras específicas para pré-plantio (ex: K baixo, dose alta)
      bool usarPrePlantio = false;

      if (nutriente == 'K2O') {
        // Verificar condição para K em pré-plantio (teor baixo, dose alta)
        double limiteTeorK = parametros.teoresCriticosMacro['K2O']?['baixo'] ?? 1.6;
        double limiteDoseK = 80.0; // Valor típico para transferir para pré-plantio

        if (texturaSolo == TexturaSolo.ARGILOSO && dose >= limiteDoseK) {
          usarPrePlantio = true;
        }
      }

      if (usarPrePlantio && epocaPrePlantio.aplicacaoPrincipal == false) {
        parcelas[chavePrePlantio] = dose;
        return parcelas;
      }
    }

    // 5. VERIFICAR SE APLICA TUDO NO PLANTIO
    if (chavesPorFase.containsKey('plantio')) {
      String chavePlantio = chavesPorFase['plantio']!;
      EpocaAplicacao epocaPlantio = epocaPorFase['plantio']!;

      // Verificar se aplica 100% no plantio baseado em:
      // - percentualDose definido como 100%
      // - nutriente que sempre vai 100% no plantio (P2O5)
      // - quando a dose é menor que o limite
      if (epocaPlantio.percentualDose == 100.0 ||
          nutriente == 'P2O5' ||
          (epocaPlantio.limiteMaximo != null && dose <= epocaPlantio.limiteMaximo!)) {
        parcelas[chavePlantio] = dose;
        return parcelas;
      }

      // 6. CALCULAR PARCELAMENTO
      // Obter limite máximo para aplicação no plantio
      double limiteNoPlantio = epocaPlantio.limiteMaximo ??
          parametros.limitesMaximosSulco[nutriente] ??
          dose;

      // Aplicar valor no plantio, limitado pelo máximo permitido
      double doseNoPlantio = Math.min(dose, limiteNoPlantio);
      parcelas[chavePlantio] = doseNoPlantio;

      // Calcular excedente que precisa ser aplicado em outras fases
      double excedente = dose - doseNoPlantio;

      // Se não houver excedente significativo, finalizar
      if (excedente <= 0.5) {
        return parcelas;
      }

      // 7. DISTRIBUIR EXCEDENTE NAS COBERTURAS
      // Identificar fases de cobertura disponíveis
      List<String> fasesCobertura = fasesOrdenadas
          .where((fase) => fase.contains('cobertura'))
          .toList();

      if (fasesCobertura.isEmpty) {
        // Sem fases de cobertura definidas, adicionar no plantio mesmo
        parcelas[chavePlantio] = (parcelas[chavePlantio] ?? 0.0) + excedente;
        return parcelas;
      }

      // Determinar número de coberturas baseado nas condições específicas
      int numCoberturas = fasesCobertura.length;

      // Regras específicas por nutriente para número de coberturas
      if (nutriente == 'N') {
        if (excedente > 100 && irrigado) {
          numCoberturas = Math.min(3, numCoberturas > 0 ? numCoberturas : 3);
        } else if (excedente > 80) {
          numCoberturas = Math.min(2, numCoberturas > 0 ? numCoberturas : 2);
        }
      } else if (nutriente == 'K2O') {
        if (texturaSolo == TexturaSolo.ARENOSO) {
          numCoberturas = Math.min(2, numCoberturas > 0 ? numCoberturas : 2);
        }
      }

      // Limitar ao número de chaves disponíveis
      numCoberturas = Math.min(numCoberturas, fasesCobertura.length);

      // Distribuir o excedente igualmente entre as coberturas
      double dosePorCobertura = excedente / numCoberturas;

      for (int i = 0; i < numCoberturas; i++) {
        String fase = fasesCobertura[i];
        String chaveCobertura = chavesPorFase[fase]!;
        parcelas[chaveCobertura] = dosePorCobertura;
      }
    }

    // 8. VALIDAÇÃO FINAL
    // Verificar se a soma está correta e ajustar se necessário
    double somaParcelas = parcelas.values.fold(0.0, (sum, v) => sum + v);
    if ((somaParcelas - dose).abs() > 0.1 && parcelas.isNotEmpty) {
      String ultimaChave = parcelas.keys.last;
      double diferenca = dose - somaParcelas;
      parcelas[ultimaChave] = (parcelas[ultimaChave] ?? 0) + diferenca;
    }

    // Remover parcelas insignificantes
    parcelas.removeWhere((key, value) => value < 0.5);

    return parcelas;
  }

// Método auxiliar para prioridade padrão por fase
  int _getPrioridadePadrao(String fase) {
    if (fase == 'pre_plantio') return 0;
    if (fase == 'plantio') return 1;
    if (fase == 'cobertura1') return 2;
    if (fase == 'cobertura2') return 3;
    if (fase == 'cobertura3') return 4;
    return 999;
  }

  // Melhorar o método de cálculo de parcelamento
  /// Lógica de parcelamento MELHORADA que utiliza exclusivamente os parâmetros do manual
  /// Lógica de parcelamento que utiliza exclusivamente os parâmetros do manual
  // Dentro da classe AjustesDosesCalculator

  /// Lógica de parcelamento MELHORADA que utiliza exclusivamente os parâmetros do manual
  /// Lógica de parcelamento que utiliza exclusivamente os parâmetros do manual
  Map<String, double> _calcularParcelamentoNutriente({
    required double dose,
    required String nutriente,
    required TexturaSolo texturaSolo,
    required bool irrigado,
    required CulturaParametros parametros,
    required double teorNutriente,
  }) {
    Map<String, double> parcelas = {};

    // Retorna imediatamente se a dose for zero
    if (dose <= 0) return parcelas;

    // 1. Extração de chaves e épocas
    Map<String, dynamic> epocasDisponiveisDoManual = _obterEpocasParaNutriente(nutriente, parametros);
    Map<String, String> chavesPorFase = _mapearChavesPorFase(epocasDisponiveisDoManual, nutriente);

    // 2. Obter limites dos parâmetros
    double? limiteMaximoSulco = parametros.limitesMaximosSulco[nutriente];

    // 3. Identificar regras específicas
    bool permitePrePlantio = epocasDisponiveisDoManual.keys.any((k) => k.contains('_PRE'));
    int maxCoberturas = _obterNumeroCoberturas(nutriente, epocasDisponiveisDoManual);

    // 4. Verificar regras especiais para pré-plantio (K₂O)
    if (_verificarCondicaoPrePlantio(
        nutriente,
        dose,
        limiteMaximoSulco,
        texturaSolo,
        permitePrePlantio,
        parametros,
        teorNutriente)) {  // Passar o teor
      String chavePrePlantio = chavesPorFase['pre_plantio'] ?? 'pre_plantio';
      parcelas[chavePrePlantio] = dose;
      return parcelas;
    }

    // 5. PARCELAMENTO PADRÃO
    String chavePlantio = chavesPorFase['plantio'] ?? 'plantio';

    // 5.1 Verificar se é nutriente que vai 100% no plantio
    bool aplicarTudoNoPlantio = _aplicarTudoNoplantio(nutriente, dose, limiteMaximoSulco);

    if (aplicarTudoNoPlantio) {
      parcelas[chavePlantio] = dose;
      return parcelas;
    }

    // 5.2 Aplicação parcelada (plantio + cobertura)
    // Obter limite para aplicação no plantio (usando EpocaAplicacao)
    double doseMaximaPlantio = 0.0;

    // Buscar a época de aplicação correspondente ao plantio
    EpocaAplicacao? epocaPlantio = null;
    for (var entry in parametros.epocasAplicacao.entries) {
      if (entry.key == chavePlantio) {
        epocaPlantio = entry.value;
        break;
      }
    }

    // Determinar dose máxima para o plantio
    if (epocaPlantio != null && epocaPlantio.limiteMaximo != null) {
      doseMaximaPlantio = epocaPlantio.limiteMaximo!;
    } else if (limiteMaximoSulco != null) {
      doseMaximaPlantio = limiteMaximoSulco;
    } else {
      doseMaximaPlantio = dose; // Se não há limite, usa a dose total
    }

    // Aplicar máximo permitido no plantio
    double doseNoPlantio = dose < doseMaximaPlantio ? dose : doseMaximaPlantio;
    parcelas[chavePlantio] = doseNoPlantio;

    // Calcular excedente para cobertura
    double excedente = dose - doseNoPlantio;
    if (excedente <= 0.5) {
      return parcelas;
    }

    // Distribuir nas coberturas
    _distribuirEmCoberturas(
        excedente,
        nutriente,
        maxCoberturas,
        chavesPorFase,
        irrigado,
        texturaSolo,
        parcelas
    );

    // Validação final
    _validarTotalDose(parcelas, dose);

    return parcelas;
  }

  /// Distribui o excedente nas coberturas disponíveis
  void _distribuirEmCoberturas(
      double excedente,
      String nutriente,
      int maxCoberturas,
      Map<String, String> chavesPorFase,
      bool irrigado,
      TexturaSolo texturaSolo,
      Map<String, double> parcelas) {

    // Identificar chaves de cobertura disponíveis
    List<String> chavesCobertura = [];
    for (int i = 1; i <= maxCoberturas; i++) {
      if (chavesPorFase.containsKey('cobertura$i')) {
        chavesCobertura.add(chavesPorFase['cobertura$i']!);
      } else {
        chavesCobertura.add('cobertura$i');
      }
    }

    if (chavesCobertura.isEmpty) return;

    // Ajustar número de coberturas com base em regras específicas
    int numCoberturas = chavesCobertura.length;

    // Regras específicas por nutriente
    if (nutriente == 'N') {
      if (excedente > 100 && irrigado) {
        numCoberturas = Math.min(3, numCoberturas > 0 ? numCoberturas : 3);
      } else if (excedente > 80) {
        numCoberturas = Math.min(2, numCoberturas > 0 ? numCoberturas : 2);
      }
    } else if (nutriente == 'K2O' && texturaSolo == TexturaSolo.ARENOSO) {
      numCoberturas = Math.min(2, numCoberturas > 0 ? numCoberturas : 2);
    }

    // Limitar ao número de chaves disponíveis
    numCoberturas = Math.min(numCoberturas, chavesCobertura.length);

    // Distribuir o excedente igualmente entre as coberturas
    double dosePorCobertura = excedente / numCoberturas;

    for (int i = 0; i < numCoberturas; i++) {
      parcelas[chavesCobertura[i]] = dosePorCobertura;
    }
  }

  // Método auxiliar inalterado, apenas para referência da validação
  void _validarTotalDose(Map<String, double> parcelas, double doseTotal) {
    // Remover parcelas com dose zero ou insignificante
    parcelas.removeWhere((key, value) => value < 0.5);

    // Verificar se a soma está correta
    if (parcelas.isEmpty) return;

    double somaParcelas = parcelas.values.fold(0.0, (sum, v) => sum + v);
    if ((somaParcelas - doseTotal).abs() > 0.1) {
      // Ajustar a última parcela para garantir a soma correta
      String ultimaChave = parcelas.keys.last;
      double diferenca = doseTotal - somaParcelas;
      parcelas[ultimaChave] = (parcelas[ultimaChave] ?? 0) + diferenca;

      // Remover se ficou zerada após ajuste
      parcelas.removeWhere((key, value) => value < 0.5);
    }
    // return parcelas; // Modificado para retornar o map validado (opcional, depende se quer modificar in-place ou retornar)
  }

  /// Mapeia as chaves do manual para fases padronizadas
  Map<String, String> _mapearChavesPorFase(Map<String, dynamic> epocasDisponiveisDoManual, String nutriente) {
    Map<String, String> chavesPorFase = {};
    String nutrientePrefixo = nutriente;

    if (nutriente == 'P2O5') nutrientePrefixo = 'P';
    if (nutriente == 'K2O') nutrientePrefixo = 'K';

    // Mapear chaves para fases padrão
    for (var chave in epocasDisponiveisDoManual.keys) {
      if (chave.startsWith('${nutrientePrefixo}_') || chave.startsWith(nutriente)) {
        if (chave.endsWith('_PLANT') || chave.contains('PLANT')) {
          chavesPorFase['plantio'] = chave;
        } else if (chave.endsWith('_PRE') || chave.contains('PRE')) {
          chavesPorFase['pre_plantio'] = chave;
        } else if (chave.endsWith('_COB1') || (chave.endsWith('_COB') && !chave.endsWith('_COB2'))) {
          chavesPorFase['cobertura1'] = chave;
        } else if (chave.endsWith('_COB2')) {
          chavesPorFase['cobertura2'] = chave;
        } else if (chave.endsWith('_COB3')) {
          chavesPorFase['cobertura3'] = chave;
        }
      }
    }

    // Se não encontrou chaves específicas, adicionar padrões
    if (!chavesPorFase.containsKey('plantio')) {
      chavesPorFase['plantio'] = 'plantio';
    }

    return chavesPorFase;
  }

  /// Verifica se deve aplicar nutriente em pré-plantio
  bool _verificarCondicaoPrePlantio(
      String nutriente,
      double dose,
      double? limiteNoSulco,
      TexturaSolo texturaSolo,
      bool permitePrePlantio,
      CulturaParametros parametros,
      double teorNutriente) {

    if (!permitePrePlantio) {
      return false;
    }

    // Buscar época de pré-plantio para o nutriente
    String? chavePrePlantio;
    EpocaAplicacao? epocaPrePlantio;

    for (var entry in parametros.epocasAplicacao.entries) {
      if ((entry.key.contains(nutriente) ||
          (nutriente == 'P2O5' && entry.key.startsWith('P_')) ||
          (nutriente == 'K2O' && entry.key.startsWith('K_'))) &&
          entry.key.contains('PRE')) {
        chavePrePlantio = entry.key;
        epocaPrePlantio = entry.value;
        break;
      }
    }

    if (epocaPrePlantio == null) {
      return false;
    }

    // Verifica condições especiais dos parâmetros
    if (epocaPrePlantio.parametrosAdicionais != null &&
        epocaPrePlantio.parametrosAdicionais.containsKey('condicoesEspeciais')) {

      var condicoes = epocaPrePlantio.parametrosAdicionais['condicoesEspeciais'] as Map<String, dynamic>?;

      if (condicoes != null) {
        // Verifica teor máximo (precisa ser menor que este valor)
        if (condicoes.containsKey('teorMaximo') &&
            condicoes['teorMaximo'] != null &&
            teorNutriente >= condicoes['teorMaximo']) {
          return false;
        }

        // Verifica teor mínimo (precisa ser maior que este valor)
        if (condicoes.containsKey('teorMinimo') &&
            condicoes['teorMinimo'] != null &&
            teorNutriente < condicoes['teorMinimo']) {
          return false;
        }

        // Verifica dose mínima
        if (condicoes.containsKey('doseMinima') &&
            condicoes['doseMinima'] != null &&
            dose < condicoes['doseMinima']) {
          return false;
        }

        // Verifica texturas permitidas
        if (condicoes.containsKey('texturas_permitidas') &&
            condicoes['texturas_permitidas'] != null) {
          List<String> texturasPerm = List<String>.from(condicoes['texturas_permitidas']);
          String texturaAtual = texturaSolo.toString().split('.').last;
          if (!texturasPerm.contains(texturaAtual)) {
            return false;
          }
        }

        // Verifica texturas proibidas
        if (condicoes.containsKey('texturas_proibidas') &&
            condicoes['texturas_proibidas'] != null) {
          List<String> texturasProib = List<String>.from(condicoes['texturas_proibidas']);
          String texturaAtual = texturaSolo.toString().split('.').last;
          if (texturasProib.contains(texturaAtual)) {
            return false;
          }
        }

        // Se chegou até aqui, todas as condições foram atendidas
        return true;
      }
    }

    // Fallback: se não tem condições específicas, verifica se é aplicação principal
    return epocaPrePlantio.aplicacaoPrincipal;
  }

  bool _verificarCondicoesAplicacao(
      String fase,
      String nutriente,
      double teor,
      double dose,
      TexturaSolo texturaSolo,
      CulturaParametros parametros) {

    // Buscar a época de aplicação para esta fase
    EpocaAplicacao? epoca;
    for (var entry in parametros.epocasAplicacao.entries) {
      if (_chaveRepresentaFase(entry.key, fase) &&
          _chavePertenceAoNutriente(entry.key, nutriente)) {
        epoca = entry.value;
        break;
      }
    }

    if (epoca == null || !epoca.parametrosAdicionais.containsKey('condicoesAplicacao')) {
      return false;
    }

    var condicoes = epoca.parametrosAdicionais['condicoesAplicacao'];
    if (condicoes == null) return false;

    // Verificar condições de teor
    if (condicoes['teor_minimo'] != null && teor < condicoes['teor_minimo']) {
      return false;
    }
    if (condicoes['teor_maximo'] != null && teor >= condicoes['teor_maximo']) {
      return false;
    }

    // Verificar condições de dose
    if (condicoes['dose_minima'] != null && dose < condicoes['dose_minima']) {
      return false;
    }
    if (condicoes['dose_maxima'] != null && dose > condicoes['dose_maxima']) {
      return false;
    }

    // Verificar texturas permitidas e proibidas
    String texturaString = texturaSolo.toString().split('.').last;

    if (condicoes['texturas_permitidas'] != null) {
      List<String> permitidas = List<String>.from(condicoes['texturas_permitidas']);
      if (!permitidas.contains(texturaString)) {
        return false;
      }
    }

    if (condicoes['texturas_proibidas'] != null) {
      List<String> proibidas = List<String>.from(condicoes['texturas_proibidas']);
      if (proibidas.contains(texturaString)) {
        return false;
      }
    }

    return true;
  }

  /// Verifica se o nutriente deve ser aplicado integralmente no plantio
  bool _aplicarTudoNoplantio(String nutriente, double dose, double? limiteNoSulco) {
    // P e micronutrientes geralmente vão 100% no plantio
    if (nutriente == 'P2O5' || ['B', 'Cu', 'Zn', 'Mn', 'Mo', 'Co'].contains(nutriente)) {
      return true;
    }

    // Se a dose é menor que o limite para sulco, vai 100% no plantio
    if (limiteNoSulco != null && dose <= limiteNoSulco) {
      return true;
    }

    return false;
  }


  /// Obtém as épocas de aplicação definidas para um nutriente específico
  /// Obtém as épocas de aplicação definidas para um nutriente específico
  Map<String, dynamic> _obterEpocasParaNutriente(String nutriente, CulturaParametros parametros) {
    Map<String, dynamic> epocas = {};
    String nutrientePrefixo = nutriente;

    // Adaptar o prefixo para busca conforme o nutriente
    if (nutriente == 'P2O5') nutrientePrefixo = 'P';
    if (nutriente == 'K2O') nutrientePrefixo = 'K';
    if (nutriente == 'N') nutrientePrefixo = 'N';

    // Busca 1: Chaves específicas para o nutriente
    for (var entry in parametros.epocasAplicacao.entries) {
      String chave = entry.key;
      // Verificar se a chave está relacionada ao nutriente atual
      if (chave.startsWith('${nutrientePrefixo}_') ||
          chave.startsWith(nutriente)) {
        epocas[chave] = entry.value;
      }
    }

    // Busca 2: Micros agrupados (se for micronutriente)
    if (['B', 'Cu', 'Mn', 'Zn', 'Mo', 'Co'].contains(nutriente) && epocas.isEmpty) {
      for (var entry in parametros.epocasAplicacao.entries) {
        if (entry.key.startsWith('MICRO_')) {
          epocas[entry.key] = entry.value;
        }
      }
    }

    // Busca 3: Se ainda não encontrou nada, buscar épocas genéricas
    if (epocas.isEmpty) {
      for (var entry in parametros.epocasAplicacao.entries) {
        if (entry.key.contains('PLANT') ||
            entry.key.contains('COB') ||
            entry.key.contains('PRE')) {
          epocas[entry.key] = entry.value;
        }
      }
    }

    return epocas;
  }

  /// Determina o número de coberturas com base nos parâmetros e no nutriente
  int _obterNumeroCoberturas(String nutriente, Map<String, dynamic> epocasDisponiveisDoManual) {
    // Contar número de coberturas definidas nos parâmetros
    int coberturasDefined = 0;
    List<String> chavesCobertura = [];

    for (var chave in epocasDisponiveisDoManual.keys) {
      if (chave.contains('_COB')) {
        chavesCobertura.add(chave);

        // Extrair número da cobertura (COB1, COB2, etc.)
        RegExp regExp = RegExp(r'COB(\d+)');
        var match = regExp.firstMatch(chave);
        if (match != null && match.groupCount >= 1) {
          int numCobertura = int.tryParse(match.group(1) ?? '1') ?? 1;
          coberturasDefined = Math.max(coberturasDefined, numCobertura);
        } else {
          // Se encontrou COB sem número, assume pelo menos uma cobertura
          coberturasDefined = Math.max(coberturasDefined, 1);
        }
      }
    }

    if (coberturasDefined > 0) {
      return coberturasDefined;
    }

    // Se não há parametrização explícita, usar valores padrão baseados nas recomendações
    // típicas, mas apenas como último recurso
    if (nutriente == 'N') return 2;     // N tipicamente tem até 2 coberturas
    if (nutriente == 'K2O') return 1;   // K tipicamente tem 1 cobertura

    return 1; // Valor conservador padrão
  }

  /// Obtém os dias após plantio para uma época específica - Versão corrigida
  int _obterDiasAposPlantio(String fase, Map<String, dynamic> epocasDoManual) {
    // Buscar nos parâmetros da cultura
    String chaveCorrespondente = '';

    for (var chave in epocasDoManual.keys) {
      if (chave.toLowerCase().contains(fase.toLowerCase()) ||
          (fase == 'plantio' && chave.contains('_PLANT')) ||
          (fase == 'pre_plantio' && chave.contains('_PRE')) ||
          (fase.contains('cobertura1') && chave.contains('_COB1')) ||
          (fase.contains('cobertura2') && chave.contains('_COB2'))) {
        chaveCorrespondente = chave;
        break;
      }
    }

    if (chaveCorrespondente.isNotEmpty) {
      var valor = epocasDoManual[chaveCorrespondente];

      // Verificar o tipo correto
      if (valor is EpocaAplicacao) {
        return valor.dias;
      } else if (valor is Map && valor.containsKey('dias')) {
        final diasValue = valor['dias'];
        return diasValue is int ? diasValue : (diasValue is num ? diasValue.toInt() : 0);
      }
    }

    // Valores padrão se não encontrar
    if (fase.contains('pre')) return -15;  // 15 dias antes do plantio
    if (fase.contains('plantio')) return 0;
    if (fase.contains('cobertura1')) return 25;
    if (fase.contains('cobertura2')) return 40;
    if (fase.contains('cobertura3')) return 55;

    return 0; // Valor padrão: plantio
  }

  /// Método melhorado para gerar aplicações com base no parcelamento
  /// Gera aplicações de nutrientes com base nos parâmetros do manual
  /// Gera aplicações de nutrientes com base nos parâmetros do manual
  Future<Map<String, List<AplicacaoNutriente>>> gerarAplicacoesNutrientes({
    required Map<String, RecomendacaoNutriente> nutrientes,
    required CulturaParametros parametros,
    required TexturaSolo texturaSolo,
    required bool irrigado,
    required DateTime dataPlantio,
    required String produtorId,
    required String propriedadeId,
  }) async {
    final Map<String, List<AplicacaoNutriente>> resultado = {};

    // Processar cada nutriente
    for (var entry in nutrientes.entries) {
      final nutriente = entry.key;
      final recomendacao = entry.value;

      // Pular se a dose for zero ou negativa
      if (recomendacao.doseRecomendada <= 0) {
        resultado[nutriente] = [];
        continue;
      }

      final List<AplicacaoNutriente> aplicacoes = [];

      // Obter épocas disponíveis para este nutriente
      final epocasDoManual = _obterEpocasParaNutriente(nutriente, parametros);

      // Calcular parcelamento com base nos parâmetros do manual
      final parcelasNutriente = _calcularParcelamentoNutriente(
        dose: recomendacao.doseRecomendada,
        nutriente: nutriente,
        texturaSolo: texturaSolo,
        irrigado: irrigado,
        parametros: parametros,
        teorNutriente: recomendacao.teor, // Usar o teor da recomendação
      );

      // Converter o parcelamento em objetos AplicacaoNutriente
      for (var entry in parcelasNutriente.entries) {
        final String fase = entry.key;
        final double doseParcial = entry.value;

        // Calcular percentual da dose total
        final percentual = (recomendacao.doseRecomendada > 0)
            ? (doseParcial / recomendacao.doseRecomendada) * 100.0
            : 100.0;

        // Obter dias após plantio com base na fase
        final dias = _obterDiasAposPlantio(fase, epocasDoManual);

        // Calcular data prevista
        final dataAplicacao = dias != null ?
        DateTime(dataPlantio.year, dataPlantio.month, dataPlantio.day + dias) :
        dataPlantio;

        // Definir modo de aplicação com base no manual
        final modoAplicacao = _definirModoAplicacao(nutriente, fase, parametros);

        // Gerar observações específicas
        final observacoes = _gerarObservacoesAplicacao(
          nutriente: nutriente,
          fase: fase,
          dose: doseParcial,
          parametros: parametros,
          texturaSolo: texturaSolo,
          irrigado: irrigado,
        );

        // Criar a aplicação
        aplicacoes.add(AplicacaoNutriente(
          id: '',
          recomendacaoNutrienteId: recomendacao.id,
          produtorId: produtorId,
          propriedadeId: propriedadeId,
          fase: _normalizarNomeFase(fase),
          modoAplicacao: modoAplicacao,
          dosePlanejada: doseParcial,
          percentualDose: percentual,
          diasAposPlantio: dias,
          dataPrevisao: dataAplicacao,
          estagioCultura: _obterEstagioCultura(dias, parametros.cultura, parametros),
          observacoes: observacoes,
        ));
      }

      // Ordenar aplicações por data (dias após plantio)
      aplicacoes.sort((a, b) => (a.diasAposPlantio ?? 0).compareTo(b.diasAposPlantio ?? 0));

      resultado[nutriente] = aplicacoes;
    }

    return resultado;
  }



  /// Gera observações específicas para cada aplicação
  /// Gera observações específicas para cada aplicação, com base no manual
  List<String> _gerarObservacoesAplicacao({
    required String nutriente,
    required String fase,
    required double dose,
    required CulturaParametros parametros,
    required TexturaSolo texturaSolo,
    required bool irrigado,
  }) {
    List<String> observacoes = [];

    // 1. Buscar a época de aplicação correspondente
    EpocaAplicacao? epocaAplicacao;
    for (var entry in parametros.epocasAplicacao.entries) {
      if (_chaveRepresentaFase(entry.key, fase) &&
          _chavePertenceAoNutriente(entry.key, nutriente)) {
        epocaAplicacao = entry.value;
        break;
      }
    }

    // 2. Se encontrou época de aplicação, buscar observações parametrizadas
    if (epocaAplicacao != null &&
        epocaAplicacao.parametrosAdicionais.containsKey('observacoes')) {

      var obsMap = epocaAplicacao.parametrosAdicionais['observacoes'] as Map<String, dynamic>?;

      if (obsMap != null) {
        // Buscar observações específicas para o tipo de solo
        String texturaKey = texturaSolo.toString().split('.').last.toLowerCase();

        if (obsMap.containsKey(texturaKey)) {
          List<dynamic> obsTextura = obsMap[texturaKey];
          observacoes.addAll(obsTextura.map((o) => o.toString()));
        }

        // Buscar observações gerais
        if (obsMap.containsKey('geral')) {
          List<dynamic> obsGerais = obsMap['geral'];
          observacoes.addAll(obsGerais.map((o) => o.toString()));
        }
      }
    }

    // 3. Se não encontrou observações parametrizadas, buscar nas observações gerais
    if (observacoes.isEmpty) {
      for (var obs in parametros.observacoesManejo) {
        if (obs.toLowerCase().contains(nutriente.toLowerCase()) &&
            (fase.contains('plantio') && obs.toLowerCase().contains('plant') ||
                fase.contains('cobertura') && obs.toLowerCase().contains('cobertura') ||
                fase.contains('pre') && obs.toLowerCase().contains('pré'))) {
          observacoes.add(obs);
        }
      }
    }

    // 4. Adicionar observações relacionadas a limites, se aplicável
    if (fase.contains('plantio')) {
      double? limite = parametros.limitesMaximosSulco[nutriente];
      if (limite != null && dose >= limite) {
        observacoes.add('Dose máxima recomendada para aplicação no sulco (${limite.toStringAsFixed(1)} kg/ha).');
      }
    }

    return observacoes;
  }

// Método auxiliar para obter dias após plantio com base na fase
  int _obterDiasAposPlantioPorFase(String fase, CulturaParametros parametros) {
    // Buscar nos parâmetros da cultura primeiro
    final chavesEpocas = parametros.epocasAplicacao.keys
        .where((k) => k.toLowerCase().contains(fase.toLowerCase()))
        .toList();

    if (chavesEpocas.isNotEmpty) {
      return parametros.epocasAplicacao[chavesEpocas.first]?.dias ?? 0;
    }

    // Valores padrão se não encontrar nos parâmetros
    if (fase.toLowerCase().contains('plantio')) return 0;
    if (fase.toLowerCase().contains('cobertura1')) return 25;
    if (fase.toLowerCase().contains('cobertura2')) return 40;
    if (fase.toLowerCase().contains('pré')) return -15; // 15 dias antes do plantio

    return 0;
  }

// Método para normalizar nome da fase para exibição
  String _normalizarNomeFase(String fase) {
    // Mapeamento interno que será movido para parametrosAdicionais
    Map<String, String> mapeamentoFases = {
      'plantio': 'Plantio',
      'pre_plantio': 'Pré-plantio',
      'cobertura1': 'Cobertura (1ª aplicação)',
      'cobertura2': 'Cobertura (2ª aplicação)',
      'cobertura3': 'Cobertura (3ª aplicação)',
    };

    // Verificar no mapeamento direto
    if (mapeamentoFases.containsKey(fase.toLowerCase())) {
      return mapeamentoFases[fase.toLowerCase()]!;
    }

    // Verificar em códigos como N_PLANT, K_COB, etc.
    if (fase.contains('_PLANT') || fase.endsWith('PLANT')) {
      return 'Plantio';
    }

    if (fase.contains('_PRE') || fase.endsWith('PRE')) {
      return 'Pré-plantio';
    }

    if (fase.contains('_COB1')) {
      return 'Cobertura (1ª aplicação)';
    }

    if (fase.contains('_COB2')) {
      return 'Cobertura (2ª aplicação)';
    }

    if (fase.contains('_COB3')) {
      return 'Cobertura (3ª aplicação)';
    }

    if (fase.contains('_COB') && !fase.contains('_COB1') && !fase.contains('_COB2') && !fase.contains('_COB3')) {
      return 'Cobertura';
    }

    // Retornar a própria fase se não encontrar mapeamento
    return fase;
  }

// Método para determinar estágio da cultura com base nos dias após plantio
  String _obterEstagioCultura(int? dias, TipoCultura cultura, CulturaParametros parametros) {
    if (dias == null || dias <= 0) return 'Plantio';

    // Verificar se há estágios definidos nos parâmetros adicionais
    if (parametros.parametrosAdicionais != null &&
        parametros.parametrosAdicionais!.containsKey('estagiosCultura')) {

      var estagios = parametros.parametrosAdicionais!['estagiosCultura'] as Map<String, dynamic>;

      // Converter para Map<String, int>
      Map<String, int> estagiosMap = {};
      estagios.forEach((key, value) {
        if (value is int) {
          estagiosMap[key] = value;
        } else if (value is num) {
          estagiosMap[key] = value.toInt();
        }
      });

      if (estagiosMap.isNotEmpty) {
        // Ordenar por dias (ordem crescente)
        var estagiosOrdenados = estagiosMap.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));

        // Encontrar o estágio adequado
        for (int i = estagiosOrdenados.length - 1; i >= 0; i--) {
          if (dias >= estagiosOrdenados[i].value) {
            return estagiosOrdenados[i].key;
          }
        }
      }
    }

    // Usar a implementação hardcoded como fallback
    return _obterEstagioFallback(dias, cultura);
  }

// Método auxiliar para fallback
  String _obterEstagioFallback(int dias, TipoCultura cultura) {
    if (cultura == TipoCultura.SOJA) {
      if (dias <= 20) return 'V2-V3';
      if (dias <= 35) return 'V4-V5';
      if (dias <= 50) return 'R1-R2';
      return 'R3+';
    } else if (cultura == TipoCultura.MILHO_GRAO) {
      if (dias <= 20) return 'V3-V4';
      if (dias <= 35) return 'V5-V6';
      if (dias <= 50) return 'V7-V8';
      return 'V9+';
    } else if (cultura == TipoCultura.CANA_DE_ACUCAR) {
      if (dias <= 30) return 'Brotação';
      if (dias <= 90) return 'Perfilhamento';
      if (dias <= 180) return 'Desenvolvimento';
      return 'Maturação';
    }

    return 'Não definido';
  }

  /// Define o modo de aplicação com base nos parâmetros do manual - Versão corrigida
  String _definirModoAplicacao(String nutriente, String fase, CulturaParametros parametros) {
    // 1. Verificar na estrutura epocasAplicacao
    for (var entry in parametros.epocasAplicacao.entries) {
      if (_chavePertenceAoNutriente(entry.key, nutriente) &&
          _chaveRepresentaFase(entry.key, fase)) {
        return entry.value.modoAplicacao.descricao;
      }
    }

    // 2. Verificar nos parametrosAdicionais
    if (parametros.parametrosAdicionais != null) {
      Map<String, dynamic>? modosPadrao =
      parametros.parametrosAdicionais!['modosAplicacaoPadrao'] as Map<String, dynamic>?;

      if (modosPadrao != null) {
        String faseLower = fase.toLowerCase();

        if (faseLower.contains('pre') && modosPadrao.containsKey('pre_plantio')) {
          return modosPadrao['pre_plantio'] as String;
        }

        if ((faseLower.contains('plant') || fase.contains('PLANT')) &&
            modosPadrao.containsKey('plantio')) {
          return modosPadrao['plantio'] as String;
        }

        if ((faseLower.contains('cob') || fase.contains('COB')) &&
            modosPadrao.containsKey('cobertura')) {
          return modosPadrao['cobertura'] as String;
        }
      }
    }

    // 3. Fallback apenas como último recurso
    return _definirModoAplicacaoPadrao(fase);
  }

  String _definirModoAplicacaoPadrao(String fase) {
    String faseLower = fase.toLowerCase();

    if (faseLower.contains('pre') || fase.contains('PRE')) {
      return 'Lanço em pré-plantio';
    } else if (faseLower.contains('plant') || fase.contains('PLANT')) {
      return 'Sulco de plantio';
    } else if (faseLower.contains('cob') || fase.contains('COB')) {
      return 'Lanço em cobertura';
    }

    return 'Não definido';
  }

  /// Verifica se uma chave pertence a um determinado nutriente
  bool _chavePertenceAoNutriente(String chave, String nutriente) {
    String prefixo = nutriente;
    if (nutriente == 'P2O5') prefixo = 'P';
    if (nutriente == 'K2O') prefixo = 'K';

    return chave.startsWith(prefixo) ||
        chave.startsWith(nutriente) ||
        (nutriente.length > 2 && chave.startsWith(nutriente.substring(0, 1))); // Para 'Zn', 'Cu', etc.
  }

  /// Verifica se uma chave representa uma determinada fase
  bool _chaveRepresentaFase(String chave, String fase) {
    chave = chave.toUpperCase();

    if (fase.contains('plantio') && (chave.contains('PLANT'))) return true;
    if (fase.contains('pre') && (chave.contains('PRE'))) return true;

    // Para coberturas, verificar número específico
    if (fase.contains('cobertura')) {
      if (!fase.contains('cobertura1') && !fase.contains('cobertura2') &&
          !fase.contains('cobertura3') && chave.contains('COB')) {
        return true; // Cobertura genérica
      }

      if (fase.contains('cobertura1') &&
          (chave.contains('COB1') || (chave.contains('COB') && !chave.contains('COB2') && !chave.contains('COB3')))) {
        return true;
      }

      if (fase.contains('cobertura2') && chave.contains('COB2')) return true;
      if (fase.contains('cobertura3') && chave.contains('COB3')) return true;
    }

    return false;
  }

// As funções _calcularParcelamentoN e _calcularParcelamentoK foram removidas por redundância.

} // Fim da classe AjustesDosesCalculator