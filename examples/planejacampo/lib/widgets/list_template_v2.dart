import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/route_observer.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/l10n/l10n.dart';

class ListTemplate<T> extends StatefulWidget {
  final IconData icon;
  final Future<List<T>> future;
  final String Function(T item) itemTitleBuilder;
  final Widget Function(T item) itemSubtitleBuilder;
  final String moduleName;
  final GenericService<T> serviceName;
  final String title;

  final Widget? bottomNavigationBar;
  final bool Function(T item)? canDelete;
  final bool Function(T item)? canEdit;
  final Map<String, Map<String, dynamic>> customTutorialSteps;
  final String? errorText;
  final List<Widget> Function(T item)? itemExpandedContentWidgets;
  final Widget Function(T?)? formScreenBuilder;
  final bool isSelectMode;
  final bool isSetMode;
  final IconData? itemLeadingIcon;
  final String? loadingText;
  final String nomeTutorial;
  final String nomeTutorialPlural;
  final String? notFoundText;
  final VoidCallback? onAddPressed;
  final void Function(T item)? onDelete;
  final VoidCallback? onDeletePressed;
  final void Function(T item)? onEdit;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onRefresh;
  final void Function(T item)? onSetMode;
  final void Function(T item)? onTap;
  final Future<bool> Function()? onWillPop;
  final bool showDeleteButton;
  final bool showTutorial;
  final String? subtitle;
  final Widget Function(T?)? viewScreenBuilder;

  

  const ListTemplate({
    Key? key,
    required this.icon,
    required this.future,
    required this.itemSubtitleBuilder,
    required this.itemTitleBuilder,
    required this.moduleName,
    required this.serviceName,
    required this.title,
    this.bottomNavigationBar,
    this.canDelete,
    this.canEdit,
    this.customTutorialSteps = const {},
    this.errorText,
    this.formScreenBuilder,
    this.isSelectMode = false,
    this.isSetMode = false,
    this.itemExpandedContentWidgets,
    this.itemLeadingIcon,
    this.loadingText,
    this.nomeTutorial = '',
    this.nomeTutorialPlural = '',
    this.notFoundText,
    this.onAddPressed,
    this.onDelete,
    this.onDeletePressed,
    this.onEdit,
    this.onHelpPressed,
    this.onRefresh,
    this.onSetMode,
    this.onTap,
    this.onWillPop,
    this.showDeleteButton = false,
    this.showTutorial = false,
    this.subtitle,
    this.viewScreenBuilder,
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
  //final ValueNotifier<bool> _showGradient = ValueNotifier(true);
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);


  List<TargetFocus> _targets = [];
  TutorialCoachMark? _tutorialCoachMark;
  late ScrollController _scrollController;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;
  bool _canEdit = false;
  bool _canView = false;
  bool _canDelete = false;
  bool _isMoreOptionsMenuOpen = false;
  bool _isInitialized = false;
  GlobalKey _contentKey = GlobalKey();
  Object _returnObject = false;

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
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);

    _checkPermissions();

    if (widget.showTutorial) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _checkPermissions() {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canView = appStateManager.canView(widget.moduleName);
    _canEdit = appStateManager.canEdit(widget.moduleName);
    _canDelete = appStateManager.canDelete(widget.moduleName);

    if (!_canView && widget.moduleName != 'produtores') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Você não tem acesso a esta funcionalidade.')),
        );
        Navigator.of(context).pop();
      });
      return;
    }
  }

  // Adicione este método
  void _onDataLoaded() {
    if (!mounted) return;
    
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;

      try {
        if (_scrollController.hasClients) {
          final viewportHeight = MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + 
              MediaQuery.of(context).padding.bottom + 
              kToolbarHeight);
          
          final contentHeight = _scrollController.position.viewportDimension + 
                              _scrollController.position.maxScrollExtent;
          
          final hasScrollableContent = contentHeight > viewportHeight;
          
          setState(() {
            _isInitialized = true;
            if (hasScrollableContent) {
              _scrollProgress.value = _scrollController.offset / _scrollController.position.maxScrollExtent;
            }
          });
          
          //print('Lista: Conteúdo carregado - altura = $contentHeight, viewport = $viewportHeight, scrollable = $hasScrollableContent');
        }
      } catch (e) {
        print('Erro ao verificar conteúdo após carregamento: $e');
      }
    });
  }

  void _checkContentSize() {
    if (!mounted) return;

    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;

      try {
        final RenderBox? box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final contentHeight = box.size.height;
          final viewportHeight = MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + 
              MediaQuery.of(context).padding.bottom + 
              kToolbarHeight);

          final hasScrollableContent = contentHeight > viewportHeight;
          
          if (hasScrollableContent && _scrollController.hasClients) {
            setState(() {
              _isInitialized = true;
              _scrollProgress.value = _scrollController.offset / _scrollController.position.maxScrollExtent;
            });
            //print('Lista: Conteúdo scrollável detectado: altura = $contentHeight, viewport = $viewportHeight');
          } else if (!_isInitialized) {
            _checkContentSize();
          }
        }
      } catch (e) {
        print('Erro ao verificar tamanho da lista: $e');
        if (!_isInitialized) {
          _checkContentSize();
        }
      }
    });
  }

  void _scrollListener() {
    if (!mounted || !_scrollController.hasClients) return;
    
    try {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent > 0) {
        setState(() {
          _scrollProgress.value = (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0);
        });
        //print('Lista: Progresso do scroll atualizado para: ${_scrollProgress.value}');
      }
    } catch (e) {
      print('Erro no listener de scroll da lista: $e');
    }
  }

  @override
  void dispose() {
    _scrollProgress.dispose();
    _scrollController.removeListener(_scrollListener);
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

  void _navigateToViewScreen(T item) async {
    if (widget.onTap != null) {
      widget.onTap!(item);
      return;
    }

    if (widget.viewScreenBuilder == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => widget.viewScreenBuilder!(item)),
    );
    _handleNavigationResult(result);
  }

  void _navigateToFormScreen(T? item) {
    if (widget.onEdit != null && item != null) {
      widget.onEdit!(item);
      return;
    }

    if (widget.formScreenBuilder == null) return;

    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          widget.formScreenBuilder!(item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    )
    .then(_handleNavigationResult);
  }

    void _handleNavigationResult(dynamic result) {
    if (result != null && result != '') {
      setState(() {
        _returnObject = result;
        if (result is! bool || result != false) {
          widget.onRefresh?.call();
        }
      });
    }
  }

  void _exitButton() {
    Navigator.of(context).pop(_returnObject);
  }

  void _navigateToAdd() async {
  if (widget.formScreenBuilder == null) return;

  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => widget.formScreenBuilder!(null)), // Passa null porque é um novo item
  );
  
  if (result != null && result != '') {
    setState(() {
      _returnObject = result;
      if (result is! bool || result != false) {
        widget.onRefresh?.call();
      }
    });
  }
}
  
  Future<void> _confirmDelete(T item) async {
    if (widget.onDelete != null) {
      widget.onDelete!(item);
      return;
    }

    await DialogScreen.confirmDelete(
      context,
      serviceName: widget.serviceName,
      itemIdValue: (item as dynamic).id,
      itemName: widget.nomeTutorial,
      onSuccessDialog: () {
        //Navigator.of(context).pop(true);
        widget.onRefresh?.call();
      },
    );
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
        description: widget.isSelectMode ? S.of(context).click_to_select_generic(widget.nomeTutorial) : S.of(context).click_to_see_more_options,
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

    if (_canEdit) {
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

  // Modifique também o _hasScrollableContent para ser mais preciso
  bool _hasScrollableContent() {
    if (!_scrollController.hasClients) return false;
    try {
      final viewportHeight = MediaQuery.of(context).size.height -
          (MediaQuery.of(context).padding.top + 
          MediaQuery.of(context).padding.bottom + 
          kToolbarHeight);
      
      final contentHeight = _scrollController.position.viewportDimension + 
                          _scrollController.position.maxScrollExtent;
      
      return contentHeight > viewportHeight && contentHeight > 0;
    } catch (e) {
      print('Erro ao verificar conteúdo scrollável: $e');
      return false;
    }
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
            _startTutorial();
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
        offset: Offset(0, 56),
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
              child: FutureBuilder<List<T>>(
                future: widget.future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        widget.errorText ?? 'Erro ao carregar os dados',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    // Quando os dados forem carregados, chame _onDataLoaded
                    WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded());
                    
                    if (snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          widget.notFoundText ?? 'Nenhum item encontrado',
                          style: theme.textTheme.bodyLarge,
                        ),
                      );
                    }

                    return ObjectTemplate.buildCardSectionWithFutureCustom<T>(
                      //key: _contentKey,
                      subTitle: widget.subtitle,
                      icon: widget.icon,
                      future: widget.future,
                      itemTitle: widget.itemTitleBuilder,
                      itemSubtitle: widget.itemSubtitleBuilder,
                      onTap: widget.onTap ?? _navigateToViewScreen,
                      canEdit: widget.canEdit ?? ((_) => _canEdit),
                      canDelete: widget.canDelete ?? ((_) => _canDelete),
                      onEdit: widget.onEdit ?? _navigateToFormScreen,
                      onDelete: widget.onDelete ?? _confirmDelete,
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
                    );
                  }

                  return Center(child: CircularProgressIndicator());
                },
              ),
            ),
            // Barra de progresso lateral
            Positioned(
              right: 8,
              top: 16,
              bottom: 16,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) {
                  return AnimatedOpacity(
                    opacity: _scrollController.hasClients && 
                            _scrollController.position.maxScrollExtent > 0 ? 0.8 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: GestureDetector(
                      onVerticalDragUpdate: (details) {
                        if (_scrollController.hasClients) {
                          final RenderBox box = context.findRenderObject() as RenderBox;
                          final double height = box.size.height;
                          final double position = details.localPosition.dy.clamp(0, height);
                          final double percent = position / height;
                          _scrollController.jumpTo(
                            _scrollController.position.maxScrollExtent * percent.clamp(0.0, 1.0),
                          );
                        }
                      },
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                Container(
                                  width: 4,
                                  height: constraints.maxHeight * progress,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.secondary,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Positioned(
                                  top: (constraints.maxHeight * progress) - 8,
                                  left: -4,
                                  child: AnimatedOpacity(
                                    opacity: _scrollController.hasClients && 
                                            _scrollController.position.isScrollingNotifier.value ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 200),
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.colorScheme.primary.withOpacity(0.3),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Indicador de mais conteúdo
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ValueListenableBuilder<double>(
                valueListenable: _scrollProgress,
                builder: (context, progress, _) {
                  return AnimatedOpacity(
                    opacity: _scrollController.hasClients &&
                            _scrollController.position.maxScrollExtent > 0 &&
                            progress < 0.98 ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 24,
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
                        Container(
                          height: 24,
                          color: theme.scaffoldBackgroundColor,
                          child: Center(
                            child: TweenAnimationBuilder(
                              tween: Tween<double>(begin: 0.8, end: 1.0),
                              duration: Duration(milliseconds: 1000),
                              builder: (context, double value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: Container(
                                    height: 4,
                                    width: 40,
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Espaço para FAB
            if (widget.onAddPressed != null && 
                (_canEdit || (widget.moduleName == 'produtores' && 
                appStateManager.canCreateMoreProdutores)))
              const Positioned(
                right: 0,
                bottom: 0,
                width: 88,
                height: 88,
                child: SizedBox(),
              ),
          ],
        ),
        floatingActionButton: (_canEdit || (widget.moduleName == 'produtores' && appStateManager.canCreateMoreProdutores))
            ? FloatingActionButton(
                key: _addButtonKey,
                onPressed: _navigateToAdd,
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }
}
