// lib/services/agro/adubacao/parametro_calagem_service.dart

import 'package:planejacampo/models/agro/adubacao/parametro_calagem.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/generic_service.dart';

class ParametroCalagemService extends GenericService<ParametroCalagem> {
  ParametroCalagemService() : super('parametrosCalagem');

  @override
  ParametroCalagem fromMap(Map<String, dynamic> map, String documentId) {
    return ParametroCalagem.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ParametroCalagem parametro) {
    return parametro.toMap();
  }

  Future<ParametroCalagem?> getParametrosCultura(
      String manualAdubacao,
      TipoCultura cultura,
      ) async {
    try {
      final parametros = await getByAttributes({
        'manualAdubacao': manualAdubacao,
        'cultura': cultura.toString().split('.').last,
      });
      return parametros.isNotEmpty ? parametros.first : null;
    } catch (e) {
      print('Erro ao buscar parâmetros de calagem: $e');
      return null;
    }
  }

  Future<void> salvarParametrosCalagem(ParametroCalagem parametro) async {
    try {
      // Verifica se já existem parâmetros para a cultura
      final parametrosExistentes = await getParametrosCultura(
        parametro.manualAdubacao,
        parametro.cultura,
      );

      if (parametrosExistentes != null) {
        // Atualiza parâmetros existentes
        await update(parametrosExistentes.id, parametro);
      } else {
        // Cria novos parâmetros
        await add(parametro);
      }
    } catch (e) {
      print('Erro ao salvar parâmetros de calagem: $e');
      rethrow;
    }
  }

  Future<void> importarParametros(
      String manualOrigem,
      String manualDestino,
      String produtorId,
      ) async {
    try {
      final parametros = await getByAttributes({
        'manualAdubacao': manualOrigem,
        'produtorId': produtorId,
      });

      for (var parametro in parametros) {
        await salvarParametrosCalagem(
          parametro.copyWith(
            id: '',
            manualAdubacao: manualDestino,
          ),
        );
      }
    } catch (e) {
      print('Erro ao importar parâmetros de calagem: $e');
      rethrow;
    }
  }

  double calcularNecessidadeCalcario({
    required double vAtual,
    required double vDesejada,
    required double ctc,
    required double prnt,
    required double profundidadeCalcario,
  }) {
    // NC = [(V2 - V1) × CTC × p] / (PRNT × 10)
    final fatorProfundidade = profundidadeCalcario / 20.0;
    final nc = ((vDesejada - vAtual) * ctc * fatorProfundidade) / (prnt * 10);
    return nc > 0 ? nc : 0;
  }

  Map<String, dynamic> validarParametros(ParametroCalagem parametro) {
    List<String> erros = [];
    List<String> avisos = [];

    if (parametro.saturacaoBasesAlvo < 40 || parametro.saturacaoBasesAlvo > 80) {
      erros.add('Saturação por bases alvo deve estar entre 40% e 80%');
    }

    if (parametro.profundidadeCalcario < 20 || parametro.profundidadeCalcario > 40) {
      erros.add('Profundidade de incorporação deve estar entre 20 e 40 cm');
    }

    if (parametro.prntReferencia < 70) {
      avisos.add('PRNT muito baixo pode comprometer eficiência da calagem');
    }

    if (parametro.prazoAplicacao < 60) {
      avisos.add('Prazo de aplicação menor que 60 dias pode comprometer reação do calcário');
    }

    return {
      'valido': erros.isEmpty,
      'erros': erros,
      'avisos': avisos,
    };
  }
}