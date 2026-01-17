import 'package:planejacampo/models/item.dart';
import 'generic_service.dart';

class ItemService extends GenericService<Item> {
  ItemService() : super('itens');

  @override
  Item fromMap(Map<String, dynamic> map, String documentId) {
    return Item.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(Item item) {
    return item.toMap();
  }

  Future<bool> getItemMovimentaEstoque(String itemId) async {
    try {
      final item = await getById(itemId);
      return item?.movimentaEstoque ?? false;
    } catch (e) {
      throw Exception('Erro ao verificar movimentação de estoque para o item $itemId');
    }
  }

}
