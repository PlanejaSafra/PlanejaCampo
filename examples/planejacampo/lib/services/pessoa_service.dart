import 'package:planejacampo/models/pessoa.dart';
import 'generic_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class PessoaService extends GenericService<Pessoa> {
  PessoaService() : super('pessoas');

  @override
  Pessoa fromMap(Map<String, dynamic> map, String documentId) {
    return Pessoa.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Pessoa pessoa) {
    return pessoa.toMap();
  }

  Future<List<Pessoa>> getByVinculos(List<String> vinculos) async {
    final produtorId = AppStateManager().activeProdutor?.id;
    List<Pessoa> results = [];
    for (String vinculo in vinculos) {
      //if (vinculo == 'Diversos') {
      final pessoas = await getByAttributes({'produtorId': produtorId, 'vinculo': vinculo});
      //}
      results.addAll(pessoas);
    }
    return results;
  }

  Future<List<Pessoa>> getByDiversos() {
    return getByVinculos(['Diversos']);
  }

  Future<List<Pessoa>> getByVinculo(String vinculo) {
    return getByVinculos([vinculo, 'Diversos']);
  }

  Future<List<Pessoa>> getFornecedores() {
    return getByVinculos(['Fornecedor', 'Diversos']);
  }

  Future<List<Pessoa>> getClientes() {
    return getByVinculos(['Cliente', 'Diversos']);
  }

  Future<List<Pessoa>> getFuncionarios() {
    return getByVinculos(['Funcionário', 'Diversos']);
  }

  Future<List<Pessoa>> getParceiros() {
    return getByVinculos(['Parceiro', 'Diversos']);
  }
}
