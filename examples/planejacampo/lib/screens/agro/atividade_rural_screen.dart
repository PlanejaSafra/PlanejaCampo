import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/screens/agro/atividade_rural_form_screen.dart';
import 'package:planejacampo/screens/agro/operacao_rural_form_screen.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/atividade_rural_options.dart';
import 'package:planejacampo/utils/operacao_rural_options.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';
import 'package:planejacampo/screens/appbar/talhoes_list_screen.dart';

class AtividadeRuralScreen extends StatefulWidget {
  final AtividadeRural atividadeRural;

  const AtividadeRuralScreen({
    Key? key,
    required this.atividadeRural,
  }) : super(key: key);

  @override
  _AtividadeRuralScreenState createState() => _AtividadeRuralScreenState();
}

class _AtividadeRuralScreenState extends State<AtividadeRuralScreen> {
  final String _moduleName = 'atividadesRurais';
  final AtividadeRuralService _atividadeRuralService = AtividadeRuralService();
  final TalhaoService _talhaoService = TalhaoService();
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  late Future<AtividadeRural?> _futureAtividade;
  late Future<List<Talhao>> _futureTalhoes;
  late Future<List<OperacaoRural>> _futureOperacoes;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late AtividadeRural _currentAtividadeRural;
  Object _returnObject = '';

  final GlobalKey _talhoesKey = GlobalKey();
  final GlobalKey _operacoesKey = GlobalKey();
  final GlobalKey _addTalhaoKey = GlobalKey();
  final GlobalKey _addOperacaoKey = GlobalKey();

  bool _isExpanded = false;

  late TalhaoDialogScreen _talhaoDialogScreen;

  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstTalhaoEditKey = GlobalKey();
  final GlobalKey _firstTalhaoDeleteKey = GlobalKey();
  final GlobalKey _firstOperacaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstOperacaoEditKey = GlobalKey();
  final GlobalKey _firstOperacaoDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentAtividadeRural = widget.atividadeRural;
    _loadAtividadeRural();
    _checkPermissions();

    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: _currentAtividadeRural.propriedadeId,
      talhaoService: _talhaoService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: () {
        _returnObject = true;
        _loadAtividadeRural();
        setState(() {});
      },
      firstTalhaoMoreOptionsKey: _firstTalhaoMoreOptionsKey,
      firstTalhaoEditKey: _firstTalhaoEditKey,
      firstTalhaoDeleteKey: _firstTalhaoDeleteKey,
    );

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('atividadeRuralScreen');
    appStateManager.setShowTutorial('atividadeRuralScreen', false);
  }

  void _loadAtividadeRural() {
    setState(() {
      _futureAtividade = _atividadeRuralService.getById(_currentAtividadeRural.id);
      _futureTalhoes = _talhaoService.getByIds(_currentAtividadeRural.talhoes ?? []);
      _futureOperacoes = _operacaoRuralService.getByAttributes({'atividadeId': _currentAtividadeRural.id});
    });
  }


  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
      // Se for a Atividade Rural Ativa no contexto,não pode remover.
      if (_canDelete && (widget.atividadeRural.id == appStateManager.activeAtividadeRural?.id )) {
        _canDelete = false;
      }
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AtividadeRuralFormScreen(atividadeRural: _currentAtividadeRural),
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
    ).then((updatedAtividadeRural) {
      if (updatedAtividadeRural != null) {
        _returnObject = true;
        if (updatedAtividadeRural is AtividadeRural) {
          setState(() {
            _currentAtividadeRural = updatedAtividadeRural;
          });
        }
        _loadAtividadeRural();
      }
    });
  }

  void _navigateToOperacaoRuralFormScreen([OperacaoRural? operacao]) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OperacaoRuralFormScreen(
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
    ).then((result) {
      if (result != null) {
        setState(() {
          _returnObject = true;
          _loadAtividadeRural();
        });
      }
    });
  }


  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).rural_activity_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).rural_activity,
      nomeTutorialPlural: S.of(context).rural_activities,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _atividadeRuralService,
      itemIdValue: widget.atividadeRural.id,
      itemName: S.of(context).rural_activity,
      fieldReference: 'atividadeRuralId',
      cardSections: [
        _buildTalhoesCards(),
        _buildOperacoesCards(),
      ],
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: {
        'talhoes': {
          'key': _talhoesKey,
          'message': S.of(context).plots_linked_to_activity,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        'operacoes': {
          'key': _operacoesKey,
          'message': S.of(context).operations_of_activity,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        if (FormatacaoUtil.hasValidPosition(_firstTalhaoMoreOptionsKey))
          'moreOptionsTalhao': {
            'key': _firstTalhaoMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options_on_first_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
            'hasMoreOptions': true,
          },
        if (FormatacaoUtil.hasValidPosition(_firstOperacaoMoreOptionsKey))
          'moreOptionsOperacao': {
            'key': _firstOperacaoMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options_on_first_operation,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
            'hasMoreOptions': true,
          },
      },
      customActionTutorialSteps: {
        'addTalhao': {
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
      additionalFloatingActionButtons: (BuildContext context) => [
        ObjectTemplate.buildCustomFloatingActionButton(
          context: context,
          onPressed: () async {
            _toggleFloatingActionButton();
            await _linkTalhoes(context);
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
    );
  }

  // Atualizado _buildSummarySection
  Widget _buildSummarySection() {
    return FutureBuilder<AtividadeRural?>(
      future: _futureAtividade,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final atividadeRural = snapshot.data!;
          final localizedTipos = AtividadeRuralOptions.getLocalizedTiposAtividades(context);
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.category, // Ícone para Tipo
                    label: S.of(context).type,
                    value: localizedTipos[atividadeRural.tipo] ?? atividadeRural.tipo,
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.date_range, // Ícone para Data de Início
                    label: S.of(context).start_date,
                    value: FormatacaoUtil.formatDate(atividadeRural.dataInicio!),
                  ),
                  if (atividadeRural.dataFim != null)
                    ...[
                      const SizedBox(height: 8),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.date_range, // Ícone para Data de Fim
                        label: S.of(context).end_date,
                        value: FormatacaoUtil.formatDate(atividadeRural.dataFim!),
                      ),
                    ],
                  if (atividadeRural.nome != null && atividadeRural.nome!.isNotEmpty)
                    ...[
                      const SizedBox(height: 8),
                      ObjectTemplate.buildInfoRow(
                        context: context,
                        icon: Icons.text_fields, // Ícone para Nome
                        label: S.of(context).name,
                        value: atividadeRural.nome!,
                      ),
                    ],
                ],
              ),
            ),
          );
        }
      },
    );
  }


  // Método Atualizado _buildTalhoesCards
  CardSection _buildTalhoesCards() {
    return ObjectTemplate.buildCardSectionWithFuture<Talhao>(
      key: _talhoesKey,
      title: S.of(context).plots,
      iconePrincipal: Icons.landscape, // Ícone representativo para Talhão
      future: _futureTalhoes,
      itemTitle: (talhao) => talhao.nome,
      itemSubtitle: (talhao) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
      onEdit: null,
      onDelete: (talhao) => _removeTalhao(talhao.id),
      itemLeadingIcon: CustomIcons.field, // Agora definido corretamente
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).plot_not_found,
      firstItemMoreOptionsKey: _firstTalhaoMoreOptionsKey,
    );
  }

// Método Atualizado _buildOperacoesCards
  CardSection _buildOperacoesCards() {
    return ObjectTemplate.buildCardSectionWithFuture<OperacaoRural>(
      key: _operacoesKey,
      title: S.of(context).rural_operations,
      iconePrincipal: Icons.build, // Ícone representativo para Operação Rural
      future: _futureOperacoes,
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
      itemLeadingIcon: Icons.build, // Opcional, pode ser omitido
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_operations_registered,
      firstItemMoreOptionsKey: _firstOperacaoMoreOptionsKey,
    );
  }



  Future<void> _linkTalhoes(BuildContext context) async {
    List<Talhao> currentSelectedTalhoes = [];
    if (_currentAtividadeRural.talhoes != null && _currentAtividadeRural.talhoes!.isNotEmpty) {
      currentSelectedTalhoes = await _talhaoService.getByIds(_currentAtividadeRural.talhoes!);
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
      try {
        // Atualiza a atividade rural no banco de dados imediatamente
        _currentAtividadeRural = _currentAtividadeRural.copyWith(
          talhoes: selectedTalhoes.map((t) => t.id).toList(),
        );
        await _atividadeRuralService.update(_currentAtividadeRural.id, _currentAtividadeRural);

        setState(() {
          _returnObject = true;
        });
        _loadAtividadeRural(); // Recarrega os dados da atividade rural
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).plots_linked_successfully),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.of(context).error_linking_plots}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _removeTalhao(String talhaoId) async {
    //print("Entrou em _removeTalhao");
    // Buscar todas as operações vinculadas à atividade atual
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
    ) ?? false;

    if (await _operacaoRuralService.hasTalhaoVinculado(widget.atividadeRural.id, talhaoId)) {
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
      ) ?? false;
    }

    if (confirmarRemocao) {
      try {
        // Remove o talhão da atividade
        _currentAtividadeRural.talhoes?.remove(talhaoId);
        await _atividadeRuralService.update(_currentAtividadeRural.id, _currentAtividadeRural);
        _loadAtividadeRural();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).plot_removed_from_activity)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context).error_removing_plot_from_activity}: ${e.toString()}')),
        );
      }
    }
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
          _loadAtividadeRural();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).error_deleting_operation)),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    // Limpar recursos, se necessário
    super.dispose();
  }
}