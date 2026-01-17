import 'package:flutter/material.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ItemFormScreen extends StatefulWidget {
  final Item? item;

  const ItemFormScreen({super.key, this.item});

  @override
  _ItemFormScreenState createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Item _currentItem;
  late TextEditingController _nomeController;
  late TextEditingController _fatorDecaimentoController;
  late TextEditingController _descricaoController;
  final GlobalKey _detailFormKey = GlobalKey();
  late String _selectedTipo;
  late String _selectedCategoria;
  late String _selectedUnidadeMedida;
  late bool _movimentaEstoque; // Nova variável para controlar o estado
  late ItemService _itemService;
  bool _showTutorial = false;
  Object _returnObject = false;

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutor!.id;
    _itemService = ItemService();
    _currentItem = widget.item ?? Item(
      id: '',
      produtorId: produtorId,
      nome: '',
      tipo: ItemOptions.tipos[0],
      categoria: ItemOptions.categorias[0],
      unidadeMedida: ItemOptions.unidadesMedida[0],
      descricao: '',
    );
    _nomeController = TextEditingController(text: _currentItem.nome);
    _descricaoController = TextEditingController(text: _currentItem.descricao);
    _fatorDecaimentoController = FormatacaoUtil.getMaskedTextController(_currentItem.fatorDecaimento);
    _selectedTipo = _currentItem.tipo;
    _selectedCategoria = _currentItem.categoria;
    _selectedUnidadeMedida = _currentItem.unidadeMedida;
    _movimentaEstoque = _currentItem.movimentaEstoque; // Inicializa com o valor atual

    _showTutorial = appStateManager.showTutorial('itemFormScreen');
    appStateManager.setShowTutorial('itemFormScreen', false);
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_currentItem.id.isEmpty) {
        await _itemService.add(_currentItem);
      } else {
        await _itemService.update(_currentItem.id, _currentItem);
      }
      _returnObject = _currentItem;
      if (widget.item == null) {
        _returnObject = true;
      } else {
        _returnObject = _currentItem;
      }
      Navigator.of(context).pop(_returnObject);
      // Verifique se o widget ainda está montado antes de usar o contexto
      if (!mounted) return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final formatacaoUtil = appStateManager.formatacao;
    return FormTemplate(
      title: widget.item == null ? S.of(context).add_input_or_product : S.of(context).edit_input_or_product,
      formKey: _formKey,
      onSave: _saveItem,
      moduleName: 'itens',
      nomeTutorial: S.of(context).input_or_product,
      showTutorial: _showTutorial,
      isNewItem: widget.item == null,
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      customTutorialSteps: {
        'customItemForm': {
          'key': _detailFormKey,
          'message': S.of(context).click_to_edit(S.of(context).input_or_product),
          'shape': 'RRect',
          'align': 'ContentAlign.botton',
          'fatorReducaoQuadro': 0.6,
        },
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            key: _detailFormKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Identificação
              Row(
                children: [
                  Icon(Icons.inventory, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).identification,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Nome
              TextFormField(
                controller: _nomeController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).name,
                  suffixIcon: Icon(Icons.edit),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).enter_name;
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentItem = _currentItem.copyWith(nome: value ?? '');
                },
              ),
              SizedBox(height: 16),

              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).type,
                value: _selectedTipo,
                dropdownItems: ItemOptions.getLocalizedTipos(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipo = newValue ?? '';
                  });
                },
                onSaved: (value) {
                  if (value != null) {
                    _currentItem = _currentItem.copyWith(tipo: value);
                  }
                },
              ),
              SizedBox(height: 16),

              // Categoria
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).category,
                value: _selectedCategoria,
                dropdownItems: ItemOptions.getLocalizedCategorias(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoria = newValue ?? '';
                  });
                },
                onSaved: (value) {
                  if (value != null) {
                    _currentItem = _currentItem.copyWith(categoria: value);
                  }
                },
              ),
              SizedBox(height: 24),

              // Seção de Medidas
              Row(
                children: [
                  Icon(Icons.straighten, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).characteristics,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Unidade de Medida
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).unit_of_measure,
                value: _selectedUnidadeMedida,
                dropdownItems: ItemOptions.getLocalizedUnidadesMedida(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedUnidadeMedida = newValue ?? '';
                  });
                },
                onSaved: (value) {
                  if (value != null) {
                    _currentItem = _currentItem.copyWith(unidadeMedida: value);
                  }
                },
              ),
              SizedBox(height: 16),

              // Movimenta Estoque
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).inventory_movement,
                value: _movimentaEstoque ? "true" : "false",
                dropdownItems: [
                  DropdownMenuItem<String>(
                    value: "true",
                    child: Text(S.of(context).yes),
                  ),
                  DropdownMenuItem<String>(
                    value: "false",
                    child: Text(S.of(context).no),
                  ),
                ],
                onChanged: (String? newValue) {
                  setState(() {
                    _movimentaEstoque = newValue == "true";
                  });
                },
                onSaved: (value) {
                  _currentItem = _currentItem.copyWith(
                    movimentaEstoque: value == "true",
                  );
                },
              ),
              SizedBox(height: 16),

              // Fator de Decaimento
              TextFormField(
                controller: _fatorDecaimentoController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).decay_factor,
                  suffixIcon: Icon(Icons.trending_down),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).enter_decay_factor;
                  }
                  return null;
                },
                inputFormatters: [formatacaoUtil.decimalInputFormatter],
                onSaved: (value) {
                  _currentItem = _currentItem.copyWith(
                      fatorDecaimento: formatacaoUtil.parseNumber(value ?? '0')
                  );
                },
              ),
              SizedBox(height: 24),

              // Seção de Descrição
              Row(
                children: [
                  Icon(Icons.description, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).details,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).description,
                  suffixIcon: Icon(Icons.text_fields),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                onSaved: (value) {
                  _currentItem = _currentItem.copyWith(descricao: value);
                },
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}