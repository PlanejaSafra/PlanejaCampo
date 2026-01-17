// V02
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planejacampo/models/estoque.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/models/movimentacao_estoque.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/utils/movimentacao_estoque_options.dart';
import '../generic_service.dart';

class MovimentacaoEstoqueService extends GenericService<MovimentacaoEstoque> {
  // Serviços

  MovimentacaoEstoqueService() : super('movimentacoesEstoque');

  @override
  MovimentacaoEstoque fromMap(Map<String, dynamic> map, String documentId) {
    return MovimentacaoEstoque.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(MovimentacaoEstoque movimentacao) {
    final dataMap = movimentacao.toMap();
    dataMap['data'] = Timestamp.fromDate(movimentacao.data.toUtc());
    return dataMap;
  }

}
