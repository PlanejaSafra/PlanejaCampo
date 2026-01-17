import 'package:planejacampo/models/frota.dart';
import 'generic_service.dart';

class FrotaService extends GenericService<Frota> {
  FrotaService() : super('frotas');

  @override
  Frota fromMap(Map<String, dynamic> map, String documentId) {
    return Frota.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Frota frota) {
    return frota.toMap();
  }
}
