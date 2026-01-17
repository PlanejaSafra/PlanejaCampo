// lib/services/agro/adubacao/resultado_analise_solo_service.dart

import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/services/generic_service.dart';

class ResultadoAnaliseSoloService extends GenericService<ResultadoAnaliseSolo> {
  ResultadoAnaliseSoloService() : super('resultadosAnalisesSolo');

  @override
  ResultadoAnaliseSolo fromMap(Map<String, dynamic> map, String documentId) {
    return ResultadoAnaliseSolo.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ResultadoAnaliseSolo resultado) {
    return resultado.toMap();
  }
}
