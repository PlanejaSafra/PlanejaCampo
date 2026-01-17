// lib/services/agro/adubacao/recomendacao_gessagem_service.dart
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/services/generic_service.dart';

class RecomendacaoGessagemService extends GenericService<RecomendacaoGessagem> {
  RecomendacaoGessagemService() : super('recomendacoesGessagem');

  @override
  RecomendacaoGessagem fromMap(Map<String, dynamic> map, String documentId) {
    return RecomendacaoGessagem.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RecomendacaoGessagem gessagem) {
    return gessagem.toMap();
  }

  Future<RecomendacaoGessagem?> getGessagemPorRecomendacao(
      String recomendacaoId,
      ) async {
    try {
      final recomendacoes = await getByAttributes({
        'recomendacaoId': recomendacaoId,
      });
      return recomendacoes.isNotEmpty ? recomendacoes.first : null;
    } catch (e) {
      print('Erro ao buscar recomendação de gessagem: $e');
      return null;
    }
  }

  Future<void> salvarRecomendacaoGessagem(
      String recomendacaoId,
      RecomendacaoGessagem gessagem,
      ) async {
    try {
      // Remove recomendação anterior se existir
      await deleteByAttribute({'recomendacaoId': recomendacaoId});

      // Salva nova recomendação
      final docRef = getCollectionReference().doc();
      await add(
        gessagem.copyWith(
          id: docRef.id,
          recomendacaoId: recomendacaoId,
        ),
      );
    } catch (e) {
      print('Erro ao salvar recomendação de gessagem: $e');
      rethrow;
    }
  }

  Future<void> atualizarRecomendacaoGessagem(
      String gessagemId,
      Map<String, dynamic> alteracoes,
      ) async {
    try {
      final gessagem = await getById(gessagemId);
      if (gessagem == null) {
        throw Exception('Recomendação de gessagem não encontrada');
      }

      await update(
        gessagemId,
        gessagem.copyWith(
          doseRecomendada: alteracoes['doseRecomendada'] != null ?
          (alteracoes['doseRecomendada'] as num).toDouble() : null,
          modoAplicacao: alteracoes['modoAplicacao'],
          parcelamento: alteracoes['parcelamento'],
          observacoes: alteracoes['observacoes'] != null ?
          List<String>.from(alteracoes['observacoes']) : null,
        ),
      );
    } catch (e) {
      print('Erro ao atualizar recomendação de gessagem: $e');
      rethrow;
    }
  }
}