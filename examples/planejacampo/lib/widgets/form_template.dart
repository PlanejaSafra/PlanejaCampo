import 'dart:io';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/l10n/l10n.dart';

class FormTemplate extends StatefulWidget {
  final String title;
  final Widget body;
  final String moduleName;
  final FloatingActionButton? floatingActionButton;
  final GlobalKey<FormState> formKey;
  final Object returnObject;
  final Future<bool> Function() onWillPop;
  final List<CardSection>? cardSections;
  final Function? onSave;
  final Function? onDelete;
  final void Function(String produtorId)? onInitForm;
  final bool isNewItem;
  final bool? canEdit;
  final bool? canDelete;
  final bool? canView;
  final Widget? bottomNavigationBar;
  final bool showTutorial;
  final String nomeTutorial;
  final Map<String, Map<String, dynamic>> customTutorialSteps;
  final Map<String, Map<String, dynamic>> customActionTutorialSteps;
  final List<Widget> Function(BuildContext)? additionalFloatingActionButtons;
  final bool isExpanded;
  final bool Function()? onFloatingActionButtonPressed;

  const FormTemplate({
    Key? key,
    required this.title,
    required this.body,
    required this.moduleName,
    required this.formKey,
    required this.returnObject,
    required this.onWillPop,
    this.cardSections,
    this.canEdit,
    this.canDelete,
    this.canView,
    this.onSave,
    this.onDelete,
    this.onInitForm,
    this.floatingActionButton,
    this.isNewItem = false,
    this.bottomNavigationBar,
    this.showTutorial = false,
    this.nomeTutorial = '',
    this.customTutorialSteps = const {},
    this.customActionTutorialSteps = const {},
    this.additionalFloatingActionButtons,
    this.isExpanded = true,
    this.onFloatingActionButtonPressed, // Recebe a função externa
  }) : super(key: key);

  @override
  FormTemplateState createState() => FormTemplateState();
}

class FormTemplateState extends State<FormTemplate>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey backButtonKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey saveButtonKey = GlobalKey();
  final GlobalKey actionButtonKey = GlobalKey();
  final GlobalKey floatingActionButtonKey = GlobalKey();
  final ValueNotifier<bool> _showGradient = ValueNotifier(true);
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);

  TutorialCoachMark? tutorialCoachMark;
  late ScrollController _scrollController;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;
  bool canEdit = false;
  bool canView = false;
  bool canDelete = false;
  bool _isInitialized = false;
  GlobalKey _contentKey = GlobalKey();

    @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);
    
    // Verificação inicial do scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkContentSize();
    });

    AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    canDelete = widget.canDelete ?? appStateManager.canDelete(widget.moduleName);
    canEdit = widget.canEdit ?? appStateManager.canDelete(widget.moduleName);
    canView = widget.canView ?? appStateManager.canDelete(widget.moduleName);

    if (widget.showTutorial) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
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
          } else if (!_isInitialized) {
            _checkContentSize();
          }
        }
      } catch (e) {
        print('Erro ao verificar tamanho do formulário: $e');
        if (!_isInitialized) {
          _checkContentSize();
        }
      }
    });
  }

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
      return false;
    }
  }

  void _scrollListener() {
    if (!mounted || !_scrollController.hasClients) return;
    
    try {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      if (maxScrollExtent > 0) {
        setState(() {
          _scrollProgress.value = (_scrollController.offset / maxScrollExtent).clamp(0.0, 1.0);
        });
      }
    } catch (e) {
      print('Erro no scroll listener do formulário: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _scrollProgress.dispose();
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
    final RenderBox? renderBox =
        key.currentContext?.findRenderObject() as RenderBox?;
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
    if (target.identify == "backButton") {
      _scrollToAndFocus(widget.formKey);
    } else if (target.identify == "moreOptions") {
      _scrollToAndFocus(widget.formKey);
      // Abre o menu moreOptions, se necessário. Comentado porque só tem Ajuda no menu moreOptions.
      //final dynamic popUpMenuButton = moreOptionsKey.currentState;
      //popUpMenuButton?.showButtonMenu();
    } else if (widget.customTutorialSteps.isNotEmpty) {
      if (target.identify == "summarySection") {
        final firstEntry = widget.customTutorialSteps.entries.first;
        final firstKey = firstEntry.value['key'] as GlobalKey;
        _scrollToAndFocus(firstKey);
      } else if (target.identify == 'actionButton') {
        // Chama a função de callback para expandir o botão
        if (widget.onFloatingActionButtonPressed != null) {
          if (!widget.isExpanded) {
            widget.onFloatingActionButtonPressed!();
          }
        }
      } else if (target.identify.startsWith("custom")) {
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

    final theme = Theme.of(context);
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
        //print("Tutorial concluído");
        if (widget.onFloatingActionButtonPressed != null) {
          if (widget.isExpanded) {
            widget.onFloatingActionButtonPressed!();
          }
        }
        _isTutorialRunning = false;
      },
      onSkip: () {
        //print("Tutorial pulado");
        if (widget.onFloatingActionButtonPressed != null) {
          if (widget.isExpanded) {
            widget.onFloatingActionButtonPressed!();
          }
        }
        _isTutorialRunning = false;
        return true;
      },
      onClickTarget: (target) {
        //print("Clicked on target: ${target.identify}");
        _handleTargetClick(target);
      },
    )..show(context: context);
  }

  List<TargetFocus> _createTargets() {
    final theme = Theme.of(context);
    List<TargetFocus> targets = [];

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
        identify: "saveButton",
        keyTarget: saveButtonKey,
        description: S.of(context).click_to_save_changes,
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

    /*
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "formKey",
        keyTarget: widget.formKey,
        description: "Aqui você pode alterar as informações do ${widget.nomeTutorial}.",
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );
    */

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
          focusPadding: (value['focusPadding'] as double?) ??
              10.0, // Se for null, usa 10.0
          textPadding: (value['textPadding'] as double?) ?? 20.0,
          fatorReducaoQuadro: (value['fatorReducaoQuadro'] as double?),
        ),
      );
    });

    if ((widget.customActionTutorialSteps != null) &&
        (widget.customActionTutorialSteps.isNotEmpty)) {
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "actionButton",
          keyTarget: actionButtonKey,
          description: S.of(context).click_for_other_features,
          shape: ShapeLightFocus.Circle,
          align: ContentAlign.top,
          focusPadding: 30,
        ),
      );

      widget.customActionTutorialSteps.forEach((key, value) {
        targets.add(
          ObjectTemplate.getTutorialTarget(
            identify: key,
            description: value['message'] as String,
            keyTarget: value['key'] as GlobalKey,
            shape: ObjectTemplate.getShapeFromString(value['shape'] as String?),
            align: value.containsKey('align')
                ? ObjectTemplate.getAlignFromString(value['align'] as String?)
                : ContentAlign.top,
          ),
        );
      });
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

  Future<void> _confirmDelete(BuildContext context) async {
    if (canDelete) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content:
              Text(S.of(context).confirm_deletion_message(widget.nomeTutorial)),
          //content: Text('Deseja realmente excluir este ${widget.nomeTutorial}?'),
          actions: [
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text(S.of(context).delete),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirm ?? false) {
        if (widget.onDelete != null) {
          await widget.onDelete!();
        }
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } else {
      Navigator.of(context).pop(false);
    }
  }

  void _exitButton() {
    if (widget.onWillPop != null) {
      widget.onWillPop!().then((shouldPop) {
        if (shouldPop) {
          Navigator.of(context).pop(null);  // Retorna null ao invés de widget.returnObject
        }
      });
    } else {
      Navigator.of(context).pop(null);  // Retorna null ao invés de widget.returnObject
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final String produtorId = appStateManager.activeProdutor?.id ?? '';
    final FormatacaoUtil formatacaoUtil = appStateManager.formatacao;
    final ThemeData theme = Theme.of(context);

    bool effectiveCanEdit;
    if (widget.canEdit != null) {
      effectiveCanEdit = widget.canEdit!;
    } else if (widget.isNewItem) {
      effectiveCanEdit = true;
    } else {
      effectiveCanEdit = appStateManager.canEdit(widget.moduleName);
    }

    if (widget.onInitForm != null) {
      widget.onInitForm!(produtorId);
    }

    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          return await widget.onWillPop();
        } else {
          Navigator.of(context).pop(null);  // Retorna null ao invés de widget.returnObject
          return false;
        }
      },
      child: Scaffold(
        key: scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            key: backButtonKey,
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              _exitButton();
            },
          ),
          title: Text(widget.title, style: theme.textTheme.displayLarge),
          centerTitle: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 4,
          actions: [
            if (effectiveCanEdit)
              IconButton(
                key: saveButtonKey,
                icon: Icon(Icons.save),
                onPressed: () async {
                  if (widget.formKey.currentState?.validate() ?? false) {
                    widget.formKey.currentState?.save();
                    if (widget.onSave != null) {
                      if (widget.onSave is Future Function()) {
                        await widget.onSave!();
                      } else {
                        widget.onSave!();
                      }
                    }
                  }
                },
              ),
            PopupMenuButton<String>(
              key: moreOptionsKey,
              icon: Icon(Icons.more_vert),
              onSelected: (String result) {
                if (result == S.of(context).help) {
                  _startTutorial();
                } else if (result == S.of(context).remove && widget.onDelete != null) {
                  _confirmDelete(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: S.of(context).help,
                  child: Text(
                    S.of(context).help,
                    style: Theme.of(context).popupMenuTheme.textStyle
                  ),
                ),
                if (canDelete && !widget.isNewItem && widget.onDelete != null)
                  PopupMenuItem<String>(
                    value: S.of(context).remove,
                    child: Text(
                      S.of(context).remove,
                      style: Theme.of(context).popupMenuTheme.textStyle
                    ),
                  ),
              ],
              offset: Offset(0, 56),
            ),
          ],
        ),
        body: Stack(
          children: [
            Form(
              key: widget.formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  key: _contentKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: IgnorePointer(
                        ignoring: !effectiveCanEdit,
                        child: widget.body,
                      ),
                    ),
                    if (widget.cardSections != null)
                      ...widget.cardSections!.map((section) =>
                          ObjectTemplate.buildCardSection(section, theme)),
                    SizedBox(height: 40),
                  ],
                ),
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
                  final hasContent = _hasScrollableContent();
                  return AnimatedOpacity(
                    opacity: hasContent ? 1.0 : 0.0,
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
                                            _scrollController.position.maxScrollExtent > 0 &&
                                            progress < 0.98 ? 1.0 : 0.0,
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
                  final hasContent = _hasScrollableContent();
                  return AnimatedOpacity(
                    opacity: hasContent && progress < 0.98 ? 1.0 : 0.0,
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
            if (widget.additionalFloatingActionButtons != null)
              const Positioned(
                right: 0,
                bottom: 0,
                width: 88,
                height: 88,
                child: SizedBox(),
              ),
          ],
        ),
        floatingActionButton: Visibility(
          visible: widget.additionalFloatingActionButtons != null,
          child: Align(
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.isExpanded && widget.additionalFloatingActionButtons != null)
                  ...widget.additionalFloatingActionButtons!(context),
                const SizedBox(height: 10),
                FloatingActionButton(
                  key: floatingActionButtonKey,
                  heroTag: 'floatingActionButton',
                  mini: false,
                  child: Icon(
                    widget.isExpanded ? Icons.close : Icons.add,
                    key: actionButtonKey
                  ),
                  onPressed: () {
                    if (widget.onFloatingActionButtonPressed != null) {
                      widget.onFloatingActionButtonPressed!();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: widget.bottomNavigationBar,
      ),
    );
  }

}
