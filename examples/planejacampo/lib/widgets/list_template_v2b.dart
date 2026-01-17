import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/themes.dart';

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
  // New parameters
  final String Function(dynamic item)? itemTitleBuilder;
  final List<Widget> Function(BuildContext context, dynamic item)? itemSubtitleBuilder;
  final IconData Function(dynamic item)? itemIconBuilder;

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
    this.itemTitleBuilder,
    this.itemSubtitleBuilder,
    this.itemIconBuilder,
  }) : super(key: key);

  @override
  _ListTemplateState createState() => _ListTemplateState();
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
    super.dispose();
  }

  void startTutorial() {
    // Implement tutorial logic if needed
  }

  void exitButton() {
    Navigator.of(context).pop(widget.returnObject);
  }

  @override
  Widget build(BuildContext context) {
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
              //return buildDefaultItem(context, item, index);
            },
          ),
        ),
        floatingActionButton: widget.onAddPressed != null &&
            (canEdit || (widget.moduleName == 'produtores' && Provider.of<AppStateManager>(context).canCreateMoreProdutores))
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
    final String title = widget.itemTitleBuilder != null ? widget.itemTitleBuilder!(item) : item.toString();
    final List<Widget>? subtitleWidgets = widget.itemSubtitleBuilder != null ? widget.itemSubtitleBuilder!(context, item) : null;
    final IconData? leadingIcon = widget.itemIconBuilder != null ? widget.itemIconBuilder!(item) : null;

    return Card(
      key: ValueKey('card_$index'),
      child: ListTile(
        leading: leadingIcon != null ? Icon(leadingIcon, color: Theme.of(context).colorScheme.primary) : null,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: subtitleWidgets != null
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: subtitleWidgets,
        )
            : null,
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
                child: Text(
                  S.of(context).details,
                  style: Theme.of(context).popupMenuTheme.textStyle,
                ),
              ),
            if (canEdit)
              PopupMenuItem<String>(
                value: 'edit',
                child: Text(
                  S.of(context).edit,
                  style: Theme.of(context).popupMenuTheme.textStyle,
                ),
              ),
            if (canDelete)
              PopupMenuItem<String>(
                value: 'delete',
                child: Text(
                  S.of(context).delete,
                  style: Theme.of(context).popupMenuTheme.textStyle,
                ),
              ),
          ],
        ),
        onTap: () {
          if (widget.onItemSelected != null) {
            widget.onItemSelected!(item);
          }
        },
      ),
    );
  }
}
