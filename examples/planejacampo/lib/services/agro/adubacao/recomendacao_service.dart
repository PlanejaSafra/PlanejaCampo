// lib/services/agro/adubacao/recomendacao_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_nutriente.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_calagem.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao_gessagem.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_calagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_gessagem_service.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_nutriente_service.dart';
import 'package:planejacampo/services/generic_service.dart';

class RecomendacaoService extends GenericService<Recomendacao> {
  final RecomendacaoNutrienteService _recomendacaoNutrienteService = RecomendacaoNutrienteService();
  final RecomendacaoCalagemService _recomendacaoCalagememService = RecomendacaoCalagemService();
  final RecomendacaoGessagemService _recomendacaoGessagemService = RecomendacaoGessagemService();

  RecomendacaoService() : super('recomendacoes');

  @override
  Recomendacao fromMap(Map<String, dynamic> map, String documentId) {
    return Recomendacao.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Recomendacao recomendacao) {
    return recomendacao.toMap();
  }

  Future<void> registrarRecomendacao({
    required Recomendacao recomendacao,
    required List<RecomendacaoNutriente> nutrientes,
    RecomendacaoCalagem? calagem,
    RecomendacaoGessagem? gessagem,
  }) async {
    try {
      // Registra recomendação principal
      String? recomendacaoId = await add(recomendacao, returnId: true);

      if (recomendacaoId == null) {
        throw Exception('Falha ao criar recomendação: ID não retornado');
      }

      // Registra nutrientes
      await _recomendacaoNutrienteService.salvarRecomendacoesNutrientes(
        recomendacaoId,
        Map.fromEntries(nutrientes.map((n) => MapEntry(n.nutriente, n))),
      );

      // Registra calagem se houver
      if (calagem != null) {
        await _recomendacaoCalagememService.salvarRecomendacaoCalagem(
          recomendacaoId,
          calagem,
        );
      }

      // Registra gessagem se houver
      if (gessagem != null) {
        await _recomendacaoGessagemService.salvarRecomendacaoGessagem(
          recomendacaoId,
          gessagem,
        );
      }
    } catch (e) {
      print('Erro ao registrar recomendação completa: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRecomendacaoCompleta(String recomendacaoId) async {
    try {
      // Busca recomendação principal
      final recomendacao = await getById(recomendacaoId);
      if (recomendacao == null) {
        throw Exception('Recomendação não encontrada');
      }

      // Busca nutrientes
      final nutrientes = await _recomendacaoNutrienteService.getNutrientesPorRecomendacao(
        recomendacaoId,
      );

      // Busca calagem
      final calagem = await _recomendacaoCalagememService.getCalagemPorRecomendacao(
        recomendacaoId,
      );

      // Busca gessagem
      final gessagem = await _recomendacaoGessagemService.getGessagemPorRecomendacao(
        recomendacaoId,
      );

      return {
        'recomendacao': recomendacao,
        'nutrientes': nutrientes,
        'calagem': calagem,
        'gessagem': gessagem,
      };
    } catch (e) {
      print('Erro ao buscar recomendação completa: $e');
      rethrow;
    }
  }

  Future<List<Recomendacao>> getRecomendacoesTalhao(String talhaoId) async {
    try {
      return await getByAttributes(
        {'talhaoId': talhaoId},
        orderBy: [{'field': 'dataRecomendacao', 'direction': 'desc'}],
      );
    } catch (e) {
      print('Erro ao buscar recomendações do talhão: $e');
      return [];
    }
  }

  Future<List<Recomendacao>> getRecomendacoesPeriodo(
      String talhaoId,
      DateTime inicio,
      DateTime fim,
      ) async {
    try {
      return await getByAttributesWithOperators(
        {
          'talhaoId': [{'operator': '==', 'value': talhaoId}],
          'dataRecomendacao': [
            {'operator': '>=', 'value': Timestamp.fromDate(inicio)},
            {'operator': '<=', 'value': Timestamp.fromDate(fim)},
          ],
        },
        orderBy: [{'field': 'dataRecomendacao', 'direction': 'desc'}],
      );
    } catch (e) {
      print('Erro ao buscar recomendações por período: $e');
      return [];
    }
  }

  Future<void> atualizarRecomendacao({
    required String recomendacaoId,
    required Recomendacao recomendacaoAtual,
    required List<RecomendacaoNutriente> nutrientes,
    RecomendacaoCalagem? calagem,
    RecomendacaoGessagem? gessagem,
    bool atualizarRecomendacao = true,
    bool atualizarNutrientes = true,
    bool atualizarCalagem = true,
    bool atualizarGessagem = true,
  }) async {
    try {
      // Atualiza recomendação principal
      if (atualizarRecomendacao) {
        await update(recomendacaoId, recomendacaoAtual);
      }

      // Atualiza nutrientes
      if (atualizarNutrientes) {
        await _recomendacaoNutrienteService.salvarRecomendacoesNutrientes(
          recomendacaoId,
          Map.fromEntries(nutrientes.map((n) => MapEntry(n.nutriente, n))),
        );
      }

      // Atualiza calagem
      if (atualizarCalagem) {
        if (calagem != null) {
          await _recomendacaoCalagememService.salvarRecomendacaoCalagem(
            recomendacaoId,
            calagem,
          );
        } else {
          await _recomendacaoCalagememService.deleteByAttribute({
            'recomendacaoId': recomendacaoId,
          });
        }
      }

      // Atualiza gessagem
      if (atualizarGessagem) {
        if (gessagem != null) {
          await _recomendacaoGessagemService.salvarRecomendacaoGessagem(
            recomendacaoId,
            gessagem,
          );
        } else {
          await _recomendacaoGessagemService.deleteByAttribute({
            'recomendacaoId': recomendacaoId,
          });
        }
      }
    } catch (e) {
      print('Erro ao atualizar recomendação completa: $e');
      rethrow;
    }
  }

  Future<void> excluirRecomendacao(String recomendacaoId) async {
    try {
      // Exclui nutrientes
      await _recomendacaoNutrienteService.deleteByAttribute({
        'recomendacaoId': recomendacaoId,
      });

      // Exclui calagem
      await _recomendacaoCalagememService.deleteByAttribute({
        'recomendacaoId': recomendacaoId,
      });

      // Exclui gessagem
      await _recomendacaoGessagemService.deleteByAttribute({
        'recomendacaoId': recomendacaoId,
      });

      // Exclui recomendação principal
      await delete(recomendacaoId);
    } catch (e) {
      print('Erro ao excluir recomendação completa: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> clonarRecomendacao(
      String recomendacaoId,
      DateTime novaData,
      ) async {
    try {
      // Busca recomendação original
      final recomendacaoOriginal = await getRecomendacaoCompleta(recomendacaoId);
      if (recomendacaoOriginal['recomendacao'] == null) {
        throw Exception('Recomendação original não encontrada');
      }

      // Cria nova recomendação com data atualizada
      final novaRecomendacao = (recomendacaoOriginal['recomendacao'] as Recomendacao).copyWith(
        id: '',
        dataRecomendacao: novaData,
      );

      // Registra nova recomendação
      await registrarRecomendacao(
        recomendacao: novaRecomendacao,
        nutrientes: recomendacaoOriginal['nutrientes'] as List<RecomendacaoNutriente>,
        calagem: recomendacaoOriginal['calagem'] as RecomendacaoCalagem?,
        gessagem: recomendacaoOriginal['gessagem'] as RecomendacaoGessagem?,
      );

      return recomendacaoOriginal;
    } catch (e) {
      print('Erro ao clonar recomendação: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getHistoricoRecomendacoes(String talhaoId) async {
    try {
      // Busca todas recomendações do talhão
      final recomendacoes = await getRecomendacoesTalhao(talhaoId);
      List<Map<String, dynamic>> historico = [];

      // Para cada recomendação, busca detalhes completos
      for (var recomendacao in recomendacoes) {
        final detalhes = await getRecomendacaoCompleta(recomendacao.id);
        historico.add(detalhes);
      }

      return historico;
    } catch (e) {
      print('Erro ao buscar histórico de recomendações: $e');
      return [];
    }
  }
}