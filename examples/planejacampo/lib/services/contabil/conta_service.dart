import 'package:planejacampo/models/contabil/conta.dart';
import '../generic_service.dart';

class ContaService extends GenericService<Conta> {
  ContaService() : super('contas');

  @override
  Conta fromMap(Map<String, dynamic> map, String documentId) {
    return Conta.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Conta conta) {
    return conta.toMap();
  }
}
