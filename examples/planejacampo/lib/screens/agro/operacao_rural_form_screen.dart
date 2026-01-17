import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/screens/agro/atividades_rurais_list_screen.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/item_operacao_rural_service.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/utils/atividade_rural_options.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/utils/operacao_rural_options.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhoes_list_screen.dart';
import 'package:planejacampo/screens/agro/tipos_operacoes_rurais_list_screen.dart';
import 'package:planejacampo/screens/agro/item_operacao_rural_form_screen.dart';
import 'package:planejacampo/models/frota_operacao_rural.dart';
import 'package:planejacampo/services/frota_operacao_rural_service.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/screens/agro/frota_operacao_rural_form_screen.dart';

class OperacaoRuralFormScreen extends StatefulWidget {
  final OperacaoRural? operacaoRural;
  final String atividadeId;

  const OperacaoRuralFormScreen({
    Key? key,
    this.operacaoRural,
    required this.atividadeId,
  }) : super(key: key);

  @override
  _OperacaoRuralFormScreenState createState() => _OperacaoRuralFormScreenState();
}

class _OperacaoRuralFormScreenState extends State<OperacaoRuralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late OperacaoRural _currentOperacaoRural;
  late TextEditingController _descricaoController;
  late TextEditingController _areaController;
  late DateTime _dataInicio;
  DateTime? _dataFim;
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  final TalhaoService _talhaoService = TalhaoService();
  final ItemOperacaoRuralService _itemOperacaoRuralService = ItemOperacaoRuralService();
  final ItemService _itemService = ItemService();
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  List<String> _talhoes = [];
  late Future<List<TipoOperacaoRural>> _futureTiposOperacao;
  late Future<List<Talhao>> _futureTalhoes;
  late Future<List<ItemOperacaoRural>> _futureItensOperacao;
  String? _selectedTipoOperacaoRuralId;
  String _selectedFase = OperacaoRuralOptions.fases[0];
  List<ItemOperacaoRural> _itensOperacao = [];
  late TextEditingController _tipoOperacaoController;
  TipoOperacaoRural? _selectedTipoOperacao;
  late TextEditingController _atividadeRuralController;
  late Future<List<Talhao>> _futureTalhoesDaAtividade;
  late Future<AtividadeRural?> _futureAtividadeRural;
  List<String> _talhoesParaRemover = [];
  Map<String, String> _itemNames = {};
  final FrotaOperacaoRuralService _frotaOperacaoRuralService = FrotaOperacaoRuralService();
  final FrotaService _frotaService = FrotaService();
  late Future<List<FrotaOperacaoRural>> _futureFrotasOperacao;
  Map<String, String> _frotaNames = {};
  List<FrotaOperacaoRural> _frotasOperacao = [];

  // Keys para o tutorial
  final GlobalKey _frotasOperacaoKey = GlobalKey();
  final GlobalKey _addFrotaOperacaoKey = GlobalKey();
  final GlobalKey _firstFrotaMoreOptionsKey = GlobalKey();
  final GlobalKey _operacaoRuralFormKey = GlobalKey();
  final GlobalKey _talhoesKey = GlobalKey();
  final GlobalKey _addTalhaoKey = GlobalKey();
  final GlobalKey _itensOperacaoKey = GlobalKey();
  final GlobalKey _addItemOperacaoKey = GlobalKey();
  final GlobalKey _firstItemMoreOptionsKey = GlobalKey();
  final GlobalKey _firstItemEditKey = GlobalKey();
  final GlobalKey _firstItemDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkActiveAtividadeRural();
    });
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('operacoesRurais');
    _canDelete = appStateManager.canDelete('operacoesRurais');
    _showTutorial = appStateManager.showTutorial('operacaoRuralFormScreen');
    appStateManager.setShowTutorial('operacaoRuralFormScreen', false);

    _currentOperacaoRural = widget.operacaoRural ??
        OperacaoRural(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          atividadeId: widget.atividadeId,
          produtorId: appStateManager.activeProdutorId!,
          propriedadeId: appStateManager.activePropriedadeId!,
          fase: OperacaoRuralOptions.fases[0],
          tipoOperacaoRuralId: '',
          dataInicio: DateTime.now(),
          talhoes: [],
          descricao: '',
        );

    _descricaoController = TextEditingController(text: _currentOperacaoRural.descricao);
    _areaController = FormatacaoUtil.getMaskedTextController(_currentOperacaoRural.area ?? 0.0);
    _dataInicio = _currentOperacaoRural.dataInicio;
    _dataFim = _currentOperacaoRural.dataFim;
    _selectedTipoOperacaoRuralId = _currentOperacaoRural.tipoOperacaoRuralId;
    _selectedFase = _currentOperacaoRural.fase;

    _talhoes = _currentOperacaoRural.talhoes ?? [];

    // CORREÇÃO CRÍTICA: Sempre carregar os dados, independente de ser nova ou existente
    _loadTiposOperacao();
    _loadTalhoes();
    _loadItensOperacao();
    _loadFrotasOperacao();

    _tipoOperacaoController = TextEditingController();
    if (_selectedTipoOperacaoRuralId != null && _selectedTipoOperacaoRuralId!.isNotEmpty) {
      _loadTipoOperacaoDetails();
    }
    _atividadeRuralController = TextEditingController(text: widget.atividadeId);
    _loadTalhoesDaAtividade();
    _loadAtividadeRural();
  }

  void _checkActiveAtividadeRural() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    if (appStateManager.activeAtividadeRural == null) {
      _showInstructionDialog();
    }
  }

  Future<void> _showInstructionDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).select_activity_to_continue),
          content: Text(S.of(context).select_activity_instruction),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
                _showAtividadesRuraisSelectionScreen();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAtividadesRuraisSelectionScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AtividadesRuraisListScreen(
          isSelectMode: true,
          isSetMode: true,
        ),
      ),
    );

    if (result == null || result == false) {
      _showErrorDialog();
    }
  }

  Future<void> _showErrorDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).select_activity_to_continue),
          content: Text(S.of(context).select_activity_instruction),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).ok),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _loadAtividadeRural() {
    _futureAtividadeRural = AtividadeRuralService().getById(widget.atividadeId);
  }

  void _loadTalhoesDaAtividade() {
    _futureTalhoesDaAtividade = _talhaoService.getByAttributes({
      'atividadeId': widget.atividadeId,
    });
  }

  void _loadTipoOperacaoDetails() async {
    if (_selectedTipoOperacaoRuralId != null && _selectedTipoOperacaoRuralId!.isNotEmpty) {
      final tipo = await _tipoOperacaoRuralService.getById(_selectedTipoOperacaoRuralId!);
      if (tipo != null) {
        setState(() {
          _selectedTipoOperacao = tipo;
          _tipoOperacaoController.text = tipo.nome;
        });
      }
    }
  }

  void _loadTiposOperacao() {
    if (widget.operacaoRural != null) {
      _futureTiposOperacao = _tipoOperacaoRuralService.getByAttributes({
        'produtorId': Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
        'siglaPais': Provider.of<AppStateManager>(context, listen: false).appLocale.countryCode ?? '',
      });
    } else {
      _futureTiposOperacao = Future.value([]);
    }
  }

  void _loadTalhoes() {
    if (widget.operacaoRural != null && _talhoes.isNotEmpty) {
      _futureTalhoes = _talhaoService.getByIds(_talhoes);
    } else {
      _futureTalhoes = Future.value([]);
    }
  }

  void _loadItensOperacao() {
    if (widget.operacaoRural != null) {
      setState(() {
        _futureItensOperacao = _itemOperacaoRuralService.getByAttributes({
          'operacaoRuralId': widget.operacaoRural!.id
        });
        _futureItensOperacao.then((itens) async {
          final itemIds = itens.map((item) => item.itemId).toSet().toList();
          if (itemIds.isNotEmpty) {
            final items = await _itemService.getByIds(itemIds);

            if (mounted) {
              setState(() {
                _itemNames = {for (var item in items) item.id: item.nome};
                _itensOperacao = itens;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _itemNames = {};
                _itensOperacao = itens;
              });
            }
          }
        });
      });
    } else {
      _futureItensOperacao = Future.value([]);
      _itensOperacao = [];
    }
  }

  void _loadFrotasOperacao() {
    if (widget.operacaoRural != null) {
      setState(() {
        _futureFrotasOperacao = _frotaOperacaoRuralService.getByAttributes({
          'operacaoRuralId': widget.operacaoRural!.id
        });
        _futureFrotasOperacao.then((frotas) async {
          final frotaIds = frotas.map((frota) => frota.frotaId).toSet().toList();
          if (frotaIds.isNotEmpty) {
            final frotasDetails = await _frotaService.getByIds(frotaIds);
            if (mounted) {
              setState(() {
                _frotaNames = {for (var frota in frotasDetails) frota.id: frota.nome};
                _frotasOperacao = frotas;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _frotaNames = {};
                _frotasOperacao = frotas;
              });
            }
          }
        });
      });
    } else {
      _futureFrotasOperacao = Future.value([]);
      _frotasOperacao = [];
    }
  }

  Future<void> _saveOperacaoRural() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          _currentOperacaoRural = _currentOperacaoRural.copyWith(
            fase: _selectedFase,
            tipoOperacaoRuralId: _selectedTipoOperacaoRuralId ?? '',
            descricao: _descricaoController.text,
            area: FormatacaoUtil.instance.parseNumber(_areaController.text),
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            talhoes: _talhoes,
          );

          String operacaoRuralId;
          if (widget.operacaoRural == null) {
            String? newId = await _operacaoRuralService.add(_currentOperacaoRural, returnId: true);
            if (newId == null) {
              throw Exception('Falha ao adicionar operação rural: ID não gerado');
            }
            operacaoRuralId = newId;
            _currentOperacaoRural = _currentOperacaoRural.copyWith(id: operacaoRuralId);
          } else {
            operacaoRuralId = _currentOperacaoRural.id;
            await _operacaoRuralService.update(operacaoRuralId, _currentOperacaoRural);
          }

          // Processar frotas da operação
          List<FrotaOperacaoRural> frotasExistentes = await _frotaOperacaoRuralService.getByAttributes({
            'operacaoRuralId': operacaoRuralId
          });

          // Identificar frotas a serem removidas
          List<FrotaOperacaoRural> frotasParaRemover = frotasExistentes
              .where((frota) => !_frotasOperacao.any((f) => f.id == frota.id))
              .toList();

          // Remover frotas e ajustar horímetros
          for (var frota in frotasParaRemover) {
            final frotaObj = await _frotaService.getById(frota.frotaId);
            if (frotaObj != null) {
              double novoHorimetro = (frotaObj.horimetroOdometro ?? 0.0) - frota.horasUtilizadas;
              await _frotaService.update(
                  frotaObj.id,
                  frotaObj.copyWith(horimetroOdometro: novoHorimetro)
              );
            }
            await _frotaOperacaoRuralService.delete(frota.id);
          }

          // Processar frotas
          List<FrotaOperacaoRural> frotasAtualizadas = [];
          for (var frota in _frotasOperacao) {
            FrotaOperacaoRural frotaAtualizada;
            if (frota.id.isEmpty) {
              final frotaObj = await _frotaService.getById(frota.frotaId);
              if (frotaObj == null) throw Exception('Frota não encontrada');

              double novoHorimetro = (frotaObj.horimetroOdometro ?? 0.0) + frota.horasUtilizadas;
              await _frotaService.update(
                  frotaObj.id,
                  frotaObj.copyWith(horimetroOdometro: novoHorimetro)
              );

              String? novaFrotaId = await _frotaOperacaoRuralService.add(
                  frota.copyWith(operacaoRuralId: operacaoRuralId),
                  returnId: true
              );
              if (novaFrotaId == null) {
                throw Exception('Falha ao adicionar nova frota de operação');
              }
              frotaAtualizada = frota.copyWith(id: novaFrotaId, operacaoRuralId: operacaoRuralId);
            } else {
              FrotaOperacaoRural? frotaOriginal = frotasExistentes.firstWhere(
                      (f) => f.id == frota.id,
                  orElse: () => throw Exception('Frota original não encontrada')
              );

              final frotaObj = await _frotaService.getById(frota.frotaId);
              if (frotaObj == null) throw Exception('Frota não encontrada');

              if (frotaOriginal.frotaId != frota.frotaId) {
                final frotaAnterior = await _frotaService.getById(frotaOriginal.frotaId);
                if (frotaAnterior != null) {
                  double horimetroAnterior = (frotaAnterior.horimetroOdometro ?? 0.0) - frotaOriginal.horasUtilizadas;
                  await _frotaService.update(
                      frotaAnterior.id,
                      frotaAnterior.copyWith(horimetroOdometro: horimetroAnterior)
                  );
                }

                double horimetroNovo = (frotaObj.horimetroOdometro ?? 0.0) + frota.horasUtilizadas;
                await _frotaService.update(
                    frotaObj.id,
                    frotaObj.copyWith(horimetroOdometro: horimetroNovo)
                );
              } else {
                double novoHorimetro = (frotaObj.horimetroOdometro ?? 0.0) -
                    frotaOriginal.horasUtilizadas +
                    frota.horasUtilizadas;
                await _frotaService.update(
                    frotaObj.id,
                    frotaObj.copyWith(horimetroOdometro: novoHorimetro)
                );
              }

              frotaAtualizada = frota.copyWith(operacaoRuralId: operacaoRuralId);
              await _frotaOperacaoRuralService.update(frota.id, frotaAtualizada);
            }
            frotasAtualizadas.add(frotaAtualizada);
          }

          setState(() {
            _frotasOperacao = frotasAtualizadas;
          });

          Navigator.of(context).pop(_currentOperacaoRural);
        } catch (e) {
          print('Erro ao salvar operação rural: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_operation(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          bool shouldExit = await _showUnsavedChangesDialog();
          return shouldExit;
        }
        return true;
      },
      child: FormTemplate(
        title: widget.operacaoRural == null
            ? S.of(context).add_rural_operation
            : S.of(context).edit_rural_operation,
        formKey: _formKey,
        onSave: _saveOperacaoRural,
        moduleName: 'operacoesRurais',
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();
              await _showTalhoesSelectionScreen();
            },
            icon: Icons.add,
            text: S.of(context).link_plot,
            key: _addTalhaoKey,
            heroTag: 'linkTalhao',
          ),
          if (widget.operacaoRural != null)
            ObjectTemplate.buildCustomFloatingActionButton(
              context: context,
              onPressed: () async {
                _toggleFloatingActionButton();
                await _showItemOperacaoRuralFormScreen();
              },
              icon: Icons.add,
              text: S.of(context).add_item,
              key: _addItemOperacaoKey,
              heroTag: 'addItemOperacao',
            ),
          if (widget.operacaoRural != null)
            ObjectTemplate.buildCustomFloatingActionButton(
              context: context,
              onPressed: () async {
                _toggleFloatingActionButton();
                await _navigateToFrotaOperacaoRuralFormScreen(null);
              },
              icon: Icons.add,
              text: S.of(context).add_fleet,
              key: _addFrotaOperacaoKey,
              heroTag: 'addFrotaOperacao',
            ),
        ],
        isNewItem: widget.operacaoRural == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        isExpanded: _isExpanded,
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: {
          'customOperacaoRuralForm': {
            'key': _operacaoRuralFormKey,
            'message': S.of(context).edit_rural_operation_info,
            'shape': 'RRect',
            'align': 'ContentAlign.bottom',
          },
          'customTalhoes': {
            'key': _talhoesKey,
            'message': S.of(context).manage_plots_info,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          'customItensOperacao': {
            'key': _itensOperacaoKey,
            'message': S.of(context).manage_operation_items_info,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
        },
        customActionTutorialSteps: {
          'linkTalhao': {
            'key': _addTalhaoKey,
            'message': S.of(context).link_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
          'addItemOperacao': {
            'key': _addItemOperacaoKey,
            'message': S.of(context).add_operation_item,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
        },
        returnObject: _returnObject,
        onWillPop: () async {
          return true;
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              key: _operacaoRuralFormKey,
              children: [
                _buildOperacaoRuralForm(),
              ],
            ),
          ),
        ),
        cardSections: [
          _buildTalhoesCards(),
          _buildItensOperacaoCards(),
          _buildFrotasOperacaoCards(),
        ],
      ),
    );
  }

  CardSection _buildFrotasOperacaoCards() {
    return ObjectTemplate.buildCardSectionWithFuture<FrotaOperacaoRural>(
      key: _frotasOperacaoKey,
      title: S.of(context).fleets,
      iconePrincipal: CustomIcons.trator_operacao_2,
      future: _futureFrotasOperacao,
      itemTitle: (frota) => _frotaNames[frota.frotaId] ?? S.of(context).not_found,
      itemSubtitle: (frota) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).hour_meter_odometer} Inicial: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horimetroInicial)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${S.of(context).hour_meter_odometer} Final: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horimetroFinal)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '${S.of(context).hours_used}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horasUtilizadas)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
      onEdit: (frota) => _navigateToFrotaOperacaoRuralFormScreen(frota),
      onDelete: (frota) => _removeFrotaOperacao(frota),
      itemLeadingIcon: Icons.agriculture,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).fleet_operation_not_found_plural,
      firstItemMoreOptionsKey: _firstFrotaMoreOptionsKey,
    );
  }

  Future<void> _navigateToFrotaOperacaoRuralFormScreen(FrotaOperacaoRural? frota) async {
    final result = await Navigator.push<FrotaOperacaoRural?>(
      context,
      MaterialPageRoute(
        builder: (context) => FrotaOperacaoRuralFormScreen(
          operacaoRural: _currentOperacaoRural,
          frotaOperacaoRural: frota,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (frota == null) {
          _frotasOperacao.add(result);
        } else {
          int index = _frotasOperacao.indexWhere((f) => f.id == frota.id);
          if (index != -1) {
            _frotasOperacao[index] = result;
          }
        }
        _hasChanges = true;
      });

      final frotaIds = _frotasOperacao.map((f) => f.frotaId).toSet().toList();
      if (frotaIds.isNotEmpty) {
        final frotas = await _frotaService.getByIds(frotaIds);
        setState(() {
          _frotaNames = {for (var f in frotas) f.id: f.nome};
        });
      }
    }
  }

  void _removeFrotaOperacao(FrotaOperacaoRural frota) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).fleet)),
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
    ) ?? false;

    if (confirm) {
      setState(() {
        _frotasOperacao.removeWhere((f) => f.id == frota.id);
        _hasChanges = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).fleet_operation_removed_plural)),
      );
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_exit_whitout_save),
          content: Text(S.of(context).confirm_exit_message_without_save),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).no),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text(S.of(context).yes),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildOperacaoRuralForm() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: FutureBuilder<AtividadeRural?>(
            future: _futureAtividadeRural,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text(S.of(context).error_loading);
              } else if (snapshot.hasData) {
                final atividade = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      atividade.nome,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${AtividadeRuralOptions.getLocalizedTiposAtividades(context)[atividade.tipo] ?? atividade.tipo} - ' +
                          '${AtividadeRuralOptions.getLocalizedSubtiposAtividades(context)[atividade.tipo]?.firstWhere(
                                  (subtipo) => subtipo == atividade.subtipo,
                              orElse: () => atividade.subtipo
                          ) ?? atividade.subtipo}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              } else {
                return Text(S.of(context).not_found);
              }
            },
          ),
        ),
        SizedBox(height: 24),

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

        ObjectTemplate.getDropdownButtonFormField(
          context: context,
          labelText: S.of(context).fase,
          value: _selectedFase,
          dropdownItems: OperacaoRuralOptions.fases.map((String fase) {
            return DropdownMenuItem<String>(
              value: fase,
              child: Text(OperacaoRuralOptions.getLocalizedFasesOperacoes(context)[fase] ?? fase),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFase = newValue ?? OperacaoRuralOptions.fases[0];
              _hasChanges = true;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).select_operation_phase;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _tipoOperacaoController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).operation_type,
            suffixIcon: Icon(Icons.search),
          ),
          readOnly: true,
          onTap: _selectTipoOperacao,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).select_operation_type;
            }
            return null;
          },
        ),
        SizedBox(height: 24),

        Row(
          children: [
            Icon(Icons.details, color: theme.colorScheme.primary),
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

        TextFormField(
          controller: _areaController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).area_ha,
            suffixIcon: Icon(Icons.area_chart),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) => _hasChanges = true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).enter_area;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        TextFormField(
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).start_date,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: FormatacaoUtil.formatDate(_dataInicio),
          ),
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _dataInicio,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _dataInicio = pickedDate;
                _hasChanges = true;
              });
            }
          },
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return S.of(context).select_start_date;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        TextFormField(
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).end_date,
            suffixIcon: Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _dataFim != null ? FormatacaoUtil.formatDate(_dataFim!) : '',
          ),
          readOnly: true,
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _dataFim ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              setState(() {
                _dataFim = pickedDate;
                _hasChanges = true;
              });
            }
          },
        ),
        SizedBox(height: 16),

        TextFormField(
          controller: _descricaoController,
          decoration: ObjectTemplate.getInputDecoration(
            context,
            S.of(context).description,
            suffixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          onChanged: (value) => _hasChanges = true,
        ),
        SizedBox(height: 24),
      ],
    );
  }

  Future<void> _selectTipoOperacao() async {
    final selectedTipo = await Navigator.push<TipoOperacaoRural>(
      context,
      MaterialPageRoute(
        builder: (context) => TiposOperacoesRuraisListScreen(isSelectMode: true),
      ),
    );

    if (selectedTipo != null) {
      setState(() {
        _selectedTipoOperacao = selectedTipo;
        _selectedTipoOperacaoRuralId = selectedTipo.id;
        _tipoOperacaoController.text = selectedTipo.nome;
        _hasChanges = true;
      });
    }
  }

  CardSection _buildTalhoesCards() {
    return CardSection(
      key: _talhoesKey,
      title: S.of(context).plots,
      cards: [
        FutureBuilder<List<Talhao>>(
          future: _futureTalhoes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text(S.of(context).no_plots_linked);
            } else {
              return Column(
                children: snapshot.data!.map((talhao) {
                  bool markedForRemoval = _talhoesParaRemover.contains(talhao.id);
                  return Card(
                    child: ListTile(
                      title: Text(talhao.nome, style: markedForRemoval ? TextStyle(color: Colors.grey) : null),
                      subtitle: Text('${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}'),
                      trailing: IconButton(
                        icon: Icon(markedForRemoval ? Icons.undo : Icons.delete),
                        onPressed: _canEdit
                            ? () {
                          markedForRemoval ? _desfazerRemocaoTalhao(talhao.id) : _removeTalhao(talhao.id);
                        }
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
    );
  }

  CardSection _buildItensOperacaoCards() {
    return ObjectTemplate.buildCardSectionWithFuture<ItemOperacaoRural>(
      key: _itensOperacaoKey,
      title: S.of(context).operation_items,
      iconePrincipal: Icons.list,
      future: _futureItensOperacao,
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
      onEdit: (item) => _showItemOperacaoRuralFormScreen(item),
      onDelete: (item) => _removeItemOperacao(item.id),
      itemLeadingIcon: Icons.shopping_cart,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_items_linked,
      firstItemMoreOptionsKey: _firstItemMoreOptionsKey,
    );
  }

  void _removeTalhao(String talhaoId) async {
    setState(() {
      if (!_talhoesParaRemover.contains(talhaoId)) {
        _talhoesParaRemover.add(talhaoId);
      }
      _hasChanges = true;
    });

    await _atualizarAreaTotal();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).plot_marked_for_removal),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _desfazerRemocaoTalhao(String talhaoId) async {
    setState(() {
      _talhoesParaRemover.remove(talhaoId);
      _hasChanges = true;
    });

    await _atualizarAreaTotal();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).plot_removal_undone),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _atualizarAreaTotal() async {
    if (_talhoes.isNotEmpty) {
      List<Talhao> talhoes = await _talhaoService.getByIds(_talhoes);
      double novaAreaTotal = talhoes
          .where((talhao) => !_talhoesParaRemover.contains(talhao.id))
          .fold(0, (sum, talhao) => sum + talhao.area);

      setState(() {
        _currentOperacaoRural = _currentOperacaoRural.copyWith(area: novaAreaTotal);
        _areaController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(novaAreaTotal);
      });
    }
  }

  void _removeItemOperacao(String itemId) {
    setState(() {
      _itensOperacao.removeWhere((item) => item.id == itemId);
      _hasChanges = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).item_removed_from_operation),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _showTalhoesSelectionScreen() async {
    List<Talhao> currentSelectedTalhoes = [];
    if (_talhoes.isNotEmpty) {
      currentSelectedTalhoes = await _talhaoService.getByIds(_talhoes);
    }

    final selectedTalhoes = await Navigator.push<List<Talhao>>(
      context,
      MaterialPageRoute(
        builder: (context) => TalhoesListScreen(
          isSelectMode: true,
          isSetMode: false,
          initialSelectedTalhoes: currentSelectedTalhoes,
          atividadeId: widget.atividadeId,
        ),
      ),
    );

    if (selectedTalhoes != null) {
      bool talhoesChanged = _talhoes.length != selectedTalhoes.length ||
          !_talhoes.every((talhaoId) => selectedTalhoes.any((talhao) => talhao.id == talhaoId));

      if (talhoesChanged) {
        setState(() {
          _talhoes = selectedTalhoes.map((t) => t.id).toList();
          _currentOperacaoRural = _currentOperacaoRural.copyWith(talhoes: _talhoes);

          double novaAreaTotal = selectedTalhoes.fold(0, (sum, talhao) => sum + talhao.area);
          _areaController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(novaAreaTotal);

          _currentOperacaoRural = _currentOperacaoRural.copyWith(area: novaAreaTotal);

          _hasChanges = true;
        });
        _loadTalhoes();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).plots_linked_successfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _showItemOperacaoRuralFormScreen([ItemOperacaoRural? item]) async {
    final result = await Navigator.push<ItemOperacaoRural>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemOperacaoRuralFormScreen(
          operacaoRural: _currentOperacaoRural,
          itemOperacaoRural: item,
        ),
      ),
    );

    if (result != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.of(context).processing),
                ],
              ),
            ),
          );
        },
      );

      try {
        if (item == null) {
          await _itemOperacaoRuralService.add(result);
          setState(() {
            _itensOperacao.add(result);
            _hasChanges = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).item_added_to_operation)),
            );
          }
        } else {
          await _itemOperacaoRuralService.update(result.id, result);
          setState(() {
            int index = _itensOperacao.indexWhere((i) => i.id == result.id);
            if (index != -1) {
              _itensOperacao[index] = result;
            }
            _hasChanges = true;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).item_updated_successfully)),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_operation(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        Navigator.of(context).pop();

        if (mounted) {
          _loadItensOperacao();
        }
      }
    }
  }

  @override
  void dispose() {
    _tipoOperacaoController.dispose();
    _descricaoController.dispose();
    _areaController.dispose();
    super.dispose();
  }
}