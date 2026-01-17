import 'package:planejacampo/models/propriedade.dart';
import 'generic_service.dart';

class PropriedadeService extends GenericService<Propriedade> {
  PropriedadeService() : super('propriedades');

  @override
  Propriedade fromMap(Map<String, dynamic> map, String documentId) {
    return Propriedade.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Propriedade propriedade) {
    return propriedade.toMap();
  }
}
