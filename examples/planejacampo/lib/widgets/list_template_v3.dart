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
  final PreferredSizeWidget? appBarBottom; // Novo parâmetro para TabBar
  final BoxDecoration Function(T item)? cardDecoration; // Parâmetro para personalizar cards



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
    this.appBarBottom, // Adicionado no constructor
    this.cardDecoration, // Adicionado no constructor
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
  final GlobalKey _listViewContentKey = GlobalKey(); // Chave para o SizedBox
  bool _isScrollable = false;
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
  Object? _returnObject;

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
    _returnObject = null;
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);

    _checkPermissions();

    if (widget.showTutorial) { /* ... */ }

    // Chama _checkScrollable após o build inicial:
    WidgetsBinding.instance.addPostFrameCallback(_checkScrollable);

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

  void _checkScrollable(_) {
    final RenderBox? listViewBox = _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewBox != null) {
      final listHeight = listViewBox.size.height;
      final viewportHeight = context.size!.height - kToolbarHeight - MediaQuery.of(context).padding.vertical - 16*2; // Ajuste para padding

      setState(() {
        _isScrollable = listHeight > viewportHeight;

        if (_isScrollable) { // Define scrollProgress inicial
          _scrollProgress.value = _scrollController.offset / _scrollController.position.maxScrollExtent;
        }
      });

      print('Altura da lista: $listHeight, Altura da viewport: $viewportHeight, Rolável: $_isScrollable'); // Debug
    } else {
      // Agenda para próximo frame se ainda não estiver renderizado
      WidgetsBinding.instance.addPostFrameCallback(_checkScrollable);
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

          // Remover o setState e atualizar apenas o ValueNotifier
          _isInitialized = true;
          if (hasScrollableContent) {
            _scrollProgress.value = _scrollController.offset / _scrollController.position.maxScrollExtent;
          }
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
        // Remover setState e atualizar apenas o ValueNotifier
        _scrollProgress.value = (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0);
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
        _returnObject = result; // Now _returnObject can hold any type

        if (result is bool && result) {
          // If a new item was added (returns true)
          widget.onRefresh?.call();
        } else if (result is T) {
          // If an item was updated (returns the item)
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
    final ThemeData theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          final shouldPop = await widget.onWillPop!();
          if (!shouldPop) return false;
        }
        Navigator.of(context).pop(_returnObject);  // Passa o objeto antes de permitir pop
        return false;  // Impede pop automático pois já fizemos manualmente
      },

      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            key: _backButtonKey,
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_returnObject),
          ),
          title: Text(widget.title, style: theme.textTheme.displayLarge),
          centerTitle: true,
          actions: [
            PopupMenuButton<String>(
              key: _moreOptionsKey,
              icon: Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == S.of(context).help) {
                  _startTutorial();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: S.of(context).help,
                  child: Text(
                    S.of(context).help,
                    style: theme.popupMenuTheme.textStyle,
                  ),
                ),
              ],
            ),
          ],
          bottom: widget.appBarBottom, // Aqui usamos o novo parâmetro
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: FutureBuilder<List<T>>(
                future: widget.future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(widget.errorText ?? S.of(context).error_loading),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(widget.notFoundText ?? S.of(context).not_found),
                    );
                  }

                  //WidgetsBinding.instance.addPostFrameCallback(_checkScrollable);

                  // Adiciona esta linha para chamar _onDataLoaded quando os dados forem carregados
                  WidgetsBinding.instance.addPostFrameCallback((_) => _onDataLoaded());

                  return ListView.builder(
                    key: _listViewKey,
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final T item = snapshot.data![index];

                      // Verifica se temos uma decoração personalizada
                      final hasCustomDecoration = widget.cardDecoration != null;

                      // Cria o widget do Card que será usado em ambos os casos
                      final cardWidget = Card(
                        // Se estiver dentro de um Container, remove a margem para evitar duplicação
                        margin: hasCustomDecoration ? EdgeInsets.zero : EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        // Se tiver decoração personalizada, reduz a elevação
                        elevation: hasCustomDecoration ? 0 : null,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ExpansionTile(
                            leading: widget.itemLeadingIcon != null
                                ? Icon(
                              widget.itemLeadingIcon,
                              color: theme.colorScheme.primary,
                              size: 24,
                            )
                                : null,
                            title: Text(
                              widget.itemTitleBuilder(item),
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: DefaultTextStyle(
                              style: theme.textTheme.bodyMedium!,
                              child: widget.itemSubtitleBuilder(item),
                            ),
                            children: widget.itemExpandedContentWidgets != null
                                ? [
                              Container(
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: theme.dividerColor,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: widget.itemExpandedContentWidgets!(item),
                                ),
                              ),
                            ]
                                : [],
                            trailing: _buildTrailingMenu(item, index),
                          ),
                        ),
                      );

                      // Quando temos decoração personalizada, encapsulamos em um Container
                      if (hasCustomDecoration) {
                        return Container(
                          key: index == 0 ? _firstItemCardKey : null,
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: widget.cardDecoration!(item),
                          child: cardWidget,
                        );
                      }

                      // Caso contrário, retorna o Card diretamente
                      if (index == 0) {
                        return KeyedSubtree(
                          key: _firstItemCardKey,
                          child: cardWidget,
                        );
                      }

                      return cardWidget;
                    },
                  );
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
                    opacity: _hasScrollableContent() ? 0.8 : 0,
                    duration: Duration(milliseconds: 200),
                    child: _buildScrollbar(progress, theme),
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
                        progress < 0.98
                        ? 1.0
                        : 0.0,
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
        floatingActionButton: (_canEdit || (widget.moduleName == 'produtores' &&
            appStateManager.canCreateMoreProdutores))
            ? FloatingActionButton(
          key: _addButtonKey,
          onPressed: _navigateToAdd,
          child: Icon(Icons.add),
        )
            : null,
      ),
    );
  }

  Widget _buildTrailingMenu(T item, int index) {
    final theme = Theme.of(context);

    if (widget.isSelectMode) {
      return IconButton(
        key: index == 0 ? _firstItemMoreOptionsKey : null,
        icon: Icon(
          Icons.arrow_forward_ios,
          color: theme.iconTheme.color,
        ),
        onPressed: () {
          if (widget.isSetMode) {
            widget.onSetMode?.call(item);
          }
          Navigator.of(context).pop(item);
        },
      );
    }

    return PopupMenuButton<String>(
      key: index == 0 ? _firstItemMoreOptionsKey : null,
      icon: Icon(
        Icons.more_vert,
        color: theme.iconTheme.color,
      ),
      onSelected: (value) async {
        switch (value) {
          case 'view':
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => widget.viewScreenBuilder!(item)),
            );
            _handleNavigationResult(result);
            break;
          case 'edit':
            if (_canEdit) {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => widget.formScreenBuilder!(item)),
              );
              _handleNavigationResult(result);
            }
            break;
          case 'delete':
            if (_canDelete) {
              await DialogScreen.confirmDelete(
                context,
                serviceName: widget.serviceName,
                itemIdValue: (item as dynamic).id,
                itemName: widget.nomeTutorial,
                onSuccessDialog: () {
                  widget.onRefresh?.call();
                },
              );
            }
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: index == 0 ? _firstItemViewKey : null,
          value: 'view',
          child: Text(
            S.of(context).details,
            style: theme.popupMenuTheme.textStyle,
          ),
        ),
        if (_canEdit)
          PopupMenuItem(
            key: index == 0 ? _firstItemEditKey : null,
            value: 'edit',
            child: Text(
              S.of(context).edit,
              style: theme.popupMenuTheme.textStyle,
            ),
          ),
        if (_canDelete)
          PopupMenuItem(
            key: index == 0 ? _firstItemDeleteKey : null,
            value: 'delete',
            child: Text(
              S.of(context).delete,
              style: theme.popupMenuTheme.textStyle,
            ),
          ),
      ],
    );
  }

  Widget _buildScrollbar(double progress, ThemeData theme) {
    return GestureDetector(
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
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  width: 4,
                  constraints: BoxConstraints(
                    minWidth: 4,
                    maxWidth: 4,
                    minHeight: 0, // Garante um valor mínimo válido
                    maxHeight: double.infinity, // Permite que o container cresça conforme necessário
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
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
    );
  }
}
