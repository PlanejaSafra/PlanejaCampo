import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:planejacampo/models/manutencao_frota.dart';
import 'package:planejacampo/models/item_manutencao_frota.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/services/item_manutencao_frota_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/object_template.dart';

class ItemManutencaoFrotaFormScreen extends StatefulWidget {
  final ItemManutencaoFrota? itemManutencaoFrota;
  final ManutencaoFrota manutencaoFrota;

  const ItemManutencaoFrotaFormScreen({
    Key? key,
    this.itemManutencaoFrota,
    required this.manutencaoFrota,
  }) : super(key: key);

  @override
  _ItemManutencaoFrotaFormScreenState createState() => _ItemManutencaoFrotaFormScreenState();
}

class _ItemManutencaoFrotaFormScreenState extends State<ItemManutencaoFrotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ItemManutencaoFrota _currentItemManutencao;

  // Controllers
  final TextEditingController _itemController = TextEditingController();
  late TextEditingController _quantidadeController;
  final TextEditingController _unidadeMedidaController = TextEditingController();
  final TextEditingController _propriedadeController = TextEditingController();
  final TextEditingController _cmpAtualController = TextEditingController();

  // Services
  final ItemManutencaoFrotaService _itemManutencaoService = ItemManutencaoFrotaService();
  final ItemService _itemService = ItemService();
  final EstoqueService _estoqueService = EstoqueService();

  String? _selectedItemId;
  String _selectedPropriedadeId = '';
  String _tipoMovimentacao = 'Saida';
  String _categoriaMovimentacao = 'Consumo';

  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  Object _returnObject = false;

  // Keys para tutorial e elementos UI
  final GlobalKey _itemManutencaoFormKey = GlobalKey();
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _itemKey = GlobalKey();
  final GlobalKey _quantidadeKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('frotas');
    _canDelete = appStateManager.canDelete('frotas');
    _showTutorial = appStateManager.showTutorial('itemManutencaoFrotaFormScreen');
    appStateManager.setShowTutorial('itemManutencaoFrotaFormScreen', false);

    _currentItemManutencao = widget.itemManutencaoFrota ??
        ItemManutencaoFrota(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId!,
          manutencaoFrotaId: widget.manutencaoFrota.id,
          propriedadeId: appStateManager.activePropriedadeId!,
          itemId: '',
          dataUtilizacao: widget.manutencaoFrota.data,
          quantidadeUtilizada: 0,
          unidadeMedida: '',
          cmpAtual: 0,
          unidadeMedidaCMP: '',
          tipoMovimentacaoEstoque: _tipoMovimentacao,
          categoriaMovimentacaoEstoque: _categoriaMovimentacao,
        );

    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _quantidadeController = FormatacaoUtil.getMaskedTextController(_currentItemManutencao.quantidadeUtilizada);
    _selectedItemId = _currentItemManutencao.itemId;
    _selectedPropriedadeId = _currentItemManutencao.propriedadeId;
    _tipoMovimentacao = _currentItemManutencao.tipoMovimentacaoEstoque;
    _categoriaMovimentacao = _currentItemManutencao.categoriaMovimentacaoEstoque;
    _unidadeMedidaController.text = _currentItemManutencao.unidadeMedida;
  }

  void _loadInitialData() {
    _loadItemDetails();
    _loadPropriedadeDetails();
    _updateCMPAtual();
  }

  void _loadItemDetails() async {
    if (_selectedItemId != null && _selectedItemId!.isNotEmpty) {
      final item = await _itemService.getById(_selectedItemId!);
      if (item != null && mounted) {
        setState(() {
          _itemController.text = item.nome;
          if (widget.itemManutencaoFrota == null) {
            _unidadeMedidaController.text = item.unidadeMedida;
          }
          _hasChanges = true;
        });
        _updateCMPAtual();
      }
    }
  }

  void _loadPropriedadeDetails() async {
    if (_selectedPropriedadeId.isNotEmpty) {
      final propriedade = await PropriedadeService().getById(_selectedPropriedadeId);
      if (propriedade != null && mounted) {
        setState(() {
          _propriedadeController.text = propriedade.nome;
          _hasChanges = true;
        });
      }
    }
  }

  void _updateCMPAtual() async {
    if (_selectedItemId != null && _selectedPropriedadeId.isNotEmpty) {
      final mapEstoqueAnterior = await _estoqueService.getEstoqueAnterior(
        propriedadeId: _selectedPropriedadeId,
        itemId: _selectedItemId!,
        dataReferencia: widget.manutencaoFrota.data,
      );

      if (mapEstoqueAnterior.isNotEmpty && mounted) {
        String unidadeMedidaOrigem = mapEstoqueAnterior['unidadeMedidaCMP'];
        String unidadeMedidaDestino = _unidadeMedidaController.text;
        double cmpOriginal = mapEstoqueAnterior['cmp'];

        if (unidadeMedidaOrigem != unidadeMedidaDestino) {
          double valorConvertido = _estoqueService.converterUnidadeMedida(
            1.0,
            unidadeMedidaOrigem,
            unidadeMedidaDestino,
          );

          double cmpConvertido = cmpOriginal / valorConvertido;

          setState(() {
            _cmpAtualController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(cmpConvertido);
            _hasChanges = true;
          });
        } else {
          setState(() {
            _cmpAtualController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(cmpOriginal);
            _hasChanges = true;
          });
        }
      } else if (mounted) {
        setState(() {
          _cmpAtualController.text = '0.00';
          _hasChanges = true;
        });
      }
    }
  }

  Future<void> _selectItem() async {
    final selectedItem = await Navigator.push<Item>(
      context,
      MaterialPageRoute(
        builder: (context) => ItensListScreen(isSelectMode: true),
      ),
    );

    if (selectedItem != null && mounted) {
      setState(() {
        _selectedItemId = selectedItem.id;
        _itemController.text = selectedItem.nome;
        _unidadeMedidaController.text = selectedItem.unidadeMedida;
        _hasChanges = true;
      });
      _updateCMPAtual();
    }
  }

  Future<void> _saveItemManutencao() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          // Monta o objeto em memória
          _currentItemManutencao = _currentItemManutencao.copyWith(
            itemId: _selectedItemId ?? '',
            propriedadeId: _selectedPropriedadeId,
            quantidadeUtilizada: FormatacaoUtil.instance.parseNumber(_quantidadeController.text),
            unidadeMedida: _unidadeMedidaController.text,
            cmpAtual: FormatacaoUtil.instance.parseNumber(_cmpAtualController.text),
            unidadeMedidaCMP: _unidadeMedidaController.text,
            tipoMovimentacaoEstoque: _tipoMovimentacao,
            categoriaMovimentacaoEstoque: _categoriaMovimentacao,
          );

          // Se for novo item, salva e pega o ID real
          if (widget.itemManutencaoFrota == null) {
            final newId = await _itemManutencaoService.add(_currentItemManutencao, returnId: true);
            _currentItemManutencao = _currentItemManutencao.copyWith(id: newId);
          } else {
            // Senão, atualiza
            await _itemManutencaoService.update(_currentItemManutencao.id, _currentItemManutencao);
          }

          if (!mounted) return;

          // Retorna o objeto ItemManutencaoFrota já salvo
          Navigator.of(context).pop(_currentItemManutencao);

        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_maintenance_item(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      // Sem permissão => pop(null)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).no_permission_to_save(S.of(context).maintenance_item),
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(null);
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentItemManutencao : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.itemManutencaoFrota == null ? S.of(context).add_maintenance_item : S.of(context).edit_maintenance_item,
        formKey: _formKey,
        onSave: _saveItemManutencao,
        moduleName: 'frotas',
        isNewItem: widget.itemManutencaoFrota == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        customTutorialSteps: _buildCustomTutorialSteps(),
        returnObject: _returnObject,
        onWillPop: () async => true,
        body: _buildFormBody(),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'customItemManutencaoForm': {
        'key': _itemManutencaoFormKey,
        'message': S.of(context).edit_maintenance_item_info,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'identificacao': {
        'key': _identificacaoKey,
        'message': '${S.of(context).identification} ${S.of(context).maintenance_item_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'item': {
        'key': _itemKey,
        'message': S.of(context).item_details_info,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'quantidade': {
        'key': _quantidadeKey,
        'message': '${S.of(context).quantity_and_weight} ${S.of(context).maintenance_item_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
    };
  }

  Widget _buildFormBody() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Identificação
            Row(
              children: [
                Icon(Icons.assignment, color: theme.colorScheme.primary),
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
            TextFormField(
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
                if (selectedPropriedade != null && mounted) {
                  setState(() {
                    _propriedadeController.text = selectedPropriedade.nome;
                    _selectedPropriedadeId = selectedPropriedade.id;
                    _hasChanges = true;
                  });
                  _updateCMPAtual();
                }
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return S.of(context).select_stock_property;
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            // Seção do Item
            Row(
              children: [
                Icon(Icons.inventory, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  S.of(context).item,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _itemController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).item,
                suffixIcon: Icon(Icons.search),
              ),
              readOnly: true,
              enabled: widget.itemManutencaoFrota?.itemId == null,
              onTap: widget.itemManutencaoFrota?.itemId != null ? null : _selectItem,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return S.of(context).please_select_item;
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _unidadeMedidaController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).unit_of_measure,
                suffixIcon: Icon(Icons.straighten),
              ),
              readOnly: true,
              onTap: _selectUnidadeMedida,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return S.of(context).select_unit_measure;
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            // Seção de Quantidade e CMP
            Row(
              children: [
                Icon(Icons.scale, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  S.of(context).quantity_and_weight,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _quantidadeController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).quantity,
                suffixIcon: Icon(Icons.monitor_weight),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                setState(() {
                  _hasChanges = true;
                });
              },
              validator: (value) {
                if (value?.isEmpty ?? true || FormatacaoUtil.instance.parseNumber(value!) <= 0) {
                  return S.of(context).please_enter_valid_number;
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _cmpAtualController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).cmp,
                suffixIcon: Icon(Icons.attach_money),
              ),
              readOnly: true,
              enabled: false,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectUnidadeMedida() async {
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

    if (selectedUnidadeMedida != null && mounted) {
      setState(() {
        _unidadeMedidaController.text = selectedUnidadeMedida;
        _hasChanges = true;
      });
      _updateCMPAtual();
    }
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantidadeController.dispose();
    _unidadeMedidaController.dispose();
    _propriedadeController.dispose();
    _cmpAtualController.dispose();
    super.dispose();
  }
}
