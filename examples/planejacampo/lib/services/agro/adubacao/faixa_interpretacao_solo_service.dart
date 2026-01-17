// lib/services/agro/adubacao/faixa_interpretacao_solo_service.dart

import 'package:planejacampo/models/agro/adubacao/faixa_interpretacao_solo.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/generic_service.dart';

class FaixaInterpretacaoSoloService extends GenericService<FaixaInterpretacaoSolo> {
  FaixaInterpretacaoSoloService() : super('faixasInterpretacaoSolo');

  @override
  FaixaInterpretacaoSolo fromMap(Map<String, dynamic> map, String documentId) {
    return FaixaInterpretacaoSolo.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(FaixaInterpretacaoSolo faixa) {
    return faixa.toMap();
  }

  Future<List<FaixaInterpretacaoSolo>> getFaixasManual(
      String manualAdubacao,
      String produtorId,
      ) async {
    try {
      return await getByAttributes({
        'manualAdubacao': manualAdubacao,
        'produtorId': produtorId,
      });
    } catch (e) {
      print('Erro ao buscar faixas de interpretação do manual: $e');
      return [];
    }
  }

  Future<List<FaixaInterpretacaoSolo>> getFaixasCultura(
      String manualAdubacao,
      String produtorId,
      TipoCultura cultura,
      ) async {
    try {
      return await getByAttributes({
        'manualAdubacao': manualAdubacao,
        'produtorId': produtorId,
        'cultura': cultura.toString().split('.').last,
      });
    } catch (e) {
      print('Erro ao buscar faixas de interpretação da cultura: $e');
      return [];
    }
  }

  Future<FaixaInterpretacaoSolo?> getFaixaNutriente(
      String manualAdubacao,
      TipoCultura cultura,
      String nutriente,
      ) async {
    try {
      final faixas = await getByAttributes({
        'manualAdubacao': manualAdubacao,
        'cultura': cultura.toString().split('.').last,
        'nutriente': nutriente,
      });
      return faixas.isNotEmpty ? faixas.first : null;
    } catch (e) {
      print('Erro ao buscar faixa de interpretação do nutriente: $e');
      return null;
    }
  }

  Future<void> salvarFaixaInterpretacao(FaixaInterpretacaoSolo faixa) async {
    try {
      // Verifica se já existe faixa para o nutriente
      final faixaExistente = await getFaixaNutriente(
        faixa.manualAdubacao,
        faixa.cultura,
        faixa.nutriente,
      );

      if (faixaExistente != null) {
        // Atualiza faixa existente
        await update(faixaExistente.id, faixa);
      } else {
        // Cria nova faixa
        await add(faixa);
      }
    } catch (e) {
      print('Erro ao salvar faixa de interpretação: $e');
      rethrow;
    }
  }

  Future<void> importarFaixas(
      String manualOrigem,
      String manualDestino,
      String produtorId,
      ) async {
    try {
      final faixasOrigem = await getFaixasManual(manualOrigem, produtorId);

      for (var faixa in faixasOrigem) {
        await salvarFaixaInterpretacao(
          faixa.copyWith(
            id: '',
            manualAdubacao: manualDestino,
          ),
        );
      }
    } catch (e) {
      print('Erro ao importar faixas de interpretação: $e');
      rethrow;
    }
  }

  String interpretarValor(
      FaixaInterpretacaoSolo faixa,
      double valor,
      ) {
    if (valor <= faixa.limiteInferior) {
      return 'Baixo';
    } else if (valor <= faixa.limiteSuperior) {
      return 'Médio';
    } else {
      return 'Alto';
    }
  }
}