import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:planejacampo/route_observer.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ListTemplate<T> extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Future<List<T>> future;
  final String Function(T item) itemTitleBuilder;
  final Widget Function(T item) itemSubtitleBuilder;
  final void Function(T item) onTap;
  final void Function(T item)? onEdit;
  final void Function(T item)? onDelete;
  final bool isSelectMode;
  final bool isSetMode;
  final void Function(T item)? onSetMode;
  final IconData? itemLeadingIcon;
  final String? loadingText;
  final String? errorText;
  final String? notFoundText;
  final List<Widget> Function(T item)? itemExpandedContentWidgets;

  // Parâmetros adicionais já existentes
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
    this.subtitle,
    required this.icon,
    required this.future,
    required this.itemTitleBuilder,
    required this.itemSubtitleBuilder,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelectMode = false,
    this.isSetMode = false,
    this.onSetMode,
    this.itemLeadingIcon,
    this.loadingText,
    this.errorText,
    this.notFoundText,
    this.itemExpandedContentWidgets,
    this.onAddPressed,
    this.onRefresh,
    required this.moduleName,
    required this.returnObject,
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
  _ListTemplateState<T> createState() => _ListTemplateState<T>();

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

class _ListTemplateState<T> extends State<ListTemplate<T>> with RouteAware, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _bodyKey = GlobalKey();
  final GlobalKey _addButtonKey = GlobalKey();
  final GlobalKey _backButtonKey = GlobalKey();
  final GlobalKey _moreOptionsKey = GlobalKey();
  final GlobalKey _cardKey = GlobalKey();
  final GlobalKey _listViewKey = GlobalKey(); // Chave para o ListView
  final GlobalKey _firstItemCardKey = GlobalKey(); // Chave para o primeiro item do ListView
  final GlobalKey<PopupMenuButtonState<String>> _firstItemMoreOptionsKey = GlobalKey<PopupMenuButtonState<String>>();
  final GlobalKey _firstItemViewKey = GlobalKey();
  final GlobalKey _firstItemEditKey = GlobalKey();
  final GlobalKey _firstItemDeleteKey = GlobalKey();
  final ValueNotifier<bool> _showGradient = ValueNotifier(true);


  List<TargetFocus> _targets = [];
  TutorialCoachMark? _tutorialCoachMark;
  late ScrollController _scrollController;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;
  bool _canEdit = false;
  bool _canView = false;
  bool _canDelete = false;
  bool _isMoreOptionsMenuOpen = false;

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
    _scrollController = ScrollController()..addListener(_scrollListener);
    //_scrollController = ScrollController();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canDelete = appStateManager.canDelete(widget.moduleName);
    _canEdit = appStateManager.canEdit(widget.moduleName);
    _canView = appStateManager.canView(widget.moduleName);
    //print('widget.moduleName: ${widget.moduleName}, canEdit: $_canEdit, canView: $_canView, canDelete: $_canDelete');

    // Verifica se o usuário não pode visualizar (canView é false)
    if (!_canView && widget.moduleName != 'produtores') {
      // Exibe uma mensagem de erro e sai da tela
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você não tem acesso a esta funcionalidade.'),
          ),
        );
        Navigator.of(context).pop(); // Sai da tela
      });
      return; // Impede a execução do restante do initState
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 300));
      if (widget.showTutorial) {
        _startTutorial();
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final isAtBottom = _scrollController.position.pixels >= 
          _scrollController.position.maxScrollExtent - 50; // buffer de 50px
      _showGradient.value = !isAtBottom;
    }
  }

  @override
  void dispose() {
    _showGradient.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _tutorialCoachMark?.finish();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isTutorialRunning) {
      _isRecreatingScrappedTutorial = true;
      _tutorialCoachMark?.finish();
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
    //print("target.identify: ${target.identify}");
    //print("_canView: $_canView, _canEdit: $_canEdit, _canDelete: $_canDelete");
    if (target.identify == "firstItemMoreOptionsKey") {
      setState(() {
        _isMoreOptionsMenuOpen = true;
      });
      // Open the PopupMenuButton programmatically
      _firstItemMoreOptionsKey.currentState?.showButtonMenu();
      // Wait a moment for the menu to open before continuing the tutorial
    } else if (widget.customTutorialSteps.isNotEmpty) {
      if (target.identify.startsWith("custom")) {
        final entries = widget.customTutorialSteps.entries.toList();

        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];

          if (entry.key == target.identify) {
            if (i + 1 < entries.length) {
              final nextEntry = entries[i + 1];
              final nextKey = nextEntry.value['key'] as GlobalKey;
              _scrollToAndFocus(nextKey);
            } else {}
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

    _waitForKeys().then((_) {
        _tutorialCoachMark = TutorialCoachMark(
          targets: _createTargets(),
          colorShadow: AppThemes.tutorialColorShadow,
          skipWidget: ElevatedButton(
            onPressed: () {
              _tutorialCoachMark?.skip();
            },
            child: Text(S
                .of(context)
                .skip, style: AppThemes.tutorialTextStyleSkip),
          ),
          textSkip: S
              .of(context)
              .skip,
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
        )
          ..show(context: context);

    });
  }

  Future<void> _waitForKeys() async {
    // List of keys to wait for
    final keysToWaitFor = [
      _backButtonKey,
      _moreOptionsKey,
      _listViewKey,
      _firstItemMoreOptionsKey,
    ];

    bool allKeysReady() {
      return keysToWaitFor.every((key) => key.currentContext != null);
    }

    // Wait until all keys have a non-null currentContext
    while (!allKeysReady()) {
      await Future.delayed(Duration(milliseconds: 100));
    }
  }




  List<TargetFocus> _createTargets() {
    final theme = Theme.of(context);
    _targets.clear();

    _targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "backButton",
        keyTarget: _backButtonKey,
        description: S.of(context).click_to_go_back,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    _targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "moreOptions",
        keyTarget: _moreOptionsKey,
        description: S.of(context).click_to_see_more_options,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    // Customizado - Mantido como está
    if (_listViewKey.currentContext != null) { // Adiciona verificação para evitar Null
      final RenderBox renderBox = _listViewKey.currentContext!.findRenderObject() as RenderBox;
      final Size size = renderBox.size; // Tamanho do widget (width e height)
      final Offset offset = renderBox.localToGlobal(Offset.zero); // Posição do widget na tela
      _targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "listViewKey",
          description: S.of(context).list_of_existing(widget.nomeTutorialPlural),
          shape: ShapeLightFocus.RRect,
          align: ContentAlign.bottom,
          targetPosition: TargetPosition(
            Size(
              size.width, // Largura do foco
              size.height * 0.6, // Altura do foco (ajuste aqui para diminuir o quadro)
            ),
            Offset(
              offset.dx, // Margem esquerda
              offset.dy, // Altura a partir do topo (ajuste para posicionar o foco)
            ),
          ),
        ),
      );
    }

    widget.customTutorialSteps.forEach((key, value) {
      _targets.add(
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

    _targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "firstItemMoreOptionsKey",
        keyTarget: _firstItemMoreOptionsKey,
        description: S.of(context).click_to_see_more_options,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.top,
      ),
    );
    if (_canView || _canEdit || _canDelete) {

      if (_canView) {
        _targets.add(
          ObjectTemplate.getTutorialTarget(
            identify: "firstItemViewKey",
            keyTarget: _firstItemViewKey,
            description: S.of(context).click_to_view_details,
            shape: ShapeLightFocus.RRect,
            focusPadding: 1.5,
            align: ContentAlign.bottom,
          ),
        );
      }
      if (_canEdit) {
        _targets.add(
          ObjectTemplate.getTutorialTarget(
            identify: "firstItemEditKey",
            keyTarget: _firstItemEditKey,
            description: S.of(context).click_to_edit_simple,
            shape: ShapeLightFocus.RRect,
            align: ContentAlign.top,
          ),
        );
      }
      if (_canDelete) {
        _targets.add(
          ObjectTemplate.getTutorialTarget(
            identify: "firstItemDeleteKey",
            keyTarget: _firstItemDeleteKey,
            description: S.of(context).click_to_delete,
            shape: ShapeLightFocus.RRect,
            align: ContentAlign.top,
          ),
        );
      }
    }

    if (widget.onAddPressed != null && _canEdit) {
      _targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "addButton",
          keyTarget: _addButtonKey,
          description: S.of(context).click_to_add(widget.nomeTutorial),
          shape: ShapeLightFocus.Circle,
          align: ContentAlign.top,
        ),
      );
    }

    return _targets;
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
        key: _moreOptionsKey,
        icon: Icon(Icons.more_vert),
        onSelected: (String result) {
          if (result == S.of(context).help) {
            if (widget.onHelpPressed != null) {
              widget.onHelpPressed!();
            }
            _startTutorial(); // Inicia o tutorial
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
            key: _backButtonKey,
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
        body: Stack(
          children: [
            Padding(
              key: _bodyKey,
              padding: const EdgeInsets.all(16.0),
              child: ObjectTemplate.buildCardSectionWithFutureCustom<T>(
                subTitle: widget.subtitle,
                icon: widget.icon,
                future: widget.future,
                itemTitle: widget.itemTitleBuilder,
                itemSubtitle: widget.itemSubtitleBuilder,
                onTap: widget.onTap,
                onEdit: widget.onEdit,
                onDelete: widget.onDelete,
                isSelectMode: widget.isSelectMode,
                isSetMode: widget.isSetMode,
                onSetMode: widget.onSetMode,
                itemLeadingIcon: widget.itemLeadingIcon,
                loadingText: widget.loadingText,
                errorText: widget.errorText,
                notFoundText: widget.notFoundText,
                itemExpandedContentWidgets: widget.itemExpandedContentWidgets,
                scrollController: _scrollController,
                listViewKey: _listViewKey,
                firstItemCardKey: _firstItemCardKey,
                firstItemMoreOptionsKey: _firstItemMoreOptionsKey,
                firstItemViewKey: _firstItemViewKey,
                firstItemEditKey: _firstItemEditKey,
                firstItemDeleteKey: _firstItemDeleteKey,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 40,
              child: ValueListenableBuilder<bool>(
                valueListenable: _showGradient,
                builder: (context, showGradient, child) {
                  return AnimatedOpacity(
                    opacity: showGradient ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.scaffoldBackgroundColor.withOpacity(0.0),
                            theme.scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.onAddPressed != null && 
                (_canEdit || (widget.moduleName == 'produtores' && 
                Provider.of<AppStateManager>(context).canCreateMoreProdutores)))
              const Positioned(
                right: 0,
                bottom: 0,
                width: 88,
                height: 88,
                child: SizedBox(),
              ),
          ],
        ),
        floatingActionButton: widget.onAddPressed != null &&
            (_canEdit || (widget.moduleName == 'produtores' && appStateManager.canCreateMoreProdutores))
            ? FloatingActionButton(
          key: _addButtonKey,
          onPressed: widget.onAddPressed,
          child: const Icon(Icons.add),
        )
            : null,
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}
