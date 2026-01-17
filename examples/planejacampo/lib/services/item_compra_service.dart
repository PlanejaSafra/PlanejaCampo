import 'package:planejacampo/models/item_compra.dart';
import 'generic_service.dart';

class ItemCompraService extends GenericService<ItemCompra> {
  ItemCompraService() : super('itensCompra');

  @override
  ItemCompra fromMap(Map<String, dynamic> map, String documentId) {
    return ItemCompra.fromMap(map, documentId);
  }

  @override
  Map<String, dynamic> toMap(ItemCompra itemCompra) {
    return itemCompra.toMap();
  }

}

