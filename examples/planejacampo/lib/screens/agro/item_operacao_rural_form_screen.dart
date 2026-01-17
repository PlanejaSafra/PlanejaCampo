import 'package:flutter/material.dart';
import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/estoques/movimentacao_estoque_service.dart';
import 'package:planejacampo/services/estoques/estoque_service.dart';
import 'package:planejacampo/utils/movimentacao_estoque_options.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';

class ItemOperacaoRuralFormScreen extends StatefulWidget {
  final ItemOperacaoRural? itemOperacaoRural;
  final OperacaoRural operacaoRural;

  const ItemOperacaoRuralFormScreen({
    Key? key,
    this.itemOperacaoRural,
    required this.operacaoRural,
  }) : super(key: key);

  @override
  _ItemOperacaoRuralFormScreenState createState() => _ItemOperacaoRuralFormScreenState();
}

class _ItemOperacaoRuralFormScreenState extends State<ItemOperacaoRuralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ItemOperacaoRural _currentItemOperacao;

  final TextEditingController _itemController = TextEditingController();
  late TextEditingController _quantidadeController;
  late TextEditingController _dataUtilizacaoController;
  final TextEditingController _unidadeMedidaController = TextEditingController();
  final TextEditingController _propriedadeController = TextEditingController();
  final TextEditingController _cmpAtualController = TextEditingController();

  final ItemService _itemService = ItemService();
  final EstoqueService _estoqueService = EstoqueService();
  final MovimentacaoEstoqueService _movimentacaoEstoqueService = MovimentacaoEstoqueService();

  String? _selectedItemId;
  String _selectedPropriedadeId = '';
  DateTime _dataUtilizacao = DateTime.now();
  String _tipoMovimentacao = 'Saida';
  String _categoriaMovimentacao = 'Consumo';
  bool _hasChanges = false;
  Object _returnObject = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);

    _initializeControllers();

    if (widget.itemOperacaoRural != null) {
      _initializeExistingItem();
    } else {
      _initializeNewItem(appStateManager);
    }

    _loadInitialData();
  }

  void _initializeControllers() {
    _quantidadeController = FormatacaoUtil.getMaskedTextController(0);
    _dataUtilizacaoController = TextEditingController();
  }

  void _initializeExistingItem() {
    _currentItemOperacao = widget.itemOperacaoRural!;

    setState(() {
      _tipoMovimentacao = _currentItemOperacao.tipoMovimentacaoEstoque;
      _categoriaMovimentacao = _currentItemOperacao.categoriaMovimentacaoEstoque;
      _selectedItemId = _currentItemOperacao.itemId;
      _quantidadeController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_currentItemOperacao.quantidadeUtilizada);
      _dataUtilizacao = _currentItemOperacao.dataUtilizacao;
      _dataUtilizacaoController.text = FormatacaoUtil.formatDate(_currentItemOperacao.dataUtilizacao);
      _unidadeMedidaController.text = _currentItemOperacao.unidadeMedida;
      _selectedPropriedadeId = _currentItemOperacao.propriedadeId;
    });
  }

  void _initializeNewItem(AppStateManager appStateManager) {
    _currentItemOperacao = ItemOperacaoRural(
      id: DateTime.now().toString(),
      operacaoRuralId: widget.operacaoRural.id,
      produtorId: appStateManager.activeProdutorId!,
      propriedadeId: widget.operacaoRural.propriedadeId,
      itemId: '',
      dataUtilizacao: _dataUtilizacao,
      quantidadeUtilizada: 0,
      unidadeMedida: '',
      cmpAtual: 0,
      unidadeMedidaCMP: '',
      tipoMovimentacaoEstoque: _tipoMovimentacao,
      categoriaMovimentacaoEstoque: _categoriaMovimentacao,
    );

    setState(() {
      _dataUtilizacaoController.text = FormatacaoUtil.formatDate(_dataUtilizacao);
      _selectedPropriedadeId = appStateManager.activePropriedadeId ?? '';
    });
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
          // Só atualiza a unidade de medida se for novo registro
          if (widget.itemOperacaoRural == null) {
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
        dataReferencia: _dataUtilizacao,
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dataUtilizacao,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != _dataUtilizacao && mounted) {
      setState(() {
        _dataUtilizacao = picked;
        _dataUtilizacaoController.text = FormatacaoUtil.formatDate(picked);
        _hasChanges = true;
      });
      _updateCMPAtual();
    }
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

  Future<void> _salvarItemOperacao() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final updatedItem = _currentItemOperacao.copyWith(
          id: widget.itemOperacaoRural?.id ?? DateTime.now().toString(),
          itemId: _selectedItemId ?? '',
          propriedadeId: _selectedPropriedadeId,
          dataUtilizacao: _dataUtilizacao,
          quantidadeUtilizada: FormatacaoUtil.instance.parseNumber(_quantidadeController.text),
          unidadeMedida: _unidadeMedidaController.text,
          cmpAtual: FormatacaoUtil.instance.parseNumber(_cmpAtualController.text),
          tipoMovimentacaoEstoque: _tipoMovimentacao,
          categoriaMovimentacaoEstoque: _categoriaMovimentacao,
        );

        Navigator.of(context).pop(updatedItem); // Retorna o item diretamente no pop

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_saving_operation(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(null);  // Retorna null ao cancelar
        return false;
      },
      child: FormTemplate(
        title: widget.itemOperacaoRural == null
            ? S.of(context).add_operation_item
            : S.of(context).edit_operation_item,
        formKey: _formKey,
        onSave: _salvarItemOperacao,
        moduleName: 'operacoesRurais',
        body: _buildFormBody(context),
        isNewItem: widget.itemOperacaoRural == null,
        returnObject: _returnObject,  // Passa o Object
        onWillPop: () async => true,
      ),
    );
  }

  Widget _buildFormBody(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIdentificacaoSection(theme),
            SizedBox(height: 24),
            _buildItemSection(theme),
            SizedBox(height: 24),
            _buildQuantidadeSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentificacaoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.assignment, S.of(context).identification),
        SizedBox(height: 16),
        _buildTipoMovimentacao(),
        SizedBox(height: 16),
        _buildCategoriaMovimentacao(),
        SizedBox(height: 16),
        _buildPropriedadeField(),
        SizedBox(height: 16),
        _buildDataUtilizacaoField(),
      ],
    );
  }

  Widget _buildItemSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.inventory, S.of(context).item),
        SizedBox(height: 16),
        _buildItemSelectionField(),
        SizedBox(height: 16),
        _buildUnidadeMedidaField(),
      ],
    );
  }

  Widget _buildQuantidadeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, Icons.scale, S.of(context).quantity_and_weight),
        SizedBox(height: 16),
        _buildQuantidadeField(),
        SizedBox(height: 16),
        _buildCMPField(),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTipoMovimentacao() {
    return ObjectTemplate.getDropdownButtonFormField(
      context: context,
      labelText: S.of(context).type,
      value: _tipoMovimentacao,
      items: MovimentacaoEstoqueOptions.tipo,
      onChanged: (String? newValue) {
        setState(() {
          _tipoMovimentacao = newValue ?? 'Saida';
          _categoriaMovimentacao = _tipoMovimentacao == 'Entrada' ? 'Colheita' : 'Consumo';
          _hasChanges = true;
        });
      },
    );
  }

  Widget _buildCategoriaMovimentacao() {
    return ObjectTemplate.getDropdownButtonFormField(
      context: context,
      labelText: S.of(context).category,
      value: _categoriaMovimentacao,
      items: MovimentacaoEstoqueOptions.categoria
          .where((categoria) => _tipoMovimentacao == 'Entrada' ? categoria.startsWith('Colheita') || categoria.startsWith('Bonificacao') : !categoria.startsWith('Colheita') && !categoria.startsWith('Bonificacao'))
          .toList(),
      onChanged: (String? newValue) {
        setState(() {
          _categoriaMovimentacao = newValue ?? (_tipoMovimentacao == 'Entrada' ? 'Colheita' : 'Consumo');
          _hasChanges = true;
        });
      },
    );
  }

  Widget _buildPropriedadeField() {
    return TextFormField(
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
    );
  }

  Widget _buildDataUtilizacaoField() {
    return TextFormField(
      controller: _dataUtilizacaoController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).usage_date,
        suffixIcon: Icon(Icons.calendar_today),
      ),
      readOnly: true,
      onTap: _selectDate,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return S.of(context).please_select_date;
        }
        return null;
      },
    );
  }

  Widget _buildItemSelectionField() {
    return TextFormField(
      controller: _itemController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).item,
        suffixIcon: Icon(Icons.search),
      ),
      readOnly: true,
      enabled: widget.itemOperacaoRural?.itemId == null,
      onTap: widget.itemOperacaoRural?.itemId != null ? null : _selectItem,
      validator: (value) {
        if (value?.isEmpty ?? true) {
          return S.of(context).please_select_item;
        }
        return null;
      },
    );
  }

  Widget _buildUnidadeMedidaField() {
    return TextFormField(
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
    );
  }

  Widget _buildQuantidadeField() {
    return TextFormField(
      controller: _quantidadeController,
      decoration: ObjectTemplate.getInputDecoration(
        context,
        S.of(context).quantity_used,
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
    );
  }

  Widget _buildCMPField() {
    return TextFormField(
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
    );
  }

  @override
  void dispose() {
    _itemController.dispose();
    _quantidadeController.dispose();
    _dataUtilizacaoController.dispose();
    _unidadeMedidaController.dispose();
    _propriedadeController.dispose();
    _cmpAtualController.dispose();
    super.dispose();
  }
}
