// lib/services/agro/adubacao/recomendacao_calagem_service.dart
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/services/generic_service.dart';

class RecomendacaoCalagemService extends GenericService<RecomendacaoCalagem> {
  RecomendacaoCalagemService() : super('recomendacoesCalagem');

  @override
  RecomendacaoCalagem fromMap(Map<String, dynamic> map, String documentId) {
    return RecomendacaoCalagem.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RecomendacaoCalagem calagem) {
    return calagem.toMap();
  }

  Future<RecomendacaoCalagem?> getCalagemPorRecomendacao(
      String recomendacaoId,
      ) async {
    try {
      final recomendacoes = await getByAttributes({
        'recomendacaoId': recomendacaoId,
      });
      return recomendacoes.isNotEmpty ? recomendacoes.first : null;
    } catch (e) {
      print('Erro ao buscar recomendação de calagem: $e');
      return null;
    }
  }

  Future<void> salvarRecomendacaoCalagem(
      String recomendacaoId,
      RecomendacaoCalagem calagem,
      ) async {
    try {
      // Remove recomendação anterior se existir
      await deleteByAttribute({'recomendacaoId': recomendacaoId});

      // Salva nova recomendação
      final docRef = getCollectionReference().doc();
      await add(
        calagem.copyWith(
          id: docRef.id,
          recomendacaoId: recomendacaoId,
        ),
      );
    } catch (e) {
      print('Erro ao salvar recomendação de calagem: $e');
      rethrow;
    }
  }

  Future<void> atualizarRecomendacaoCalagem(
      String calagemId,
      Map<String, dynamic> alteracoes,
      ) async {
    try {
      final calagem = await getById(calagemId);
      if (calagem == null) {
        throw Exception('Recomendação de calagem não encontrada');
      }

      await update(
        calagemId,
        calagem.copyWith(
          quantidadeRecomendada: alteracoes['quantidadeRecomendada'] != null ?
          (alteracoes['quantidadeRecomendada'] as num).toDouble() : null,
          tipoCalcario: alteracoes['tipoCalcario'],
          modoAplicacao: alteracoes['modoAplicacao'],
          parcelamento: alteracoes['parcelamento'],
          observacoes: alteracoes['observacoes'] != null ?
          List<String>.from(alteracoes['observacoes']) : null,
        ),
      );
    } catch (e) {
      print('Erro ao atualizar recomendação de calagem: $e');
      rethrow;
    }
  }
}