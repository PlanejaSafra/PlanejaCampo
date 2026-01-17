// lib/services/agro/adubacao/cultura_parametros_service.dart

import 'package:planejacampo/models/agro/adubacao/cultura_parametros.dart';
import 'package:planejacampo/models/agro/adubacao/cultura_parametros_factories.dart';
import 'package:planejacampo/models/enums.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CulturaParametrosService extends GenericService<CulturaParametros> {
  CulturaParametrosService() : super('culturasParametro');

  @override
  CulturaParametros fromMap(Map<String, dynamic> map, String documentId) {
    return CulturaParametros.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(CulturaParametros parametros) {
    return parametros.toMap();
  }

  /// Busca os parâmetros de adubação para uma cultura e um manual específico
  Future<CulturaParametros?> getParametrosCultura(
      TipoCultura cultura,
      String manualAdubacao,
      ) async {
    try {
      final parametros = await getByAttributes({
        'cultura': cultura.toString().split('.').last,
        'manualAdubacao': manualAdubacao,
      });

      if (parametros.isNotEmpty) {
        return parametros.first;
      }

      // Se não encontrou, cria novos parâmetros usando o factory específico da cultura
      CulturaParametros? novosParametros;

      switch (cultura) {
        case TipoCultura.SOJA:
          novosParametros = CulturaParametrosFactories.soja(
            id: '',
            manualAdubacao: manualAdubacao,
          );
          break;
        case TipoCultura.CANA_DE_ACUCAR:
          novosParametros = CulturaParametrosFactories.canaDeAcucar(
            id: '',
            manualAdubacao: manualAdubacao,
          );
          break;
        case TipoCultura.MILHO_GRAO:  // ADD THIS CASE
          novosParametros = CulturaParametrosFactories.milhoGrao(
            id: '',
            manualAdubacao: manualAdubacao,
          );
          break;
      // Adicionar outros cases conforme novas culturas forem implementadas
        default:
          throw Exception('Cultura ${cultura.toString()} não suportada');
      }


      if (novosParametros != null) {
        print('Tentando salvar novos parâmetros para ${cultura.toString()}');
        try {
          await add(novosParametros);
          print('Parâmetros salvos com sucesso');
          return novosParametros;
        } catch (e) {
          print('Erro ao salvar parâmetros: ${e.toString()}');
          return novosParametros; // Retorna mesmo assim para não quebrar o fluxo
        }
      }

      return null;
    } catch (e) {
      print('Erro ao buscar/criar parâmetros da cultura: ${e.toString()}');
      return null;
    }
  }

  /// Busca todos os parâmetros de um manual de adubação específico
  Future<List<CulturaParametros>> getParametrosManual(
      String manualAdubacao,
      String produtorId,
      ) async {
    try {
      return await getByAttributes(
        {'manualAdubacao': manualAdubacao, 'produtorId': produtorId},
        orderBy: [{'field': 'cultura', 'direction': 'asc'}],
      );
    } catch (e) {
      print('Erro ao buscar parâmetros do manual: \$e');
      return [];
    }
  }

  /// Salva ou atualiza parâmetros para uma cultura
  Future<void> salvarParametrosCultura(
      TipoCultura cultura,
      String manualAdubacao,
      String produtorId,
      ) async {
    try {
      var parametros = await getParametrosCultura(
        cultura,
        manualAdubacao,
      );

      // Se não existir, cria novo com valores específicos da cultura
      if (parametros == null) {
        CulturaParametros? novosParametros;

        switch (cultura) {
          case TipoCultura.SOJA:
            novosParametros = CulturaParametrosFactories.soja(
              id: '',
              manualAdubacao: manualAdubacao,
            );
            break;
          case TipoCultura.CANA_DE_ACUCAR:
            novosParametros = CulturaParametrosFactories.canaDeAcucar(
              id: '',
              manualAdubacao: manualAdubacao,
            );
            break;
          case TipoCultura.MILHO_GRAO:  // ADD THIS CASE
            novosParametros = CulturaParametrosFactories.milhoGrao(
              id: '',
              manualAdubacao: manualAdubacao,
            );
            break;
          default:
            throw Exception('Cultura ${cultura.toString()} não suportada');
        }

        if (novosParametros != null) {
          await add(novosParametros);
        }
      }
    } catch (e) {
      print('Erro ao salvar parâmetros da cultura: $e');
      rethrow;
    }
  }

  /// Atualiza parâmetros específicos de uma cultura
  Future<void> atualizarParametros(
      String parametrosId,
      Map<String, dynamic> alteracoes,
      ) async {
    try {
      final parametros = await getById(parametrosId);
      if (parametros == null) {
        throw Exception('Parâmetros não encontrados: $parametrosId');
      }

      // Ajustes nas recomendações de gessagem para evitar doses muito altas sem parcelamento
      if (alteracoes.containsKey('parametrosGessagem')) {
        final gessagem = alteracoes['parametrosGessagem'];
        if (gessagem != null && gessagem['dose_maxima'] != null && gessagem['dose_maxima'] > 4.0) {
          print('Aviso: Dose de gesso acima de 4 t/ha deve ser parcelada.');
          gessagem['dose_maxima'] = 4.0;
        }
      }

      await update(
        parametrosId,
        parametros.copyWith(
          parametrosCalagem: alteracoes['parametrosCalagem'] ?? parametros.parametrosCalagem,
          parametrosGessagem: alteracoes['parametrosGessagem'] ?? parametros.parametrosGessagem,
          recomendacaoNPK: alteracoes['recomendacaoNPK'] != null
              ? Map<String, Map<double, Map<String, double>>>.from(
            (alteracoes['recomendacaoNPK'] as Map).map(
                  (nutriente, prodMap) => MapEntry(
                nutriente.toString(),
                (prodMap as Map).map(
                      (prod, interpMap) => MapEntry(
                    double.parse(prod.toString()),
                    (interpMap as Map).map(
                          (interp, dose) => MapEntry(
                        interp.toString(),
                        (dose is num) ? dose.toDouble() : 0.0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
              : null,
          // Adicione outras alterações conforme necessidade
        ),
      );
    } catch (e) {
      print('Erro ao atualizar parâmetros: $e');
      rethrow;
    }
  }

  /// Valida os parâmetros de uma cultura
  Future<Map<String, dynamic>> validarParametros(CulturaParametros parametros) async {
    List<String> erros = [];
    List<String> avisos = [];

    if (parametros.produtividadeMinima <= 0) {
      erros.add('Produtividade mínima deve ser maior que zero');
    }

    if (parametros.produtividadeMaxima <= parametros.produtividadeMinima) {
      erros.add('Produtividade máxima deve ser maior que a mínima');
    }

    if (parametros.recomendacaoNPK.isEmpty) {
      erros.add('Recomendação de NPK não definida');
    }

    if (parametros.teoresCriticosMacro.isEmpty || parametros.teoresCriticosMicro.isEmpty) {
      erros.add('Teores críticos não definidos');
    }

    if (parametros.parametrosCalagem.isEmpty || parametros.parametrosGessagem.isEmpty) {
      avisos.add('Parâmetros de correção do solo incompletos');
    }

    if (parametros.fatorAjusteDoses.isEmpty) {
      avisos.add('Fatores de ajuste não definidos');
    }

    if (parametros.parametrosGessagem['dose_maxima'] != null && parametros.parametrosGessagem['dose_maxima'] > 4.0) {
      avisos.add('Dose de gesso acima de 4 t/ha deve ser parcelada');
    }

    return {
      'valido': erros.isEmpty,
      'erros': erros,
      'avisos': avisos,
    };
  }

  /// Copia os parâmetros de um manual para outro
  Future<void> copiarParametrosManual(
      String manualOrigem,
      String manualDestino,
      String produtorId,
      ) async {
    try {
      final parametrosOrigem = await getParametrosManual(manualOrigem, produtorId);

      final batch = FirebaseFirestore.instance.batch();

      for (var parametro in parametrosOrigem) {
        final docRef = getCollectionReference().doc();
        batch.set(
          docRef,
          parametro.copyWith(
            id: docRef.id,
            manualAdubacao: manualDestino,
          ).toMap(),
        );
      }

      await batch.commit();
    } catch (e) {
      print('Erro ao copiar parâmetros: \$e');
      rethrow;
    }
  }
}
