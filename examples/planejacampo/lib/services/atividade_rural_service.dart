import 'package:planejacampo/models/atividade_rural.dart';
import 'generic_service.dart';

class AtividadeRuralService extends GenericService<AtividadeRural> {
  AtividadeRuralService() : super('atividadesRurais');

  @override
  AtividadeRural fromMap(Map<String, dynamic> map, String documentId) {
    return AtividadeRural.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(AtividadeRural atividadeRural) {
    return atividadeRural.toMap();
  }
}
