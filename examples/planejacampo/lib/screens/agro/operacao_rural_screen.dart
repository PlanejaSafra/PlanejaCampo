import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/models/operacao_rural.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/services/operacao_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/services/item_operacao_rural_service.dart';
import 'package:planejacampo/screens/agro/operacao_rural_form_screen.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/operacao_rural_options.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhoes_list_screen.dart';
import 'package:planejacampo/screens/agro/item_operacao_rural_form_screen.dart';
import 'package:planejacampo/models/item_operacao_rural.dart';
import 'package:planejacampo/models/item.dart';
import 'package:planejacampo/utils/item_options.dart';
import 'package:planejacampo/services/item_service.dart';
import 'package:planejacampo/models/frota_operacao_rural.dart';
import 'package:planejacampo/services/frota_operacao_rural_service.dart';
import 'package:planejacampo/screens/agro/frota_operacao_rural_form_screen.dart';
import 'package:planejacampo/services/frota_service.dart';

class OperacaoRuralScreen extends StatefulWidget {
  final OperacaoRural operacaoRural;

  const OperacaoRuralScreen({
    Key? key,
    required this.operacaoRural,
  }) : super(key: key);

  @override
  _OperacaoRuralScreenState createState() => _OperacaoRuralScreenState();
}

class _OperacaoRuralScreenState extends State<OperacaoRuralScreen> {
  final String _moduleName = 'operacoesRurais';
  final OperacaoRuralService _operacaoRuralService = OperacaoRuralService();
  final TalhaoService _talhaoService = TalhaoService();
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  final ItemOperacaoRuralService _itemOperacaoRuralService = ItemOperacaoRuralService();
  final ItemService _itemService = ItemService();
  late Future<OperacaoRural?> _futureOperacao;
  late Future<List<Talhao>> _futureTalhoes;
  late Future<TipoOperacaoRural?> _futureTipoOperacao;
  late Future<List<ItemOperacaoRural>> _futureItensOperacao;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late OperacaoRural _currentOperacaoRural;
  Object _returnObject = '';
  Map<String, String> _itemNames = {};

  final FrotaOperacaoRuralService _frotaOperacaoRuralService = FrotaOperacaoRuralService();
  final FrotaService _frotaService = FrotaService();
  late Future<List<FrotaOperacaoRural>> _futureFrotasOperacao;
  Map<String, String> _frotaNames = {};

  final GlobalKey _frotasOperacaoKey = GlobalKey();
  final GlobalKey _addFrotaOperacaoKey = GlobalKey();
  final GlobalKey _firstFrotaMoreOptionsKey = GlobalKey();
  final GlobalKey _talhoesKey = GlobalKey();
  final GlobalKey _addTalhaoKey = GlobalKey();
  final GlobalKey _itensOperacaoKey = GlobalKey();
  final GlobalKey _addItemOperacaoKey = GlobalKey();
  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstItemMoreOptionsKey = GlobalKey();
  final GlobalKey _firstItemEditKey = GlobalKey();
  final GlobalKey _firstItemDeleteKey = GlobalKey();


  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentOperacaoRural = widget.operacaoRural;
    _loadOperacaoRural();
    _checkPermissions();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('operacaoRuralScreen');
    appStateManager.setShowTutorial('operacaoRuralScreen', false);
  }

  void _loadOperacaoRural() {
    setState(() {
      _futureOperacao = _operacaoRuralService.getById(_currentOperacaoRural.id);
      _futureTalhoes = _talhaoService.getByIds(_currentOperacaoRural.talhoes ?? []);
      _futureTipoOperacao = _tipoOperacaoRuralService.getById(_currentOperacaoRural.tipoOperacaoRuralId);
      _futureItensOperacao = _itemOperacaoRuralService.getByAttributes({'operacaoRuralId': _currentOperacaoRural.id});
      _futureFrotasOperacao = _frotaOperacaoRuralService.getByAttributes({'operacaoRuralId': _currentOperacaoRural.id});

      // Limpa os maps antes de recarregar
      _itemNames.clear();
      _frotaNames.clear();
    });

    // Carrega nomes dos itens
    _futureItensOperacao.then((itensOperacao) async {
      if (itensOperacao.isNotEmpty) {
        final itemIds = itensOperacao.map((item) => item.itemId).toSet().toList();
        final items = await _itemService.getByIds(itemIds);
        if (mounted) {
          setState(() {
            _itemNames = { for (var item in items) item.id: item.nome };
          });
        }
      }
    });

    // Carrega nomes das frotas
    _futureFrotasOperacao.then((frotasOperacao) async {
      print('Frotas operação carregadas: ${frotasOperacao.length}');
      if (frotasOperacao.isNotEmpty) {
        final frotaIds = frotasOperacao.map((frota) => frota.frotaId).toSet().toList();
        print('IDs das frotas: $frotaIds');
        if (frotaIds.isNotEmpty) {
          final frotas = await _frotaService.getByIds(frotaIds);
          print('Frotas carregadas: ${frotas.length}');
          if (mounted) {
            setState(() {
              _frotaNames = { for (var frota in frotas) frota.id: frota.nome };
              print('Nomes das frotas carregados: ${_frotaNames.length}');
            });
          }
        }
      }
    });
  }


  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            OperacaoRuralFormScreen(
              operacaoRural: _currentOperacaoRural,
              atividadeId: _currentOperacaoRural.atividadeId,
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
    ).then((updatedOperacaoRural) {
      if (updatedOperacaoRural != null) {
        _returnObject = true;
        if (updatedOperacaoRural is OperacaoRural) {
          setState(() {
            _currentOperacaoRural = updatedOperacaoRural;
          });
        }
        _loadOperacaoRural();
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
      title: S.of(context).rural_operation,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).rural_operation,
      nomeTutorialPlural: S.of(context).rural_operations,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _operacaoRuralService,
      itemIdValue: widget.operacaoRural.id,
      itemName: S.of(context).rural_operation,
      fieldReference: 'operacaoRuralId',
      cardSections: [
        _buildTalhoesCards(),
        _buildItensOperacaoCards(),
        _buildFrotasOperacaoCards(),
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
        'itensOperacao': {
          'key': _itensOperacaoKey,
          'message': S.of(context).operation_items_info,
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
        if (FormatacaoUtil.hasValidPosition(_firstItemMoreOptionsKey))
          'moreOptionsItem': {
            'key': _firstItemMoreOptionsKey,
            'message': S.of(context).click_to_see_more_options,
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
        'addItemOperacao': {
          'key': _addItemOperacaoKey,
          'message': S.of(context).add_operation_item,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
        },
      },
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
        ObjectTemplate.buildCustomFloatingActionButton(
          context: context,
          onPressed: () async {
            _toggleFloatingActionButton();
            //await _showItemOperacaoRuralFormScreen();
            await _navigateToItemOperacaoRuralFormScreen(null);
          },
          icon: Icons.add,
          text: S.of(context).add_item,
          key: _addItemOperacaoKey,
          heroTag: 'addItemOperacao',
        ),
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
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<OperacaoRural?>(
      future: _futureOperacao,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final operacaoRural = snapshot.data!;
          final localizedFases = OperacaoRuralOptions.getLocalizedFasesOperacoes(context);
          final localizedTipoOperacao = _futureTipoOperacao;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.category, // Ícone representativo para Fase
                    label: S.of(context).fase,
                    value: localizedFases[operacaoRural.fase] ?? operacaoRural.fase,
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.date_range, // Ícone para Data de Início
                    label: S.of(context).start_date,
                    value: FormatacaoUtil.formatDate(operacaoRural.dataInicio),
                  ),
                  if (operacaoRural.dataFim != null) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.date_range, // Ícone para Data de Fim
                      label: S.of(context).end_date,
                      value: FormatacaoUtil.formatDate(operacaoRural.dataFim!),
                    ),
                  ],
                  if (operacaoRural.area != null) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.area_chart, // Ícone representativo para Área
                      label: S.of(context).area,
                      value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(operacaoRural.area!)} ${S.of(context).hectares}',
                    ),
                  ],
                  if (operacaoRural.descricao != null && operacaoRural.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ObjectTemplate.buildInfoRow(
                      context: context,
                      icon: Icons.description, // Ícone representativo para Descrição
                      label: S.of(context).description,
                      value: operacaoRural.descricao!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  FutureBuilder<TipoOperacaoRural?>(
                    future: _futureTipoOperacao,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError || !snapshot.hasData) {
                        return ObjectTemplate.buildInfoRow(
                          context: context,
                          icon: Icons.error,
                          label: S.of(context).operation_type,
                          value: S.of(context).error_loading,
                        );
                      } else {
                        return ObjectTemplate.buildInfoRow(
                          context: context,
                          icon: Icons.category, // Ícone representativo para Tipo de Operação
                          label: S.of(context).operation_type,
                          value: snapshot.data!.nome,
                        );
                      }
                    },
                  ),
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
      onEdit: null, // Defina se a edição estiver disponível
      onDelete: (talhao) => _removeTalhao(talhao.id),
      itemLeadingIcon: CustomIcons.field, // Ícone personalizado para Talhão
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).plot_not_found,
      firstItemMoreOptionsKey: _firstTalhaoMoreOptionsKey,
    );
  }

// Método Atualizado _buildItensOperacaoCards
  CardSection _buildItensOperacaoCards() {
    return ObjectTemplate.buildCardSectionWithFuture<ItemOperacaoRural>(
      key: _itensOperacaoKey,
      title: S.of(context).operation_items,
      iconePrincipal: Icons.list, // Ícone representativo para Itens da Operação
      future: _futureItensOperacao,
      //itemTitle: (item) async => item.itemId, // Supondo que 'nome' exista em ItemOperacaoRural
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
      onEdit: (item) => _navigateToItemOperacaoRuralFormScreen(item),
      onDelete: (item) => _removeItemOperacao(item),
      itemLeadingIcon: Icons.shopping_cart, // Ícone personalizado para Itens da Operação
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_items_linked,
      firstItemMoreOptionsKey: _firstItemMoreOptionsKey,
    );
  }

  Future<void> _navigateToItemOperacaoRuralFormScreen(ItemOperacaoRural? item) async {
    final result = await Navigator.push<ItemOperacaoRural?>(
      context,
      MaterialPageRoute(
        builder: (context) => ItemOperacaoRuralFormScreen(
          operacaoRural: _currentOperacaoRural,
          itemOperacaoRural: item,
        ),
      ),
    );

    if (result != null) {  // Se temos um resultado válido (item novo ou editado)
      try {
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

        if (item == null) {  // Novo item
          await _itemOperacaoRuralService.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).item_added_to_operation)),
          );
        } else {  // Atualização
          await _itemOperacaoRuralService.update(result.id, result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).item_updated_successfully)),
          );
        }

        Navigator.of(context).pop(); // Fecha o diálogo de processamento
        _loadOperacaoRural(); // Recarrega os dados

      } catch (e) {
        Navigator.of(context).pop(); // Fecha o diálogo de processamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_saving_operation(e.toString()))),
        );
      }
    }
    // Se result for null, usuário cancelou ou voltou sem alterações
  }


  Future<void> _showTalhoesSelectionScreen() async {
    List<Talhao> currentSelectedTalhoes = await _talhaoService.getByIds(_currentOperacaoRural.talhoes ?? []);

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
        _currentOperacaoRural = _currentOperacaoRural.copyWith(
          talhoes: selectedTalhoes.map((t) => t.id).toList(),
        );
      });
      await _operacaoRuralService.update(_currentOperacaoRural.id, _currentOperacaoRural);
      _loadOperacaoRural();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).plots_linked_successfully)),
      );
    }
  }

  void _removeTalhao(String talhaoId) async {
    setState(() {
      _currentOperacaoRural = _currentOperacaoRural.copyWith(
        talhoes: _currentOperacaoRural.talhoes?.where((id) => id != talhaoId).toList(),
      );
    });
    await _operacaoRuralService.update(_currentOperacaoRural.id, _currentOperacaoRural);
    _loadOperacaoRural();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(S.of(context).plot_removed_from_operation)),
    );
  }

  void _removeItemOperacao(ItemOperacaoRural item) async {
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).operation_item)),
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
      // Mostrar diálogo de progresso
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
        await _itemOperacaoRuralService.delete(item.id);
        //await _operacaoRuralService.update(_currentOperacaoRural.id, _currentOperacaoRural);
        Navigator.of(context).pop(); // Fechar diálogo de progresso
        _loadOperacaoRural();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).item_removed_from_operation)),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Fechar diálogo de progresso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_removing_item(e.toString()))),
        );
      }
    }
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

  Future<void> _navigateToFrotaOperacaoRuralFormScreen(FrotaOperacaoRural? frotaOperacao) async {
    final result = await Navigator.push<FrotaOperacaoRural?>(
      context,
      MaterialPageRoute(
        builder: (context) => FrotaOperacaoRuralFormScreen(
          operacaoRural: _currentOperacaoRural,
          frotaOperacaoRural: frotaOperacao,
        ),
      ),
    );

    if (result != null) {
      try {
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

        if (frotaOperacao == null) {
          // Nova vinculação
          final frota = await _frotaService.getById(result.frotaId);
          if (frota == null) throw Exception('Frota não encontrada');

          // Adiciona as horas ao horímetro da nova frota
          double novoHorimetro = (frota.horimetroOdometro ?? 0.0) + result.horasUtilizadas;
          await _frotaService.update(frota.id, frota.copyWith(horimetroOdometro: novoHorimetro));

          // Salva a nova vinculação
          await _frotaOperacaoRuralService.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).add_fleet_operation_success_plural)),
          );
        } else {
          // Atualização
          if (frotaOperacao.frotaId != result.frotaId) {
            // Frota foi trocada: precisa atualizar ambas as frotas

            // Atualiza a frota anterior (remove as horas)
            final frotaAnterior = await _frotaService.getById(frotaOperacao.frotaId);
            if (frotaAnterior != null) {
              double horimetroAnterior = (frotaAnterior.horimetroOdometro ?? 0.0) - frotaOperacao.horasUtilizadas;
              await _frotaService.update(
                  frotaAnterior.id,
                  frotaAnterior.copyWith(horimetroOdometro: horimetroAnterior)
              );
            }

            // Atualiza a nova frota (adiciona as horas)
            final frotaNova = await _frotaService.getById(result.frotaId);
            if (frotaNova == null) throw Exception('Nova frota não encontrada');

            double horimetroNovo = (frotaNova.horimetroOdometro ?? 0.0) + result.horasUtilizadas;
            await _frotaService.update(
                frotaNova.id,
                frotaNova.copyWith(horimetroOdometro: horimetroNovo)
            );
          } else {
            // Mesma frota: apenas atualiza o horímetro com a diferença
            final frota = await _frotaService.getById(result.frotaId);
            if (frota == null) throw Exception('Frota não encontrada');

            double novoHorimetro = (frota.horimetroOdometro ?? 0.0) - frotaOperacao.horasUtilizadas + result.horasUtilizadas;
            await _frotaService.update(
                frota.id,
                frota.copyWith(horimetroOdometro: novoHorimetro)
            );
          }

          // Atualiza a vinculação
          await _frotaOperacaoRuralService.update(result.id, result);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).edit_fleet_operation_success_plural)),
          );
        }

        Navigator.of(context).pop(); // Fecha o diálogo de processamento
        _loadOperacaoRural(); // Recarrega os dados

      } catch (e) {
        Navigator.of(context).pop(); // Fecha o diálogo de processamento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_saving_operation(e.toString()))),
        );
      }
    }
  }

  void _removeFrotaOperacao(FrotaOperacaoRural frotaOperacao) async {
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
        // Busca a frota para atualizar seu horímetro
        final frota = await _frotaService.getById(frotaOperacao.frotaId);
        if (frota != null) {
          // Remove as horas utilizadas do horímetro da frota
          double novoHorimetro = (frota.horimetroOdometro ?? 0.0) - frotaOperacao.horasUtilizadas;

          // Atualiza o horímetro da frota
          await _frotaService.update(
              frota.id,
              frota.copyWith(horimetroOdometro: novoHorimetro)
          );
        }

        // Remove a vinculação
        await _frotaOperacaoRuralService.delete(frotaOperacao.id);

        Navigator.of(context).pop();
        _loadOperacaoRural();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).fleet_operation_removed_plural)),
        );
      } catch (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).error_removing_fleet_operation_plural(e.toString()))),
        );
      }
    }
  }

  @override
  void dispose() {
    // Clean up resources if necessary
    super.dispose();
  }
}