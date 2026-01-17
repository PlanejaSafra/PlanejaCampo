import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class ScreenTemplate extends StatefulWidget {
  final String title;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final String moduleName;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final Widget? bottomNavigationBar;
  final List<Widget>? additionalActions;
  final bool showTutorial;
  final String nomeTutorial;
  final String nomeTutorialPlural;
  final Map<String, Map<String, dynamic>> customTutorialSteps;

  const ScreenTemplate({
    Key? key,
    required this.title,
    required this.body,
    required this.moduleName,
    this.floatingActionButton,
    this.showDeleteButton = false,
    this.onDeletePressed,
    this.bottomNavigationBar,
    this.additionalActions,
    this.showTutorial = false,
    this.nomeTutorial = '',
    this.nomeTutorialPlural = '',
    this.customTutorialSteps = const {},
  }) : super(key: key);

  @override
  _ScreenTemplateState createState() => _ScreenTemplateState();
}

class _ScreenTemplateState extends State<ScreenTemplate> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey addButtonKey = GlobalKey();
  final GlobalKey backButtonKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey bodyKey = GlobalKey();

  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 300));
      if (widget.showTutorial) {
        _startTutorial();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    tutorialCoachMark?.finish();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isTutorialRunning) {
      _isRecreatingScrappedTutorial = true;
      tutorialCoachMark?.finish();
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _startTutorial() {
    if (_isTutorialRunning && !_isRecreatingScrappedTutorial) {
      return;
    }
    _isTutorialRunning = true;
    _isRecreatingScrappedTutorial = false;
    final theme = Theme.of(context);
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.black,
      textSkip: "Pular",
      textStyleSkip: theme.textTheme.labelLarge ??
          TextStyle(fontSize: 16, color: Colors.white),
      alignSkip: Alignment.bottomLeft,
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        //print("Tutorial concluído");
        _isTutorialRunning = false;
      },
      onSkip: () {
        //print("Tutorial pulado");
        _isTutorialRunning = false;
        return true;
      },
      onClickTarget: (target) {
        //print("Clicked on target: ${target.identify}");
      },
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    final theme = Theme.of(context);
    targets.clear();

    if (widget.floatingActionButton != null) {
      targets.add(
        TargetFocus(
          identify: "addButton",
          keyTarget: addButtonKey,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: Text(
                "Clique aqui para incluir ${widget.nomeTutorial}.",
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    }

    targets.add(
      TargetFocus(
        identify: "backButton",
        keyTarget: backButtonKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Clique aqui para voltar à tela anterior.",
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );

    targets.add(
      TargetFocus(
        identify: "moreOptions",
        keyTarget: moreOptionsKey,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: Text(
              "Clique aqui para ver mais opções.",
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );

    targets.add(
      TargetFocus(
        identify: "bodyKey",
        keyTarget: bodyKey,
        contents: [
          TargetContent(
            align: ContentAlign.custom,
            customPosition: CustomTargetContentPosition(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
            ),
            child: Center(
              child: Text(
                "Aqui você pode visualizar e editar os detalhes do ${widget.nomeTutorial}.",
                style: theme.textTheme.titleLarge,
              ),
            ),
          ),
        ],
        shape: ShapeLightFocus.RRect,
      ),
    );

    widget.customTutorialSteps.forEach((key, value) {
      targets.add(
        TargetFocus(
          identify: key,
          keyTarget: value['key'] as GlobalKey,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Text(
                value['message'] as String,
                style: theme.textTheme.titleLarge,
              ),
            ),
          ],
          shape: _getShapeFromString(value['shape'] as String?),
        ),
      );
    });

    return targets;
  }

  ShapeLightFocus _getShapeFromString(String? shape) {
    switch (shape) {
      case 'Circle':
        return ShapeLightFocus.Circle;
      case 'RRect':
        return ShapeLightFocus.RRect;
      default:
        return ShapeLightFocus.Circle;
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Deseja realmente excluir este ${widget.nomeTutorial}?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Excluir'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      if (widget.onDeletePressed != null) {
        widget.onDeletePressed!();
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final bool canEdit = appStateManager.canEdit(widget.moduleName);
    final bool canDelete = appStateManager.canDelete(widget.moduleName);
    //final FormatacaoUtil formatacaoUtil = appStateManager.formatacao;
    final ThemeData theme = Theme.of(context);

    List<Widget> appBarActions = [];

    if (widget.showDeleteButton && canDelete) {
      appBarActions.add(
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _confirmDelete(context),
        ),
      );
    }

    appBarActions.add(
      PopupMenuButton<String>(
        key: moreOptionsKey,
        icon: Icon(Icons.more_vert),
        onSelected: (String result) {
          if (result == 'Ajuda') {
            _startTutorial();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: 'Ajuda',
            child: Text(
              'Ajuda',
              style: Theme.of(context).popupMenuTheme.textStyle,
            ),
          ),
        ],
        offset: Offset(0, 56),
      ),
    );

    if (widget.additionalActions != null) {
      appBarActions.addAll(widget.additionalActions!);
    }

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          key: backButtonKey,
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge,
        ),
        centerTitle: true,
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 4,
        actions: appBarActions,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          key: bodyKey,
          child: widget.body,
        ),
      ),
      floatingActionButton: widget.floatingActionButton != null && (canEdit || widget.moduleName == 'produtores')
          ? FloatingActionButton(
              key: addButtonKey,
              onPressed: widget.floatingActionButton?.onPressed,
              child: widget.floatingActionButton?.child,
            )
          : null,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }
}