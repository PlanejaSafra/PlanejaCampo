import 'package:planejacampo/models/registro_coleta.dart';
import 'generic_service.dart';

class RegistroColetaService extends GenericService<RegistroColeta> {
  RegistroColetaService() : super('registrosColetas');

  @override
  RegistroColeta fromMap(Map<String, dynamic> map, String documentId) {
    return RegistroColeta.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RegistroColeta registroColeta) {
    return registroColeta.toMap();
  }
}
