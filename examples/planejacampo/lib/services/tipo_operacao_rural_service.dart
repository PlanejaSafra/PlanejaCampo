import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'generic_service.dart';

class TipoOperacaoRuralService extends GenericService<TipoOperacaoRural> {
  TipoOperacaoRuralService() : super('tiposOperacaoRural');

  @override
  TipoOperacaoRural fromMap(Map<String, dynamic> map, String documentId) {
    return TipoOperacaoRural.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(TipoOperacaoRural tipoOperacao) {
    return tipoOperacao.toMap();
  }

// Métodos adicionais específicos para TipoOperacaoRural podem ser adicionados aqui
}
