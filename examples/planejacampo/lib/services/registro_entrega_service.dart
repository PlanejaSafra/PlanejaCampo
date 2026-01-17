import 'package:planejacampo/models/registro_entrega.dart';
import 'generic_service.dart';

class RegistroEntregaService extends GenericService<RegistroEntrega> {
  RegistroEntregaService() : super('registrosEntregas');

  @override
  RegistroEntrega fromMap(Map<String, dynamic> map, String documentId) {
    return RegistroEntrega.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(RegistroEntrega registroEntrega) {
    return registroEntrega.toMap();
  }
}
