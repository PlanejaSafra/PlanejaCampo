import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/screens/agro/operacao_rural_form_screen.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/operacao_rural_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';
import 'package:planejacampo/utils/atividade_rural_options.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhoes_list_screen.dart';

class AtividadeRuralFormScreen extends StatefulWidget {
  final AtividadeRural? atividadeRural;

  const AtividadeRuralFormScreen({Key? key, this.atividadeRural}) : super(key: key);

  @override
  _AtividadeRuralFormScreenState createState() => _AtividadeRuralFormScreenState();
}

class _AtividadeRuralFormScreenState extends State<AtividadeRuralFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late AtividadeRural _currentAtividadeRural;
  late TextEditingController _nomeController;
  late DateTime _dataInicio;
  DateTime? _dataFim;
  final AtividadeRuralService _atividadeRuralService = AtividadeRuralService();
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  final TalhaoService _talhaoService = TalhaoService();
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  String _selectedTipo = '';
  String _selectedSubtipo = '';
  List<String> _subtipos = [];
  List<String> _talhoesParaRemover = [];

  List<String> _talhoes = [];
  late Future<List<Talhao>> _futureTalhoes;
  late TalhaoDialogScreen _talhaoDialogScreen;
  late Future<List<OperacaoRural>> _futureOperacoes;

  // Definição das GlobalKeys para o tutorial
  final GlobalKey _atividadeRuralFormKey = GlobalKey();
  final GlobalKey _talhoesKey = GlobalKey();
  final GlobalKey _addTalhaoKey = GlobalKey();
  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstTalhaoEditKey = GlobalKey();
  final GlobalKey _firstTalhaoDeleteKey = GlobalKey();
  final GlobalKey _operacoesKey = GlobalKey();
  final GlobalKey _addOperacaoKey = GlobalKey();
  final GlobalKey _firstOperacaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstOperacaoEditKey = GlobalKey();
  final GlobalKey _firstOperacaoDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit('atividadesRurais');
    _canDelete = appStateManager.canDelete('atividadesRurais');
    _showTutorial = appStateManager.showTutorial('atividadeRuralFormScreen');
    appStateManager.setShowTutorial('atividadeRuralFormScreen', false);

    _currentAtividadeRural = widget.atividadeRural ??
        AtividadeRural(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId!,
          propriedadeId: appStateManager.activePropriedadeId!,
          tipo: AtividadeRuralOptions.tiposAtividade[0],
          subtipo: '',
          nome: '',
          dataInicio: DateTime.now(),
          talhoes: [],
        );

    _nomeController = TextEditingController(text: _currentAtividadeRural.nome);
    _dataInicio = _currentAtividadeRural.dataInicio;
    _dataFim = _currentAtividadeRural.dataFim;
    _selectedTipo = _currentAtividadeRural.tipo;
    _selectedSubtipo = _currentAtividadeRural.subtipo;
    _updateSubtipos();

    _talhoes = widget.atividadeRural?.talhoes?.cast<String>() ?? <String>[];
    _loadTalhoes();

    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: _currentAtividadeRural.propriedadeId,
      talhaoService: _talhaoService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: () {
        _returnObject = true;
        _loadTalhoes();
        setState(() {});
      },
      firstTalhaoMoreOptionsKey: _firstTalhaoMoreOptionsKey,
      firstTalhaoEditKey: _firstTalhaoEditKey,
      firstTalhaoDeleteKey: _firstTalhaoDeleteKey,
    );
    _loadOperacoes();
  }

  void _loadOperacoes() {
    setState(() {
      if (widget.atividadeRural != null) {
        _futureOperacoes = _operacaoRuralService.getByAttributes({'atividadeId': widget.atividadeRural!.id});
      } else {
        _futureOperacoes = Future.value([]);
      }
    });
  }

  void _navigateToOperacaoRuralFormScreen([OperacaoRural? operacao]) {
    Navigator.of(context)
        .push<dynamic>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => OperacaoRuralFormScreen(
          operacaoRural: operacao,
          atividadeId: _currentAtividadeRural.id,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((result) {
      if (result != null) {
        setState(() {
          _returnObject = true;
          _loadOperacoes();
        });
      }
    });
  }

  void _updateSubtipos() {
    setState(() {
      _subtipos = AtividadeRuralOptions.getSubtipos(_selectedTipo);
      if (!_subtipos.contains(_selectedSubtipo)) {
        _selectedSubtipo = _subtipos.isNotEmpty ? _subtipos[0] : '';
      }
    });
  }

  void _loadTalhoes() {
    _futureTalhoes = _talhaoService.getByIds(_talhoes);
  }

  Future<void> _saveAtividadeRural() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          // Remover os talhões marcados para remoção
          _talhoes.removeWhere((talhaoId) => _talhoesParaRemover.contains(talhaoId));

          _currentAtividadeRural = _currentAtividadeRural.copyWith(
            tipo: _selectedTipo,
            subtipo: _selectedSubtipo,
            nome: _nomeController.text,
            dataInicio: _dataInicio,
            dataFim: _dataFim,
            talhoes: _talhoes,
          );

          if (widget.atividadeRural == null) {
            final newAtividadeId = await _atividadeRuralService.add(_currentAtividadeRural, returnId: true);
            _currentAtividadeRural = _currentAtividadeRural.copyWith(id: newAtividadeId);
          } else {
            await _atividadeRuralService.update(_currentAtividadeRural.id, _currentAtividadeRural);
          }

          _talhoesParaRemover.clear(); // Limpa a lista após salvar

          _returnObject = widget.atividadeRural == null ? true : _currentAtividadeRural;
          if (!mounted) return;
          Navigator.of(context).pop(_returnObject);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_activity(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).rural_activity)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
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
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? _currentAtividadeRural : _returnObject);
        return false;
      },
      child: FormTemplate(
        title: widget.atividadeRural == null ? S.of(context).add_rural_activity : S.of(context).edit_rural_activity,
        formKey: _formKey,
        onSave: _saveAtividadeRural,
        moduleName: 'atividadesRurais',
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();

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
                  ),
                ),
              );

              if (selectedTalhoes != null) {
                setState(() {
                  _talhoes = selectedTalhoes.map((t) => t.id).toList();
                  _currentAtividadeRural = _currentAtividadeRural.copyWith(talhoes: _talhoes);
                  _hasChanges = true;
                  _returnObject = true;
                });
                _loadTalhoes();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).plots_linked_successfully),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            icon: Icons.add,
            text: S.of(context).link_plot,
            key: _addTalhaoKey,
            heroTag: 'linkTalhao',
          ),
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _navigateToOperacaoRuralFormScreen();
            },
            icon: Icons.add,
            text: S.of(context).add_operation,
            key: _addOperacaoKey,
            heroTag: 'addOperacao',
          ),
        ],
        isNewItem: widget.atividadeRural == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        isExpanded: _isExpanded,
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: {
          'customAtividadeRuralForm': {
            'key': _atividadeRuralFormKey,
            'message': S.of(context).edit_rural_activity_info,
            'shape': 'RRect',
            'align': 'ContentAlign.bottom',
          },
          'customTalhoes': {
            'key': _talhoesKey,
            'message': S.of(context).manage_plots_info,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          'customFirstTalhaoMoreOptions': {
            'key': _firstTalhaoMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options_on_first_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
            'hasMoreOptions': true,
          },
          'operacoes': {
            'key': _operacoesKey,
            'message': S.of(context).operations_of_activity,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          'moreOptionsOperacao': {
            'key': _firstOperacaoMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options_on_first_operation,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
            'hasMoreOptions': true,
          },
        },
        customActionTutorialSteps: {
          'linkTalhao': {
            'key': _addTalhaoKey,
            'message': S.of(context).link_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
          'addOperacao': {
            'key': _addOperacaoKey,
            'message': S.of(context).add_operation,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Icon(Icons.agriculture, color: theme.colorScheme.primary),
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
                // Campos de Identificação
                // Tipo de Atividade
                ObjectTemplate.getDropdownButtonFormField(
                  context: context,
                  labelText: S.of(context).activity_type,
                  value: _selectedTipo,
                  items: AtividadeRuralOptions.tiposAtividade,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTipo = newValue ?? '';
                      _updateSubtipos();
                      _hasChanges = true;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).select_activity_type;
                    }
                    return null;
                  },
                  dropdownItems: AtividadeRuralOptions.tiposAtividade.map((String tipo) {
                    return DropdownMenuItem<String>(
                      value: tipo,
                      child: Text(AtividadeRuralOptions.getLocalizedTiposAtividades(context)[tipo] ?? tipo),
                    );
                  }).toList(),
                ),
                SizedBox(height: 16),

                // Categoria
                ObjectTemplate.getDropdownButtonFormField(
                  context: context,
                  labelText: S.of(context).categoria,
                  value: _selectedSubtipo,
                  items: _subtipos,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSubtipo = newValue ?? '';
                      _hasChanges = true;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.of(context).select_categoria;
                    }
                    return null;
                  },
                  dropdownItems: _subtipos.map((String subtipo) {
                    return DropdownMenuItem<String>(
                      value: subtipo,
                      child: Text(AtividadeRuralOptions.getLocalizedSubtiposAtividades(context)[_selectedTipo]?.elementAt(_subtipos.indexOf(subtipo)) ?? subtipo),
                    );
                  }).toList(),
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
                  textInputAction: TextInputAction.next,
                ),

                SizedBox(height: 24),

                Row(
                  children: [
                    Icon(Icons.date_range, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).dates,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Campos de Datas
                TextFormField(
                  controller: TextEditingController(
                    text: FormatacaoUtil.formatDate(_dataInicio),
                  ),
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).start_date,
                    suffixIcon: Icon(Icons.calendar_today),
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
                  //isExpanded: true,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: TextEditingController(
                    text: _dataFim != null ? FormatacaoUtil.formatDate(_dataFim!) : '',
                  ),
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).end_date,
                    suffixIcon: Icon(Icons.calendar_today),
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
                  //isExpanded: true,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        cardSections: [
          _buildTalhoesCardsRefatorado(),
          _buildOperacoesCardsRefatorado(),
          /*
          CardSection(
            title: S.of(context).rural_operations,
            key: _operacoesKey,
            cards: _buildOperacoesCards(),
          ),

           */
        ],
      ),
    );
  }

  CardSection _buildOperacoesCardsRefatorado() {
    return ObjectTemplate.buildCardSectionWithFuture<OperacaoRural>(
      key: _operacoesKey,
      title: S.of(context).rural_operations, // Título da seção
      iconePrincipal: CustomIcons.trator_operacao_2, // Ícone representativo para Operação Rural
      future: _futureOperacoes, // Future que retorna a lista de OperacaoRural
      itemTitle: (operacao) => OperacaoRuralOptions.getLocalizedFasesOperacoes(context)[operacao.fase] ?? operacao.fase,
      itemSubtitle: (operacao) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).start_date}: ${FormatacaoUtil.formatDate(operacao.dataInicio)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (operacao.dataFim != null)
              Text(
                '${S.of(context).end_date}: ${FormatacaoUtil.formatDate(operacao.dataFim!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (operacao.area != null)
              Text(
                '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(operacao.area!)} ${S.of(context).hectares}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        );
      },
      onEdit: (operacao) => _navigateToOperacaoRuralFormScreen(operacao),
      onDelete: (operacao) => _deleteOperacao(operacao),
      //itemLeadingIcon: Icons.build, // Ícone opcional para cada ListTile
      loadingText: S.of(context).loading, // Texto durante o carregamento
      errorText: S.of(context).error_loading, // Texto em caso de erro
      notFoundText: S.of(context).no_operations_registered, // Texto quando nenhuma operação é encontrada
      firstItemMoreOptionsKey: _firstOperacaoMoreOptionsKey, // Chave para o primeiro item
    );
  }

  void _deleteOperacao(OperacaoRural operacao) async {
    await DialogScreen.confirmDelete(
      context,
      serviceName: _operacaoRuralService,
      itemIdValue: operacao.id,
      itemName: S.of(context).rural_operation,
      onSuccessDialog: () async {
        try {
          await _operacaoRuralService.delete(operacao.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).operation_deleted_successfully)),
          );
          _loadOperacoes(); // Certifique-se de que esta linha está presente
          setState(() {}); // Adicione esta linha para garantir a reconstrução do widget
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).error_deleting_operation)),
          );
        }
      },
    );
  }

  CardSection _buildTalhoesCardsRefatorado() {
    return ObjectTemplate.buildCardSectionWithFuture<Talhao>(
      key: _talhoesKey,
      title: S.of(context).plots,
      iconePrincipal: Icons.landscape, // Ícone representativo para Talhão
      future: _futureTalhoes,
      itemTitle: (talhao) => talhao.nome,
      itemSubtitle: (talhao) {
        bool markedForRemoval = _talhoesParaRemover.contains(talhao.id);
        return Text(
          '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
              //color: markedForRemoval ? Colors.grey : null,
              ),
        );
      },
      onEdit: null, // Se necessário, implementar a lógica de edição
      onDelete: (talhao) {
        bool markedForRemoval = _talhoesParaRemover.contains(talhao.id);
        if (markedForRemoval) {
          _desfazerRemocaoTalhao(talhao.id);
        } else {
          _removeTalhao(talhao.id);
        }
      },
      //itemLeadingIcon: CustomIcons.field, // Ícone personalizado
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_plots_linked,
      firstItemMoreOptionsKey: _firstTalhaoMoreOptionsKey,

      itemTrailing: (talhao, index) {
        bool markedForRemoval = _talhoesParaRemover.contains(talhao.id);
        return IconButton(
          icon: Icon(
            markedForRemoval ? Icons.undo : Icons.delete,
            //color: markedForRemoval ? Colors.grey : Theme.of(context).colorScheme.error,
          ),
          onPressed: () {
            if (markedForRemoval) {
              _desfazerRemocaoTalhao(talhao.id);
            } else {
              _removeTalhao(talhao.id);
            }
          },
        );
      },
      cardDecoration: (talhao) {
        if (_talhoesParaRemover.contains(talhao.id)) {
          return BoxDecoration(
            color: Colors.red.withOpacity(0.1), // Cor de fundo vermelha suave
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: Colors.red, width: 1),
          );
        } else {
          return BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
          );
        }
      },
    );
  }

  Future<void> _removeTalhao(String talhaoId) async {
    bool confirmarRemocao = false;

    confirmarRemocao = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(S.of(context).linked_operations_warning),
            content: Text(S.of(context).confirm_plot_removal_from_activity),
            actions: <Widget>[
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(S.of(context).proceed),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ??
        false;

    if (await _operacaoRuralService.hasTalhaoVinculado(widget.atividadeRural!.id, talhaoId)) {
      confirmarRemocao = false;
      // Exibir diálogo de confirmação adicional
      confirmarRemocao = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(S.of(context).linked_operations_warning),
              content: Text(S.of(context).talhao_linked_operations_confirmation),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).proceed),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          ) ??
          false;
    }

    if (confirmarRemocao) {
      setState(() {
        if (!_talhoesParaRemover.contains(talhaoId)) {
          _talhoesParaRemover.add(talhaoId);
        }
        _hasChanges = true;
      });

      _atualizarAreaTotal();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).plot_marked_for_removal),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _desfazerRemocaoTalhao(String talhaoId) {
    setState(() {
      _talhoesParaRemover.remove(talhaoId);
      _hasChanges = true;
    });

    _atualizarAreaTotal();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).plot_removal_undone),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _atualizarAreaTotal() async {
    List<Talhao> talhoes = await _talhaoService.getByIds(_talhoes);
    double novaAreaTotal = talhoes.where((talhao) => !_talhoesParaRemover.contains(talhao.id)).fold(0, (sum, talhao) => sum + talhao.area);

    setState(() {
      // Atualize a área total da atividade, se necessário
      // _currentAtividadeRural = _currentAtividadeRural.copyWith(area: novaAreaTotal);
    });
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
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: selectedDate != null ? DateFormat.yMMMd().format(selectedDate) : '',
          ),
          validator: (value) {
            if (label == S.of(context).start_date && (value?.isEmpty ?? true)) {
              return S.of(context).select_start_date;
            }
            return null;
          },
        ),
      ),
    );
  }
}
