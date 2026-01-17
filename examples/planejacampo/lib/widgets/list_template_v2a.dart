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
  final List<dynamic> items;
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
  final bool isSelectMode;
  final bool isSetMode;
  final Function(dynamic)? onItemSelected;
  final Function(dynamic)? onViewItem;
  final Function(dynamic)? onEditItem;
  final Function(dynamic)? onDeleteItem;
  final Widget Function(BuildContext, dynamic, int)? itemBuilder;

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
    this.isSelectMode = false,
    this.isSetMode = false,
    this.onItemSelected,
    this.onViewItem,
    this.onEditItem,
    this.onDeleteItem,
    this.itemBuilder,
  }) : super(key: key);

  @override
  _ListTemplateState createState() => _ListTemplateState();

  static Widget buildListWithFuture<T>({
    required BuildContext context,
    required Future<List<T>> future,
    required String title,
    required String moduleName,
    required Object returnObject,
    VoidCallback? onAddPressed,
    VoidCallback? onRefresh,
    Widget? bottomNavigationBar,
    VoidCallback? onHelpPressed,
    bool showDeleteButton = false,
    VoidCallback? onDeletePressed,
    bool showTutorial = false,
    String nomeTutorial = '',
    String nomeTutorialPlural = '',
    Map<String, Map<String, dynamic>> customTutorialSteps = const {},
    Future<bool> Function()? onWillPop,
    bool isSelectMode = false,
    bool isSetMode = false,
    Function(T)? onItemSelected,
    Function(T)? onViewItem,
    Function(T)? onEditItem,
    Function(T)? onDeleteItem,
    Widget Function(BuildContext, T, int)? itemBuilder,
    String? loadingText,
    String? errorText,
    String? emptyText,
  }) {
    return FutureBuilder<List<T>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(errorText ?? S.of(context).error_loading));
        } else {
          final items = snapshot.data ?? [];
          return ListTemplate(
            title: title,
            items: items,
            moduleName: moduleName,
            returnObject: returnObject,
            onAddPressed: onAddPressed,
            onRefresh: onRefresh,
            bottomNavigationBar: bottomNavigationBar,
            onHelpPressed: onHelpPressed,
            showDeleteButton: showDeleteButton,
            onDeletePressed: onDeletePressed,
            showTutorial: showTutorial,
            nomeTutorial: nomeTutorial,
            nomeTutorialPlural: nomeTutorialPlural,
            customTutorialSteps: customTutorialSteps,
            onWillPop: onWillPop,
            isSelectMode: isSelectMode,
            isSetMode: isSetMode,
            onItemSelected: onItemSelected != null ? (item) => onItemSelected(item as T) : null,
            onViewItem: onViewItem != null ? (item) => onViewItem(item as T) : null,
            onEditItem: onEditItem != null ? (item) => onEditItem(item as T) : null,
            onDeleteItem: onDeleteItem != null ? (item) => onDeleteItem(item as T) : null,
            itemBuilder: itemBuilder != null ? (context, item, index) => itemBuilder(context, item as T, index) : null,
          );
        }
      },
    );
  }

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
// ... resto do código do ListTemplate ...
}

class _ListTemplateState extends State<ListTemplate> with RouteAware, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey bodyKey = GlobalKey();
  final GlobalKey addButtonKey = GlobalKey();
  final GlobalKey backButtonKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey listViewKey = GlobalKey();

  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  late ScrollController scrollController;
  bool isTutorialRunning = false;
  bool isRecreatingScrappedTutorial = false;
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
    scrollController = ScrollController();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    canDelete = appStateManager.canDelete(widget.moduleName);
    canEdit = appStateManager.canEdit(widget.moduleName);
    canView = appStateManager.canView(widget.moduleName);

    if (!canView && widget.moduleName != 'produtores') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Você não tem acesso a esta funcionalidade.'),
          ),
        );
        Navigator.of(context).pop();
      });
      return;
    }

    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 300));
      if (widget.showTutorial) {
        startTutorial();
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    tutorialCoachMark?.finish();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (isTutorialRunning) {
      isRecreatingScrappedTutorial = true;
      tutorialCoachMark?.finish();
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          startTutorial();
        }
      });
    }
  }

  void scrollToTop() {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        0,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
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

  void scrollToAndFocus(GlobalKey key) {
    final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.5,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void handleTargetClick(TargetFocus target) {
    if (widget.customTutorialSteps.isNotEmpty) {
      if (target.identify.startsWith("custom")) {
        final entries = widget.customTutorialSteps.entries.toList();
        for (int i = 0; i < entries.length; i++) {
          final entry = entries[i];
          if (entry.key == target.identify) {
            if (i + 1 < entries.length) {
              final nextEntry = entries[i + 1];
              final nextKey = nextEntry.value['key'] as GlobalKey;
              scrollToAndFocus(nextKey);
            }
            break;
          }
        }
      }
    }
  }

  void startTutorial() {
    if (isTutorialRunning && !isRecreatingScrappedTutorial) {
      return;
    }
    isTutorialRunning = true;
    isRecreatingScrappedTutorial = false;

    scrollToTop();

    tutorialCoachMark = TutorialCoachMark(
      targets: createTargets(),
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
        isTutorialRunning = false;
      },
      onSkip: () {
        isTutorialRunning = false;
        return true;
      },
      onClickTarget: (target) {
        handleTargetClick(target);
      },
    )..show(context: context);
  }

  List<TargetFocus> createTargets() {
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

    final RenderBox renderBox = listViewKey.currentContext?.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "listViewKey",
        description: S.of(context).list_of_existing(widget.nomeTutorialPlural),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
        targetPosition: TargetPosition(
          Size(size.width, size.height * 0.6),
          Offset(offset.dx, offset.dy),
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
          align: value.containsKey('align') ? ObjectTemplate.getAlignFromString(value['align'] as String?) : ContentAlign.bottom,
        ),
      );
    });

    if (widget.onAddPressed != null) {
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

  void exitButton() {
    Navigator.of(context).pop(widget.returnObject);
  }

  @override
  Widget build(BuildContext context) {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final ThemeData theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          return await widget.onWillPop!();
        } else {
          exitButton();
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
                  exitButton();
                }
              } else {
                exitButton();
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
          actions: [
            PopupMenuButton<String>(
              key: moreOptionsKey,
              icon: Icon(Icons.more_vert),
              onSelected: (String result) {
                if (result == S.of(context).help) {
                  widget.onHelpPressed?.call();
                  startTutorial();
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
          ],
        ),
        body: Padding(
          key: bodyKey,
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            key: listViewKey,
            controller: scrollController,
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              //if (widget.itemBuilder != null) {
              //  return widget.itemBuilder!(context, item, index);
              //} else {
              //  return buildDefaultItem(context, item, index);
              //}
              return buildDefaultItem(context, item, index);
            },
          ),
        ),
        floatingActionButton: widget.onAddPressed != null
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

  Widget buildDefaultItem(BuildContext context, dynamic item, int index) {
    return Card(
      key: ValueKey('card_$index'),
      child: ListTile(
        title: Text(item.toString()),
        trailing: widget.isSelectMode
            ? IconButton(
          icon: Icon(Icons.arrow_forward_ios),
          onPressed: () {
            if (widget.isSetMode && widget.onItemSelected != null) {
              widget.onItemSelected!(item);
            }
            Navigator.of(context).pop(item);
          },
        )
            : PopupMenuButton<String>(
          key: ValueKey('popup_$index'),
          onSelected: (value) {
            if (value == 'view' && widget.onViewItem != null) {
              widget.onViewItem!(item);
            } else if (value == 'edit' && widget.onEditItem != null) {
              widget.onEditItem!(item);
            } else if (value == 'delete' && widget.onDeleteItem != null) {
              widget.onDeleteItem!(item);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            if (canView)
              PopupMenuItem<String>(
                value: 'view',
                child: Text(S.of(context).details, style: Theme.of(context).popupMenuTheme.textStyle),
              ),
            if (canEdit)
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(S.of(context).edit, style: Theme.of(context).popupMenuTheme.textStyle),
              ),
            if (canDelete)
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(S.of(context).delete, style: Theme.of(context).popupMenuTheme.textStyle),
              ),
          ],
        ),
      ),
    );
  }
}
