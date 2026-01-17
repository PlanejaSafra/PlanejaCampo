// lib/services/agro/adubacao/recomendacao_nutriente_service.dart
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecomendacaoNutrienteService extends GenericService<RecomendacaoNutriente> {
  RecomendacaoNutrienteService() : super('recomendacoesNutrientes');

  @override
  RecomendacaoNutriente fromMap(Map<String, dynamic> map, String documentId) {
    return RecomendacaoNutriente.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RecomendacaoNutriente nutriente) {
    return nutriente.toMap();
  }

  Future<List<RecomendacaoNutriente>> getNutrientesPorRecomendacao(
      String recomendacaoId,
      ) async {
    try {
      return await getByAttributes({
        'recomendacaoId': recomendacaoId,
      }, orderBy: [
        {'field': 'nutriente', 'direction': 'asc'}
      ]);
    } catch (e) {
      print('Erro ao buscar nutrientes da recomendação: $e');
      return [];
    }
  }

  Future<void> salvarRecomendacoesNutrientes(
      String recomendacaoId,
      Map<String, RecomendacaoNutriente> nutrientes,
      ) async {
    try {
      // Deleta recomendações anteriores
      await deleteByAttribute({'recomendacaoId': recomendacaoId});

      // Batch para salvar novas recomendações
      final batch = FirebaseFirestore.instance.batch();

      for (var nutriente in nutrientes.values) {
        final docRef = getCollectionReference().doc();
        batch.set(
          docRef,
          nutriente
              .copyWith(
            id: docRef.id,
            recomendacaoId: recomendacaoId,
          )
              .toMap(),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao salvar recomendações de nutrientes: $e');
      rethrow;
    }
  }

  Future<void> atualizarRecomendacaoNutriente(
      String nutrienteId,
      Map<String, dynamic> alteracoes,
      ) async {
    try {
      final nutriente = await getById(nutrienteId);
      if (nutriente == null) {
        throw Exception('Recomendação de nutriente não encontrada');
      }

      await update(
        nutrienteId,
        nutriente.copyWith(
          doseRecomendada: alteracoes['doseRecomendada'] != null ?
          (alteracoes['doseRecomendada'] as num).toDouble() : null,
          fonte: alteracoes['fonte'],
          observacoes: alteracoes['observacoes'] != null ?
          List<String>.from(alteracoes['observacoes']) : null,
        ),
      );
    } catch (e) {
      print('Erro ao atualizar recomendação de nutriente: $e');
      rethrow;
    }
  }
}