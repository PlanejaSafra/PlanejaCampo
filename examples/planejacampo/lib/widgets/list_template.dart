import 'package:flutter/material.dart';
import 'package:planejacampo/route_observer.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ListTemplate extends StatefulWidget {
  final String title;
  final List<Widget> items;
  final VoidCallback? onAddPressed;
  final VoidCallback? onRefresh;
  final String moduleName;
  final Object returnObject;
  final Widget? bottomNavigationBar;
  final VoidCallback? onHelpPressed;
  final bool showDeleteButton;
  final VoidCallback? onDeletePressed;
  final bool showTutorial;
  final String nomeTutorial;
  final String nomeTutorialPlural;
  final Future<bool> Function()? onWillPop;
  final Map<String, Map<String, dynamic>> customTutorialSteps;

  const ListTemplate({
    Key? key,
    required this.title,
    required this.items,
    required this.moduleName,
    required this.returnObject,
    this.onAddPressed,
    this.onRefresh,
    this.bottomNavigationBar,
    this.onHelpPressed,
    this.showDeleteButton = false,
    this.onDeletePressed,
    this.showTutorial = false,
    this.nomeTutorial = '',
    this.nomeTutorialPlural = '',
    this.customTutorialSteps = const {},
    this.onWillPop,
  }) : super(key: key);

  @override
  _ListTemplateState createState() => _ListTemplateState();

  static Widget getListItem({
    required BuildContext context,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    IconData? trailingIcon,
    Color? trailingIconColor,
    VoidCallback? onTrailingIconTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(
          title,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            : null,
        trailing: trailingIcon != null
            ? IconButton(
                icon: Icon(trailingIcon),
                color: trailingIconColor,
                onPressed: onTrailingIconTap,
                style: Theme.of(context).iconButtonTheme.style,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _ListTemplateState extends State<ListTemplate>
    with RouteAware, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey bodyKey = GlobalKey();
  final GlobalKey addButtonKey = GlobalKey();
  final GlobalKey backButtonKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey cardKey = GlobalKey();
  final GlobalKey listViewKey = GlobalKey();

  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  late ScrollController _scrollController;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;
  bool canEdit = false;
  bool canView = false;
  bool canDelete = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didPopNext() {
    widget.onRefresh?.call();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    canDelete = appStateManager.canDelete(widget.moduleName);
    canEdit = appStateManager.canEdit(widget.moduleName);
    canView = appStateManager.canView(widget.moduleName);
    //print('widget.moduleName: ${widget.moduleName}, canEdit: $canEdit, canView: $canView, canDelete: $canDelete');
    //print('listTemplate widget.showTutorial: ${widget.showTutorial}');

    // Verifica se o usuário não pode visualizar (canView é false)
    if (!canView && widget.moduleName != 'produtores') {
      // Exibe uma mensagem de erro e sai da tela
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você não tem acesso a esta funcionalidade.'),
          ),
        );
        Navigator.of(context).pop();  // Sai da tela
      });
      return;  // Impede a execução do restante do initState
    }
    
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
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    tutorialCoachMark?.finish();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isTutorialRunning) {
      _isRecreatingScrappedTutorial = true;
      tutorialCoachMark?.finish();
      // Adicione um pequeno atraso antes de recriar o tutorial
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Se o controller não estiver anexado, tente usar o PrimaryScrollController
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          PrimaryScrollController.of(context)?.animateTo(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  void _scrollToAndFocus(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleTargetClick(TargetFocus target) {
    if (widget.customTutorialSteps.isNotEmpty) {
      if (target.identify.startsWith("custom")) {
        final entries = widget.customTutorialSteps.entries.toList();

        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];

          if (entry.key == target.identify) {
            if (i + 1 < entries.length) {
              final nextEntry = entries[i + 1];
              final nextKey = nextEntry.value['key'] as GlobalKey;
              _scrollToAndFocus(nextKey);
            } else {
            }
            break;
          }
        }

        //_scrollToAndFocus(firstKey);
      }
    }
  }

  void _startTutorial() {
    if (_isTutorialRunning && !_isRecreatingScrappedTutorial) {
      return;
    }
    _isTutorialRunning = true;
    _isRecreatingScrappedTutorial = false;

    _scrollToTop();

    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: AppThemes.tutorialColorShadow,
      skipWidget: ElevatedButton(
        onPressed: () {
          tutorialCoachMark?.skip();
        },
        child: Text(S.of(context).skip, style: AppThemes.tutorialTextStyleSkip),
      ),
      textSkip: S.of(context).skip,
      textStyleSkip: AppThemes.tutorialTextStyleSkip,
      alignSkip: Alignment.bottomCenter,
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        _isTutorialRunning = false;
      },
      onSkip: () {
        _isTutorialRunning = false;
        return true;
      },
      onClickTarget: (target) {
        _handleTargetClick(target);
      },
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    final theme = Theme.of(context);
    targets.clear();

    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "backButton",
        keyTarget: backButtonKey,
        description: S.of(context).click_to_go_back,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "moreOptions",
        keyTarget: moreOptionsKey,
        description: S.of(context).click_to_see_more_options,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    // Customizado - Mantido como está
    final RenderBox renderBox = listViewKey.currentContext?.findRenderObject() as RenderBox;
    final Size size = renderBox.size; // Tamanho do widget (width e height)
    final Offset offset = renderBox.localToGlobal(Offset.zero); // Posição do widget na tela
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "listViewKey",
        //keyTarget: listViewKey,
        description: S.of(context).list_of_existing(widget.nomeTutorialPlural),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
        targetPosition: TargetPosition(
          Size(
            size.width, // Largura do foco
            size.height *
                0.6, // Altura do foco (ajuste aqui para diminuir o quadro)
          ),
          Offset(
            offset.dx, // Margem esquerda
            offset
                .dy, // Altura a partir do topo (ajuste para posicionar o foco)
          ),
        ),
      ),
    );

    widget.customTutorialSteps.forEach((key, value) {
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: key,
          description: value['message'] as String,
          keyTarget: value['key'] as GlobalKey,
          shape: ObjectTemplate.getShapeFromString(value['shape'] as String?),
          align: value.containsKey('align')
              ? ObjectTemplate.getAlignFromString(value['align'] as String?)
              : ContentAlign.bottom,
        ),
      );
    });

    if (widget.onAddPressed != null && canEdit) {
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "addButton",
          keyTarget: addButtonKey,
          description: S.of(context).click_to_add(widget.nomeTutorial),
          shape: ShapeLightFocus.Circle,
          align: ContentAlign.top,
        ),
      );
    }

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

  _exitButton() {
    /*
    if (widget.returnObject is bool) {
      if (widget.returnObject == true) {
        Navigator.of(context).pop(true);
      }
    } else if (widget.returnObject != null) {
      Navigator.of(context).pop(widget.returnObject);
    } else {
      Navigator.of(context).pop();
    }
    print('widget.returnValue: ${widget.returnObject}');
    return false; // Evita o comportamento padrão do pop
    */
    Navigator.of(context).pop(widget.returnObject);
  }


  @override
  Widget build(BuildContext context) {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final String produtorId = appStateManager.activeProdutor?.id ?? '';
    final FormatacaoUtil formatacaoUtil = appStateManager.formatacao;
    final ThemeData theme = Theme.of(context);
    List<Widget> appBarActions = [];

    appBarActions.add(
      PopupMenuButton<String>(
        key: moreOptionsKey,
        icon: Icon(Icons.more_vert),
        onSelected: (String result) {
          //print('result: ${result}, S.of(context).help: ${S.of(context).help}');
          if (result == S.of(context).help) {
            if (widget.onHelpPressed != null) {
              widget.onHelpPressed!();
            }
            _startTutorial(); // Adicione esta linha
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: S.of(context).help,
            child: Text(
              S.of(context).help,
              style: Theme.of(context).popupMenuTheme.textStyle,
            ),
          ),
        ],
        offset: Offset(0, 56), // Ajuste conforme necessário
      ),
    );
    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          return await widget.onWillPop!();
        } else {
          _exitButton();
          return true;
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            key: backButtonKey,
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
              if (widget.onWillPop != null) {
                bool shouldPop = await widget.onWillPop!();
                if (shouldPop) {
                  _exitButton();
                }
              } else {
                _exitButton();
              }
            },
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
          key: bodyKey,
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            key: listViewKey,
            padding: const EdgeInsets.all(8.0),
            children: widget.items,
          ),
        ),
        floatingActionButton: widget.onAddPressed != null &&
                (canEdit || (widget.moduleName == 'produtores' && appStateManager.canCreateMoreProdutores))
            ? FloatingActionButton(
                key: addButtonKey,
                onPressed: widget.onAddPressed,
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}
