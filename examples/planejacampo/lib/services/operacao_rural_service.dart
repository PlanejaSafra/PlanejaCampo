import 'package:planejacampo/models/operacao_rural.dart';
import 'generic_service.dart';

class OperacaoRuralService extends GenericService<OperacaoRural> {
  OperacaoRuralService() : super('operacoesRurais');

  @override
  OperacaoRural fromMap(Map<String, dynamic> map, String documentId) {
    return OperacaoRural.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(OperacaoRural operacaoRural) {
    return operacaoRural.toMap();
  }

  Future<bool> hasTalhaoVinculado(String atividadeId, String talhaoId) async {
    
    List<OperacaoRural> operacoes = await getByAttributes({
      'atividadeId': atividadeId,
    });
    for (OperacaoRural operacao in operacoes) {
      if (operacao.talhoes != null) {
        for (String thisTalhaoId in operacao.talhoes!) {
          if (thisTalhaoId == talhaoId) {
            return true;
          }
        }
      }
    }
    return false;
  }
}
