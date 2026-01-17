import 'package:flutter/material.dart';
import 'package:planejacampo/models/item_compra.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/widgets/object_template.dart';


class ItemCompraFormScreen extends StatefulWidget {
  final ItemCompra? itemCompra; // Para edição de itens
  final Function(ItemCompra) onSave; // Função de callback para salvar o item
  final String? propriedadeId; // Propriedade ativa

  const ItemCompraFormScreen({
    Key? key,
    this.itemCompra,
    required this.onSave,
    this.propriedadeId,
  }) : super(key: key);

  @override
  _ItemCompraFormScreenState createState() => _ItemCompraFormScreenState();
}

class _ItemCompraFormScreenState extends State<ItemCompraFormScreen> {
  final TextEditingController _nomeItemController = TextEditingController();
  late TextEditingController _quantidadeController;
  late TextEditingController _precoUnitarioController;
  final TextEditingController _unidadeMedidaController = TextEditingController(); // Controlador para unidade de medida
  final TextEditingController _propriedadeController = TextEditingController();
  
  String _selectedPropriedadeId = '';
  String? _currentItemId;  // Variável para armazenar o ID do item selecionado

  @override
  void initState() {
    super.initState();
    
    _quantidadeController = FormatacaoUtil.getMaskedTextController(widget.itemCompra?.quantidade ?? 0);
    _precoUnitarioController = FormatacaoUtil.getMaskedTextController(widget.itemCompra?.precoUnitario ?? 0);

    _unidadeMedidaController.text = widget.itemCompra?.unidadeMedida ?? ''; // Carrega a unidade de medida da compra

    if (widget.itemCompra != null) {
      // Busca o nome do item com base no itemId
      ItemService().getById(widget.itemCompra!.itemId).then((item) {
        if (item != null) {
          setState(() {
            _nomeItemController.text = item.nome;  // Nome do item exibido no campo de texto
            _currentItemId = item.id;  // Armazena o ID real do item
          });
        }
      });
      _selectedPropriedadeId = widget.itemCompra!.propriedadeId;
    } else {
      // Para novos itens, use o propriedadeId fornecido ou o activePropriedadeId
      _selectedPropriedadeId = widget.propriedadeId ?? AppStateManager().activePropriedadeId ?? '';
    }

    // Carrega o nome da propriedade
    if (_selectedPropriedadeId.isNotEmpty) {
      _carregarNomePropriedade(_selectedPropriedadeId);
    }
  }

  void _carregarNomePropriedade(String propriedadeId) async {
    // Simula a busca da propriedade no banco de dados
    final propriedade = await PropriedadeService().getById(propriedadeId);
    if (propriedade != null) {
      setState(() {
        _propriedadeController.text = propriedade.nome;
      });
    }
  }

  void _selecionarItem() async {
    // Simula a busca de um item no banco de dados
    final selectedItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItensListScreen(isSelectMode: true),
      ),
    );
    if (selectedItem != null) {
      setState(() {
        _nomeItemController.text = selectedItem.nome;  // Atualiza o campo de texto com o nome do item
        _currentItemId = selectedItem.id;  // Atualiza o ID do item
        _unidadeMedidaController.text = selectedItem.unidadeMedida; // Carrega a unidade de medida padrão do item
      });
    }
  }

  void _selecionarUnidadeMedida() async {
    // Simula a escolha da unidade de medida a partir de uma lista
    final selectedUnidadeMedida = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).unit_of_measure),
          children: ItemOptions.unidadesMedida.map((unidade) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, unidade),
              child: Text(unidade),
            );
          }).toList(),
        );
      },
    );

    if (selectedUnidadeMedida != null) {
      setState(() {
        _unidadeMedidaController.text = selectedUnidadeMedida; // Atualiza o campo de unidade de medida
      });
    }
  }

  void _salvarItem() {
    final quantidade = NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).parse(_quantidadeController.text).toDouble();
    final precoUnitario = NumberFormat.decimalPattern(Localizations.localeOf(context).toString()).parse(_precoUnitarioController.text).toDouble();

    final ItemCompra novoItem = ItemCompra(
      id: widget.itemCompra?.id ?? DateTime.now().toString(),
      itemId: _currentItemId ?? '',  // Agora usamos o ID correto do item
      compraId: widget.itemCompra?.id ?? '',
      quantidade: quantidade,
      precoUnitario: precoUnitario,
      valorTotal: quantidade * precoUnitario,
      unidadeMedida: _unidadeMedidaController.text,  // Salva a unidade de medida selecionada
      propriedadeId: _selectedPropriedadeId,
      produtorId: AppStateManager().activeProdutorId!,
    );

    widget.onSave(novoItem);
    Navigator.of(context).pop(novoItem);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.itemCompra != null ? S.of(context).edit_input_or_product : S.of(context).add_input_or_product),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Local de Armazenamento
            TextField(
              controller: _propriedadeController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).stock_property,
                suffixIcon: Icon(Icons.business),
              ),
              readOnly: true,
              onTap: () async {
                final selectedPropriedade = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropriedadesListScreen(isSelectMode: true),
                  ),
                );
                if (selectedPropriedade != null) {
                  setState(() {
                    _propriedadeController.text = selectedPropriedade.nome;
                    _selectedPropriedadeId = selectedPropriedade.id;
                  });
                }
              },
            ),
            const SizedBox(height: 10),

            // Item
            GestureDetector(
              onTap: widget.itemCompra?.itemId != null ? null : _selecionarItem,
              child: AbsorbPointer(
                child: TextField(
                  controller: _nomeItemController,
                  enabled: widget.itemCompra?.itemId == null,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).item,
                    suffixIcon: Icon(Icons.inventory),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Unidade de Medida
            TextField(
              controller: _unidadeMedidaController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).unit_of_measure,
                suffixIcon: Icon(Icons.straighten),
              ),
              readOnly: true,
              onTap: _selecionarUnidadeMedida,
            ),
            const SizedBox(height: 10),

            // Quantidade
            TextField(
              controller: _quantidadeController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).quantity,
                suffixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),

            // Preço Unitário
            TextField(
              controller: _precoUnitarioController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).unit_price,
                suffixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text(S.of(context).cancel),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text(S.of(context).save),
          onPressed: _salvarItem,
        ),
      ],
    );
  }
}
