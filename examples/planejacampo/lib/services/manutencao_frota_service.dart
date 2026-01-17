import 'package:planejacampo/models/manutencao_frota.dart';
import 'generic_service.dart';

class ManutencaoFrotaService extends GenericService<ManutencaoFrota> {
  ManutencaoFrotaService() : super('manutencoesFrota');

  @override
  ManutencaoFrota fromMap(Map<String, dynamic> map, String documentId) {
    return ManutencaoFrota.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ManutencaoFrota manutencaoFrota) {
    return manutencaoFrota.toMap();
  }
}
