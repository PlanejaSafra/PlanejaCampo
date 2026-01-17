import 'package:planejacampo/models/frota_operacao_rural.dart';
import 'generic_service.dart';

class FrotaOperacaoRuralService extends GenericService<FrotaOperacaoRural> {
  FrotaOperacaoRuralService() : super('frotaOperacoesRurais');

  @override
  FrotaOperacaoRural fromMap(Map<String, dynamic> map, String documentId) {
    return FrotaOperacaoRural.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(FrotaOperacaoRural frotaOperacaoRural) {
    return frotaOperacaoRural.toMap();
  }

// Adicione métodos específicos se necessário
}
