import 'package:planejacampo/models/registro_chuva.dart';
import 'generic_service.dart';

class RegistroChuvaService extends GenericService<RegistroChuva> {
  RegistroChuvaService() : super('registrosChuvas');

  @override
  RegistroChuva fromMap(Map<String, dynamic> map, String documentId) {
    return RegistroChuva.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RegistroChuva registroChuva) {
    return registroChuva.toMap();
  }
}
