import 'package:planejacampo/models/talhao.dart';
import 'generic_service.dart';

class TalhaoService extends GenericService<Talhao> {
  TalhaoService() : super('talhoes');

  @override
  Talhao fromMap(Map<String, dynamic> map, String documentId) {
    return Talhao.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Talhao talhao) {
    return talhao.toMap();
  }


}
