import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/manutencao_frota.dart';
import 'package:planejacampo/models/abastecimento_frota.dart';
import 'package:planejacampo/models/item_manutencao_frota.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/services/manutencao_frota_service.dart';
import 'package:planejacampo/services/abastecimento_frota_service.dart';
import 'package:planejacampo/services/item_manutencao_frota_service.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/frota_options.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/screens/agro/manutencao_frota_form_screen.dart';
import 'package:planejacampo/screens/agro/abastecimento_frota_form_screen.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';

class FrotaFormScreen extends StatefulWidget {
  final Frota? frota;

  const FrotaFormScreen({Key? key, this.frota}) : super(key: key);

  @override
  _FrotaFormScreenState createState() => _FrotaFormScreenState();
}

class _FrotaFormScreenState extends State<FrotaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Frota _currentFrota;
  late TextEditingController _nomeController;
  late TextEditingController _modeloController;
  late TextEditingController _anoFabricacaoController;
  late MoneyMaskedTextController _valorController;
  late MoneyMaskedTextController _horimetroOdometroController;
  late TextEditingController _vidaUtilController;
  late TextEditingController _observacoesController;
  late TextEditingController _identificadorController;
  late DateTime? _dataAquisicao;
// No início da classe _FrotaFormScreenState
  late List<AbastecimentoFrota> _abastecimentosAtuais = [];
  late List<AbastecimentoFrota> _abastecimentosParaRemover = [];
  late List<ManutencaoFrota> _manutencoesAtuais = [];
  late List<ManutencaoFrota> _manutencoesParaRemover = [];

  // Services
  final FrotaService _frotaService = FrotaService();
  final ManutencaoFrotaService _manutencaoService = ManutencaoFrotaService();
  final AbastecimentoFrotaService _abastecimentoService = AbastecimentoFrotaService();
  final ItemManutencaoFrotaService _itemManutencaoService = ItemManutencaoFrotaService();
  final ItemService _itemService = ItemService();

  // Future data loaders
  late Future<List<ManutencaoFrota>> _futureManutencoes;
  late Future<List<AbastecimentoFrota>> _futureAbastecimentos;
  Map<String, String> _itemNames = {};

  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  String _selectedTipo = '';

  // Keys para tutorial e elementos UI
  final GlobalKey _frotaFormKey = GlobalKey();
  final GlobalKey _identificacaoKey = GlobalKey();
  final GlobalKey _caracteristicasKey = GlobalKey();
  final GlobalKey _dadosOperacionaisKey = GlobalKey();
  final GlobalKey _observacoesKey = GlobalKey();

  // Keys para Manutenções
  final GlobalKey _manutencoesKey = GlobalKey();
  final GlobalKey _addManutencaoKey = GlobalKey();
  final GlobalKey _firstManutencaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstManutencaoEditKey = GlobalKey();
  final GlobalKey _firstManutencaoDeleteKey = GlobalKey();

  // Keys para Abastecimentos
  final GlobalKey _abastecimentosKey = GlobalKey();
  final GlobalKey _addAbastecimentoKey = GlobalKey();
  final GlobalKey _firstAbastecimentoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstAbastecimentoEditKey = GlobalKey();
  final GlobalKey _firstAbastecimentoDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('frotas');
    _canDelete = appStateManager.canDelete('frotas');
    _showTutorial = appStateManager.showTutorial('frotaFormScreen');
    appStateManager.setShowTutorial('frotaFormScreen', false);

    _currentFrota = widget.frota ??
        Frota(
          id: DateTime.now().toString(),
          nome: '',
          tipo: FrotaOptions.tiposFrota[0],
          produtorId: appStateManager.activeProdutorId!,
          propriedadeId: appStateManager.activePropriedadeId,
        );

    _initializeControllers();

    if (widget.frota != null) {
      _loadManutencoes();
      _loadAbastecimentos();
    }
  }

  void _initializeControllers() {
    _nomeController = TextEditingController(text: _currentFrota.nome);
    _modeloController = TextEditingController(text: _currentFrota.modelo ?? '');
    _anoFabricacaoController = FormatacaoUtil.getIntegerMaskedTextController(_currentFrota.anoFabricacao?.toInt() ?? 0);
    _valorController = FormatacaoUtil.getMaskedTextController(_currentFrota.valor ?? 0.0);
    _horimetroOdometroController = FormatacaoUtil.getMaskedTextController(_currentFrota.horimetroOdometro ?? 0.0);
    _vidaUtilController = FormatacaoUtil.getIntegerMaskedTextController(_currentFrota.vidaUtil?.toInt() ?? 0);
    _observacoesController = TextEditingController(text: _currentFrota.observacoes ?? '');
    _identificadorController = TextEditingController(text: _currentFrota.identificador ?? '');
    _dataAquisicao = _currentFrota.dataAquisicao;
    _selectedTipo = _currentFrota.tipo;
  }

  void _loadManutencoes() {
    setState(() {
      _futureManutencoes = _manutencaoService.getByAttributes({
        'frotaId': _currentFrota.id
      });
      _futureManutencoes.then((manutencoes) {
        setState(() {
          _manutencoesAtuais = manutencoes;
        });
      });
    });
  }

  void _loadAbastecimentos() {
    setState(() {
      _futureAbastecimentos = _abastecimentoService.getByAttributes({
        'frotaId': _currentFrota.id
      });
      _futureAbastecimentos.then((abastecimentos) async {
        final itemIds = abastecimentos.map((abast) => abast.itemId).toSet().toList();
        final items = await _itemService.getByIds(itemIds);

        if (mounted) {
          setState(() {
            _itemNames = { for (var item in items) item.id: item.nome };
            _abastecimentosAtuais = abastecimentos;
          });
        }
      });
    });
  }

  Future<void> _navigateToAbastecimentoFormScreen([AbastecimentoFrota? abastecimento]) async {
    final result = await Navigator.push<AbastecimentoFrota>(
      context,
      MaterialPageRoute(
        builder: (context) => AbastecimentoFrotaFormScreen(
          frota: _currentFrota,
          abastecimentoFrota: abastecimento,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (abastecimento == null) {
          // Novo abastecimento
          _abastecimentosAtuais.add(result);
        } else {
          // Atualização
          int index = _abastecimentosAtuais.indexWhere((a) => a.id == abastecimento.id);
          if (index != -1) {
            _abastecimentosAtuais[index] = result;
          }
        }
        _hasChanges = true;
      });
    }
  }

  Future<void> _navigateToManutencaoFormScreen([ManutencaoFrota? manutencao]) async {
    final result = await Navigator.push<ManutencaoFrota>(
      context,
      MaterialPageRoute(
        builder: (context) => ManutencaoFrotaFormScreen(
          frota: _currentFrota,
          manutencaoFrota: manutencao,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (manutencao == null) {
          _manutencoesAtuais.add(result);
        } else {
          int index = _manutencoesAtuais.indexWhere((m) => m.id == manutencao.id);
          if (index != -1) {
            _manutencoesAtuais[index] = result;
          }
        }
        _hasChanges = true;
      });
    }
  }

  void _removeManutencao(ManutencaoFrota manutencao) {
    setState(() {
      if (manutencao.id.isNotEmpty) {
        _manutencoesParaRemover.add(manutencao);
      }
      _manutencoesAtuais.removeWhere((m) => m.id == manutencao.id);
      _hasChanges = true;
    });
  }

  void _removeAbastecimento(AbastecimentoFrota abastecimento) {
    setState(() {
      if (abastecimento.id.isNotEmpty) {
        _abastecimentosParaRemover.add(abastecimento);
      }
      _abastecimentosAtuais.removeWhere((a) => a.id == abastecimento.id);
      _hasChanges = true;
    });
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  Future<void> _saveFrota() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          _currentFrota = _currentFrota.copyWith(
            nome: _nomeController.text,
            tipo: _selectedTipo,
            modelo: _modeloController.text,
            anoFabricacao: _anoFabricacaoController.text.isNotEmpty ?
            int.tryParse(_anoFabricacaoController.text.replaceAll(RegExp(r'[^0-9]'), '')) : null,
            valor: FormatacaoUtil.instance.parseNumber(_valorController.text),
            horimetroOdometro: FormatacaoUtil.instance.parseNumber(_horimetroOdometroController.text),
            vidaUtil: _vidaUtilController.text.isNotEmpty ?
            int.tryParse(_vidaUtilController.text.replaceAll(RegExp(r'[^0-9]'), '')) : null,
            dataAquisicao: _dataAquisicao,
            observacoes: _observacoesController.text,
            identificador: _identificadorController.text,
          );

          if (widget.frota == null) {
            final newFrotaId = await _frotaService.add(_currentFrota, returnId: true);
            _currentFrota = _currentFrota.copyWith(id: newFrotaId);
          } else {
            await _frotaService.update(_currentFrota.id, _currentFrota);
          }

          _returnObject = widget.frota == null ? true : _currentFrota;
          if (!mounted) return;
          Navigator.of(context).pop(_returnObject);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_fleet(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).fleet)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.of(context).pop(_hasChanges ? _currentFrota : _returnObject);
          return false;
        },
        child: FormTemplate(
        title: widget.frota == null ? S.of(context).add_fleet : S.of(context).edit_fleet,
    formKey: _formKey,
    onSave: _saveFrota,
    moduleName: 'frotas',
    isNewItem: widget.frota == null,
    canEdit: _canEdit,
    canDelete: _canDelete,
    showTutorial: _showTutorial,
    isExpanded: _isExpanded,
    onFloatingActionButtonPressed: _toggleFloatingActionButton,
    customTutorialSteps: _buildCustomTutorialSteps(),
    returnObject: _returnObject,
    onWillPop: () async => true,
    body: _buildFormBody(),
          cardSections: widget.frota != null ? [
            _buildManutencoesCards(),
            _buildAbastecimentosCards(),
          ] : [],
          additionalFloatingActionButtons: widget.frota != null ? (BuildContext context) => [
            ObjectTemplate.buildCustomFloatingActionButton(
              context: context,
              onPressed: () {
                _toggleFloatingActionButton();
                _navigateToManutencaoFormScreen();
              },
              icon: Icons.add,
              text: S.of(context).add_maintenance,
              key: _addManutencaoKey,
              heroTag: 'addManutencao',
            ),
            ObjectTemplate.buildCustomFloatingActionButton(
              context: context,
              onPressed: () {
                _toggleFloatingActionButton();
                _navigateToAbastecimentoFormScreen();
              },
              icon: Icons.add,
              text: S.of(context).add_refueling,
              key: _addAbastecimentoKey,
              heroTag: 'addAbastecimento',
            ),
          ] : null,
        ),
    );
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
                Icon(Icons.badge, color: theme.colorScheme.primary),
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
              controller: _nomeController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).name,
                suffixIcon: Icon(Icons.edit),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return S.of(context).enter_name;
                }
                return null;
              },
              onChanged: (value) => _hasChanges = true,
            ),
            SizedBox(height: 16),
            ObjectTemplate.getDropdownButtonFormField(
              context: context,
              labelText: S.of(context).fleet_type,
              value: _selectedTipo,
              items: FrotaOptions.tiposFrota,
              onChanged: (String? value) {
                setState(() {
                  _selectedTipo = value ?? '';
                  _hasChanges = true;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).select_fleet_type;
                }
                return null;
              },
              dropdownItems: FrotaOptions.tiposFrota
                  .map((tipo) => DropdownMenuItem(
                value: tipo,
                child: Text(FrotaOptions.getLocalizedTiposFrota(context)[tipo] ?? tipo),
              ))
                  .toList(),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _modeloController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).model,
                suffixIcon: Icon(Icons.directions_car),
              ),
              onChanged: (value) => _hasChanges = true,
            ),

            SizedBox(height: 24),
            // Seção de Características
            Row(
              children: [
                Icon(Icons.settings, color: theme.colorScheme.primary),
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
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _anoFabricacaoController,
                    decoration: ObjectTemplate.getInputDecoration(
                      context,
                      S.of(context).year_of_manufacture,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _hasChanges = true,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _vidaUtilController,
                    decoration: ObjectTemplate.getInputDecoration(
                      context,
                      S.of(context).useful_life,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _hasChanges = true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).value,
                suffixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _hasChanges = true,
            ),

            SizedBox(height: 24),
            // Seção de Dados Operacionais
            Row(
              children: [
                Icon(Icons.speed, color: theme.colorScheme.primary),
                SizedBox(width: 8),
                Text(
                  S.of(context).operational_data,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _horimetroOdometroController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).hour_meter_odometer,
                suffixIcon: Icon(Icons.speed),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => _hasChanges = true,
            ),
            SizedBox(height: 16),
            _buildDatePickerField(
              context: context,
              label: S.of(context).acquisition_date,
              selectedDate: _dataAquisicao,
              onDateSelected: (date) {
                setState(() {
                  _dataAquisicao = date;
                  _hasChanges = true;
                });
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _identificadorController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).identifier,
                suffixIcon: Icon(Icons.qr_code),
              ),
              onChanged: (value) => _hasChanges = true,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: ObjectTemplate.getInputDecoration(
                context,
                S.of(context).notes,
              ),
              maxLines: 4,
              onChanged: (value) => _hasChanges = true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? selectedDate,
    required Function(DateTime) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (pickedDate != null) {
          onDateSelected(pickedDate);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          decoration: ObjectTemplate.getInputDecoration(
            context,
            label,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: selectedDate != null ? FormatacaoUtil.formatDate(selectedDate) : '',
          ),
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'customFrotaForm': {
        'key': _frotaFormKey,
        'message': S.of(context).edit_fleet_info,
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'identificacao': {
        'key': _identificacaoKey,
        'message': '${S.of(context).identification} ${S.of(context).fleet_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'caracteristicas': {
        'key': _caracteristicasKey,
        'message': '${S.of(context).characteristics} ${S.of(context).fleet_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'dadosOperacionais': {
        'key': _dadosOperacionaisKey,
        'message': '${S.of(context).operational_data} ${S.of(context).fleet_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      'observacoes': {
        'key': _observacoesKey,
        'message': '${S.of(context).notes} ${S.of(context).fleet_details_info}',
        'shape': 'RRect',
        'align': 'ContentAlign.bottom',
      },
      if (widget.frota != null) ..._buildCardSectionsTutorialSteps(),
    };
  }

  Map<String, Map<String, dynamic>> _buildCardSectionsTutorialSteps() {
    return {
      'manutencoes': {
        'key': _manutencoesKey,
        'message': S.of(context).maintenance_records_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
      'abastecimentos': {
        'key': _abastecimentosKey,
        'message': S.of(context).refueling_records_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
      if (FormatacaoUtil.hasValidPosition(_firstManutencaoMoreOptionsKey))
        'moreOptionsManutencao': {
          'key': _firstManutencaoMoreOptionsKey,
          'message': S.of(context).click_to_see_more_options,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
          'hasMoreOptions': true,
        },
      if (FormatacaoUtil.hasValidPosition(_firstAbastecimentoMoreOptionsKey))
        'moreOptionsAbastecimento': {
          'key': _firstAbastecimentoMoreOptionsKey,
          'message': S.of(context).click_to_see_more_options,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
          'hasMoreOptions': true,
        },
    };
  }

  CardSection _buildManutencoesCards() {
    return ObjectTemplate.buildCardSectionWithFuture<ManutencaoFrota>(
      key: _manutencoesKey,
      title: S.of(context).maintenance_records,
      iconePrincipal: Icons.build,
      future: _futureManutencoes,
      itemTitle: (manutencao) => FormatacaoUtil.formatDate(manutencao.data),
      itemSubtitle: (manutencao) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (manutencao.horimetro != null)
              Text(
                '${S.of(context).hour_meter_odometer}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(manutencao.horimetro!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (manutencao.observacoes != null)
              Text(
                manutencao.observacoes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
      onEdit: (manutencao) => _navigateToManutencaoFormScreen(manutencao),
      onDelete: (manutencao) => _removeManutencao(manutencao),
      itemLeadingIcon: Icons.build,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_maintenance_records,
      firstItemMoreOptionsKey: _firstManutencaoMoreOptionsKey,
    );
  }

  CardSection _buildAbastecimentosCards() {
    return ObjectTemplate.buildCardSectionWithFuture<AbastecimentoFrota>(
      key: _abastecimentosKey,
      title: S.of(context).refueling_records,
      iconePrincipal: Icons.local_gas_station,
      future: _futureAbastecimentos,
      itemTitle: (abastecimento) => FormatacaoUtil.formatDate(abastecimento.data),
      itemSubtitle: (abastecimento) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(abastecimento.quantidadeUtilizada)} ${ItemOptions.getLocalizedUnidadesMedidaAbreviada(context)[abastecimento.unidadeMedida] ?? abastecimento.unidadeMedida}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (abastecimento.externo)
              Text(
                S.of(context).external_refueling,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );
      },
      onEdit: (abastecimento) => _navigateToAbastecimentoFormScreen(abastecimento),
      onDelete: (abastecimento) => _removeAbastecimento(abastecimento),
      itemLeadingIcon: Icons.local_gas_station,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_refueling_records,
      firstItemMoreOptionsKey: _firstAbastecimentoMoreOptionsKey,
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _modeloController.dispose();
    _anoFabricacaoController.dispose();
    _valorController.dispose();
    _horimetroOdometroController.dispose();
    _vidaUtilController.dispose();
    _observacoesController.dispose();
    _identificadorController.dispose();
    super.dispose();
  }
}