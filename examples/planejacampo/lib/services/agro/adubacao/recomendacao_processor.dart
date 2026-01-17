import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/agro/cultura.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/agro/adubacao/cultura_parametros_service.dart';
import 'package:planejacampo/services/agro/adubacao/faixa_interpretacao_solo_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_service.dart';
import 'package:planejacampo/services/agro/adubacao/ajustes_doses_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/correcao_solo_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/nutriente_calculator.dart';
import 'package:planejacampo/services/agro/adubacao/validador_recomendacao.dart';

class RecomendacaoProcessor {
  final CulturaParametrosService parametrosService;
  final FaixaInterpretacaoSoloService faixaService;
  final RecomendacaoService recomendacaoService;
  final NutrienteCalculator nutrienteCalculator;
  final CorrecaoSoloCalculator correcaoCalculator;
  final AjustesDosesCalculator ajustesCalculator;
  final ValidadorRecomendacao validador;

  RecomendacaoProcessor({
    required this.parametrosService,
    required this.faixaService,
    required this.recomendacaoService,
    required this.nutrienteCalculator,
    required this.correcaoCalculator,
    required this.ajustesCalculator,
    required this.validador,
  });

  Future<Map<String, dynamic>> processarRecomendacao({
    required ResultadoAnaliseSolo analise,
    required Cultura cultura,
    required double produtividadeEsperada,
    required String estado,
    required String produtorId,
    required String propriedadeId,
    required String talhaoId,
  }) async {
    try {
      _logDadosEntrada(analise, cultura, produtividadeEsperada);

      final parametros = await _buscarParametrosCultura(
        cultura.tipo,
        estado,
        produtorId,
      );

      final caracteristicasSolo = _avaliarCondicoesSolo(analise, parametros);
      _logCondicoesSolo(analise, caracteristicasSolo);

      final correcoes = await _calcularCorrecoesSolo(
        analise,
        parametros,
        produtorId,
        propriedadeId,
        produtividadeEsperada,
      );
      _logCorrecoesSolo(correcoes);

      var nutrientes = await nutrienteCalculator.calcularDoses(
        analise: analise,
        parametros: parametros,
        produtividadeEsperada: produtividadeEsperada,
        texturaSolo: caracteristicasSolo['texturaSolo'],
        classeResposta: caracteristicasSolo['classeResposta'],
        irrigado: cultura.permiteIrrigacao,
        produtorId: produtorId,
        propriedadeId: propriedadeId,
      );

      // Ajustar doses conforme necessário
      nutrientes = _ajustarDosesEParcelamento(nutrientes, caracteristicasSolo, parametros);

      // NOVO: Calcular aplicações estruturadas para cada nutriente
      final aplicacoes = await ajustesCalculator.gerarAplicacoesNutrientes(
        nutrientes: nutrientes,
        parametros: parametros,
        texturaSolo: caracteristicasSolo['texturaSolo'],
        irrigado: cultura.permiteIrrigacao,
        dataPlantio: cultura.dataPlantio ?? DateTime.now(),
        produtorId: produtorId,
        propriedadeId: propriedadeId,
      );
      _logNutrientesAjustados(nutrientes);

      final recomendacao = Recomendacao(
        id: '',
        manualAdubacao: parametros.manualAdubacao,
        produtorId: produtorId,
        propriedadeId: propriedadeId,
        talhaoId: talhaoId,
        dataRecomendacao: DateTime.now(),
        dataPlantio: cultura.dataPlantio ?? DateTime.now(),
        produtividadeEsperada: produtividadeEsperada,
        resultadoAnaliseSoloId: analise.id,
        tipoCultura: cultura.tipo,
        classeResposta: caracteristicasSolo['classeResposta'],
        texturaSolo: caracteristicasSolo['texturaSolo'],
        sistemaCultivo: cultura.sistemaCultivo,
        irrigado: cultura.permiteIrrigacao,
        observacoes: ['Recomendação gerada com sucesso'],
      );
      _logRecomendacaoFinal(recomendacao);

      final validacao = validador.validarRecomendacao(
        recomendacao: recomendacao,
        nutrientes: nutrientes,
        parametros: parametros,
        calagem: correcoes['calagem'],
        gessagem: correcoes['gessagem'],
      );
      _logValidacao(validacao);

      return {
        'recomendacao': recomendacao,
        'nutrientes': nutrientes,
        'correcoes': correcoes,
        'aplicacoes': aplicacoes,  // NOVO: incluir aplicações no resultado
        'validacao': validacao,
      };
    } catch (e, stackTrace) {
      print('Erro ao processar recomendação: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<CulturaParametros> _buscarParametrosCultura(
      TipoCultura cultura, String estado, String produtorId) async {
    // Necessário modificar. Utilizar a UF para definir qual manual será utilizado, dentre os manuais existentes, utilizar o último.
    final parametros = await parametrosService.getParametrosCultura(
      cultura,
      'IAC-B100-2022-$estado',
    );
    if (parametros == null) {
      throw Exception('Parâmetros não encontrados para a cultura $cultura.');
    }
    return parametros;
  }

  Future<Map<String, dynamic>> _calcularCorrecoesSolo(
      ResultadoAnaliseSolo analise,
      CulturaParametros parametros,
      String produtorId,
      String propriedadeId,
      double produtividadeEsperada) async {
    final resultado = await correcaoCalculator.calcularCorrecoes(
      analise: analise,
      parametros: parametros,
      produtorId: produtorId,
      propriedadeId: propriedadeId,
      produtividadeEsperada: produtividadeEsperada,
    );
    if (resultado['calagem'] != null) {
      print('Calagem recomendada: ${resultado['calagem']}');
    }
    if (resultado['gessagem'] != null) {
      print('Gessagem recomendada: ${resultado['gessagem']}');
    }
    return resultado;
  }

  Map<String, RecomendacaoNutriente> _ajustarDosesEParcelamento(
      Map<String, RecomendacaoNutriente> nutrientes,
      Map<String, dynamic> caracteristicasSolo,
      CulturaParametros parametros) {  // Adicionar parâmetro
    return nutrientes.map((key, value) {
      if (key == 'K2O' && value.doseRecomendada > parametros.limitesMaximosSulco['K2O']!) {
        final limiteK2O = parametros.limitesMaximosSulco['K2O']!;
        final observacoes = List<String>.from(value.observacoes)
          ..add('Máximo ${limiteK2O} kg/ha no plantio');
        return MapEntry(key, value.copyWith(observacoes: observacoes));
      }
      return MapEntry(key, value);
    });
  }

  Map<String, dynamic> _avaliarCondicoesSolo(
      ResultadoAnaliseSolo analise, CulturaParametros parametros) {
    // CORREÇÃO CRÍTICA: Priorizar textura já definida na análise
    // Só calcular a partir do teor de argila se não estiver disponível
    //final texturaSolo = analise.texturaSolo ?? _determinarTexturaSolo(analise.argila);
    // Calcular a textura pois o que foi recebido da análise pode estar errado.
    final texturaSolo = _determinarTexturaSolo(analise.argila);

    if (!TexturaSolo.values.contains(texturaSolo)) {
      throw Exception('Textura do solo inválida: $texturaSolo');
    }

    final classeResposta = analise.saturacaoBase < parametros.parametrosCalagem['saturacao_bases_minima']
        ? ClasseResposta.ALTA
        : ClasseResposta.MEDIA_BAIXA;

    return {
      'texturaSolo': texturaSolo,
      'classeResposta': classeResposta,
    };
  }

  // CORREÇÃO: Método para determinar textura a partir do teor de argila
  // As unidades devem estar em g/kg (não em percentual)
  TexturaSolo _determinarTexturaSolo(double teorArgila) {
    // Teor de argila em g/kg deve ser comparado com valores em g/kg
    if (teorArgila <= 150) return TexturaSolo.ARENOSO;  // <= 15%
    if (teorArgila <= 350) return TexturaSolo.MEDIO;    // Entre 15% e 35%
    return TexturaSolo.ARGILOSO;                       // > 35%
  }

  void _logDadosEntrada(ResultadoAnaliseSolo analise, Cultura cultura,
      double produtividadeEsperada) {
    print('=== DADOS DE ENTRADA ===');
    print('Análise ID: ${analise.id}');
    print('Cultura: ${cultura.tipo}, Produtividade Esperada: $produtividadeEsperada t/ha');
    print('Análise de Solo: $analise');
  }

  void _logCondicoesSolo(ResultadoAnaliseSolo analise, Map<String, dynamic> condicoes) {
    print('=== CONDIÇÕES DO SOLO ===');
    print('Textura: ${condicoes['texturaSolo']}');
    print('Classe Resposta: ${condicoes['classeResposta']}');
  }

  void _logCorrecoesSolo(Map<String, dynamic> correcoes) {
    print('=== CORREÇÕES DO SOLO ===');
    correcoes.forEach((key, value) {
      print('$key: ${value.toString()}');
    });
  }

  void _logRecomendacaoNutrientes(Map<String, RecomendacaoNutriente> nutrientes) {
    print('=== RECOMENDAÇÃO DE NUTRIENTES ===');
    nutrientes.forEach((key, value) {
      print('$key: Dose: ${value.doseRecomendada}, Observações: ${value.observacoes}');
    });
  }

  void _logNutrientesAjustados(Map<String, RecomendacaoNutriente> nutrientes) {
    print('=== NUTRIENTES AJUSTADOS ===');
    nutrientes.forEach((key, value) {
      print('$key: Dose: ${value.doseRecomendada}, Observações: ${value.observacoes}');
    });
  }

  void _logRecomendacaoFinal(Recomendacao recomendacao) {
    print('=== RECOMENDAÇÃO FINAL ===');
    print(recomendacao.toString());
  }

  void _logValidacao(Map<String, dynamic> validacao) {
    print('=== VALIDAÇÃO DA RECOMENDAÇÃO ===');
    print('Valida: ${validacao['valido']}');
    print('Erros: ${validacao['erros']}');
    print('Avisos: ${validacao['avisos']}');
  }
}
