// lib/services/agro/adubacao/aplicacao_nutriente_service.dart

import 'package:planejacampo/models/agro/adubacao/aplicacao_nutriente.dart';
import 'package:planejacampo/services/generic_service.dart';

class AplicacaoNutrienteService extends GenericService<AplicacaoNutriente> {
  AplicacaoNutrienteService() : super('aplicacoesNutrientes');

  @override
  AplicacaoNutriente fromMap(Map<String, dynamic> map, String documentId) {
    return AplicacaoNutriente.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(AplicacaoNutriente aplicacao) {
    return aplicacao.toMap();
  }

  Future<List<AplicacaoNutriente>> getByRecomendacaoNutriente(String recomendacaoNutrienteId) async {
    try {
      return await getByAttributes({
        'recomendacaoNutrienteId': recomendacaoNutrienteId,
      }, orderBy: [
        {'field': 'fase', 'direction': 'asc'}
      ]);
    } catch (e) {
      print('Erro ao buscar aplicações do nutriente: $e');
      return [];
    }
  }

  Future<void> salvarAplicacoesNutriente(
      String recomendacaoNutrienteId,
      List<AplicacaoNutriente> aplicacoes,
      String produtorId,
      String propriedadeId,
      ) async {
    try {
      // Remover aplicações anteriores
      await deleteByAttribute({'recomendacaoNutrienteId': recomendacaoNutrienteId});

      // Salvar novas aplicações
      for (var aplicacao in aplicacoes) {
        final docRef = getCollectionReference().doc();
        await add(
          aplicacao.copyWith(
            id: docRef.id,
            recomendacaoNutrienteId: recomendacaoNutrienteId,
            produtorId: produtorId,
            propriedadeId: propriedadeId,
          ),
        );
      }
    } catch (e) {
      print('Erro ao salvar aplicações do nutriente: $e');
      rethrow;
    }
  }
}