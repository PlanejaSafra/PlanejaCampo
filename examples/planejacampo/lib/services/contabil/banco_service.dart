import 'package:planejacampo/models/contabil/banco.dart';
import '../generic_service.dart';

class BancoService extends GenericService<Banco> {
  BancoService() : super('bancos');

  @override
  Banco fromMap(Map<String, dynamic> map, String documentId) {
    return Banco.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Banco banco) {
    return banco.toMap();
  }
}
