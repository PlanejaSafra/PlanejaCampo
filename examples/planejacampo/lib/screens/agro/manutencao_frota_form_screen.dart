import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/manutencao_frota.dart';
import 'package:planejacampo/models/item_manutencao_frota.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/services/manutencao_frota_service.dart';
import 'package:planejacampo/services/item_manutencao_frota_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/screens/agro/item_manutencao_frota_form_screen.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';

class ManutencaoFrotaFormScreen extends StatefulWidget {
  final ManutencaoFrota? manutencaoFrota;
  final Frota frota;

  const ManutencaoFrotaFormScreen({
    Key? key,
    this.manutencaoFrota,
    required this.frota,
  }) : super(key: key);

  @override
  _ManutencaoFrotaFormScreenState createState() => _ManutencaoFrotaFormScreenState();
}

class _ManutencaoFrotaFormScreenState extends State<ManutencaoFrotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ManutencaoFrota _currentManutencao;
  late MoneyMaskedTextController _horimetroController;
  late TextEditingController _observacoesController;
  late TextEditingController _dataController;
  late DateTime _data;

  // Services
  final ManutencaoFrotaService _manutencaoService = ManutencaoFrotaService();
  final ItemManutencaoFrotaService _itemManutencaoService = ItemManutencaoFrotaService();
  final ItemService _itemService = ItemService();

  // Future data loaders
  late Future<List<ItemManutencaoFrota>> _futureItensManutencao = Future.value([]);
  Map<String, String> _itemNames = {};

  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  // Keys para tutorial e elementos UI
  final GlobalKey _manutencaoFormKey = GlobalKey();
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _observacoesKey = GlobalKey();
  final GlobalKey _itensManutencaoKey = GlobalKey();
  final GlobalKey _addItemManutencaoKey = GlobalKey();
  final GlobalKey _firstItemMoreOptionsKey = GlobalKey();
  final GlobalKey _firstItemEditKey = GlobalKey();
  final GlobalKey _firstItemDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);

    _canEdit = appStateManager.canEdit('frotas');
    _canDelete = appStateManager.canDelete('frotas');
    _showTutorial = appStateManager.showTutorial('manutencaoFrotaFormScreen');
    appStateManager.setShowTutorial('manutencaoFrotaFormScreen', false);

    // Cria objeto em memória, mas não grava no DB
    _currentManutencao = widget.manutencaoFrota ??
        ManutencaoFrota(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId!,
          frotaId: widget.frota.id,
          data: DateTime.now(),
        );

    _initializeControllers();

    // Se já existia manutenção, carrega itens
    if (widget.manutencaoFrota != null) {
      _loadItensManutencao();
    }
  }


  void _initializeControllers() {
    _horimetroController = FormatacaoUtil.getMaskedTextController(_currentManutencao.horimetro ?? widget.frota.horimetroOdometro ?? 0.0);
    _observacoesController = TextEditingController(text: _currentManutencao.observacoes);
    _data = _currentManutencao.data;
    _dataController = TextEditingController(text: FormatacaoUtil.formatDate(_data));
  }

  void _loadItensManutencao() {
    setState(() {
      _futureItensManutencao = _itemManutencaoService.getByAttributes({'manutencaoFrotaId': _currentManutencao.id});

      _itemNames.clear();
      _futureItensManutencao.then((itens) async {
        if (itens.isNotEmpty) {
          final itemIds = itens.map((item) => item.itemId).toSet().toList();
          final items = await _itemService.getByIds(itemIds);
          if (mounted) {
            setState(() {
              _itemNames = {for (var item in items) item.id: item.nome};
            });
          }
        }
      });
    });
  }

  Future<void> _navigateToItemManutencaoFormScreen([ItemManutencaoFrota? item]) async {
    final result = await Navigator.push<ItemManutencaoFrota>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemManutencaoFrotaFormScreen(
          manutencaoFrota: _currentManutencao,
          itemManutencaoFrota: item,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _returnObject = true;
      });
      _loadItensManutencao();
    }
  }

  Future<void> _removeItemManutencao(ItemManutencaoFrota item) async {
    bool confirm = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).confirm_deletion),
              content: Text(S.of(context).confirm_deletion_message(S.of(context).maintenance_item)),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).remove),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            );
          },
        ) ??
        false;

    if (confirm) {
      try {
        await _itemManutencaoService.delete(item.id);
        _loadItensManutencao();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).maintenance_item_removed)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_removing_item(e.toString()))),
        );
      }
    }
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  Future<void> _saveManutencao() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        try {
          // Monta a manutenção
          _currentManutencao = _currentManutencao.copyWith(
            data: _data,
            horimetro: FormatacaoUtil.instance.parseNumber(_horimetroController.text),
            observacoes: _observacoesController.text,
          );

          // Se for nova
          if (widget.manutencaoFrota == null) {
            final newId = await _manutencaoService.add(_currentManutencao, returnId: true);
            _currentManutencao = _currentManutencao.copyWith(id: newId);
          } else {
            // Se já existia
            await _manutencaoService.update(_currentManutencao.id, _currentManutencao);
          }

          if (!mounted) return;
          // Retorna a manutenção já salva
          Navigator.of(context).pop(_currentManutencao);

        } catch (e) {
          // Exibe erro
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar manutenção: $e')),
          );
        }
      }
    } else {
      // Sem permissão => volta null
      Navigator.of(context).pop(null);
    }
  }



  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentManutencao : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.manutencaoFrota == null ? S.of(context).add_maintenance : S.of(context).edit_maintenance,
        formKey: _formKey,
        onSave: _saveManutencao,
        moduleName: 'frotas',
        isNewItem: widget.manutencaoFrota == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        isExpanded: _isExpanded,
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: _buildCustomTutorialSteps(),
        returnObject: _returnObject,
        onWillPop: () async => true,
        body: _buildFormBody(),
        cardSections: [
          _buildItensManutencaoCards(),
        ],
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _navigateToItemManutencaoFormScreen();
            },
            icon: Icons.add,
            text: S.of(context).add_maintenance_item,
            key: _addItemManutencaoKey,
            heroTag: 'addItemManutencao',
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'customManutencaoForm': {
        'key': _manutencaoFormKey,
        'message': S.of(context).edit_maintenance_info,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'identificacao': {
        'key': _identificacaoKey,
        'message': '${S.of(context).identification} ${S.of(context).maintenance_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'observacoes': {
        'key': _observacoesKey,
        'message': '${S.of(context).notes} ${S.of(context).maintenance_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      if (widget.manutencaoFrota != null) ..._buildCardSectionsTutorialSteps(),
    };
  }

  Map<String, Map<String, dynamic>> _buildCardSectionsTutorialSteps() {
    return {
      'itensManutencao': {
        'key': _itensManutencaoKey,
        'message': S.of(context).maintenance_items_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
      if (FormatacaoUtil.hasValidPosition(_firstItemMoreOptionsKey))
        'moreOptionsItem': {
          'key': _firstItemMoreOptionsKey,
          'message': S.of(context).click_to_see_more_options,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
          'hasMoreOptions': true,
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
              controller: _dataController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).date,
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _data,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (pickedDate != null) {
                  setState(() {
                    _data = pickedDate;
                    _dataController.text = FormatacaoUtil.formatDate(pickedDate);
                    _hasChanges = true;
                  });
                }
              },
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return S.of(context).select_date;
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _horimetroController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).hour_meter_odometer,
                suffixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _hasChanges = true,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.notes, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  S.of(context).notes,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).observations,
              ),
              maxLines: 4,
              onChanged: (value) => _hasChanges = true,
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  CardSection _buildItensManutencaoCards() {
    return ObjectTemplate.buildCardSectionWithFuture<ItemManutencaoFrota>(
      key: _itensManutencaoKey,
      title: S.of(context).maintenance_items,
      iconePrincipal: Icons.build,
      future: _futureItensManutencao,
      itemTitle: (item) => _itemNames[item.itemId] ?? S.of(context).not_found,
      itemSubtitle: (item) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item.quantidadeUtilizada)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[item.unidadeMedida] ?? item.unidadeMedida}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${S.of(context).cmp}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item.cmpAtual)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${S.of(context).total_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(item.quantidadeUtilizada * item.cmpAtual)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
      onEdit: (item) => _navigateToItemManutencaoFormScreen(item),
      onDelete: (item) => _removeItemManutencao(item),
      itemLeadingIcon: Icons.build,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_maintenance_items,
      firstItemMoreOptionsKey: _firstItemMoreOptionsKey,
    );
  }

  @override
  void dispose() {
    _horimetroController.dispose();
    _observacoesController.dispose();
    _dataController.dispose();
    super.dispose();
  }
}
