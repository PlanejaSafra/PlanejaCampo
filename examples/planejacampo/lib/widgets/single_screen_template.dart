import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/services/generic_service.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/widgets/card_section.dart';

class SingleScreenTemplate<T> extends StatefulWidget {
  final String title;
  final Widget summarySection;
  final List<CardSection> cardSections;
  final String moduleName;
  final GenericService<T> serviceName; // Service a ser utilizado (ex: produtorService, propriedadeService, compraService)
  final String itemIdValue; // Valor do Id da classe (ex: produtorId, propriedadeId, compraId)
  final String itemName; // Nome da entidade - descrição a ser exibida (ex: Produtor, Propriedade, Compra)
  final String fieldReference; // Nome do campo a ser pesquisado como referência (ex: 'produtorId', 'propriedadeId')
  final Object returnObject;
  final Future<bool> Function() onWillPop;
  final bool canEdit;
  final bool canDelete;
  final bool canView;
  final Widget? bottomNavigationBar;
  final List<Widget>? additionalActions;
  final bool showTutorial;
  final String nomeTutorial;
  final String nomeTutorialPlural;
  final Map<String, Map<String, dynamic>> customTutorialSteps;
  final Map<String, Map<String, dynamic>> customActionTutorialSteps;
  final VoidCallback? onEditPressed;
  final VoidCallback? onDeletePressed;
  final Function? onSuccessDeleteDialog; // Função opcional a ser executada em caso de sucesso.
  final bool isExpanded;
  final bool Function()? onFloatingActionButtonPressed;
  final List<Widget> Function(BuildContext)? additionalFloatingActionButtons;

  const SingleScreenTemplate({
    Key? key,
    required this.title,
    required this.summarySection,
    required this.cardSections,
    required this.moduleName,
    required this.serviceName,
    required this.itemIdValue,
    required this.itemName,
    required this.fieldReference,
    required this.returnObject,
    required this.onWillPop,
    this.onSuccessDeleteDialog, // Parâmetro opcional
    this.canEdit = false,
    this.canDelete = false,
    this.canView = false,
    this.bottomNavigationBar,
    this.additionalActions,
    this.showTutorial = false,
    this.nomeTutorial = '',
    this.nomeTutorialPlural = '',
    this.customTutorialSteps = const {},
    this.customActionTutorialSteps = const {},
    this.onEditPressed,
    this.onDeletePressed,
    this.isExpanded = true,
    this.onFloatingActionButtonPressed, // Recebe a função externa
    this.additionalFloatingActionButtons, // Botões adicionais
  }) : super(key: key);

  @override
  _SingleScreenTemplateState<T> createState() => _SingleScreenTemplateState<T>();
}

class _SingleScreenTemplateState<T> extends State<SingleScreenTemplate<T>>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey backButtonKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey summarySectionKey = GlobalKey();
  final GlobalKey ajudaOptionKey = GlobalKey();
  final GlobalKey alterarOptionKey = GlobalKey();
  final GlobalKey removerOptionKey = GlobalKey();
  final GlobalKey floatingActionButtonKey = GlobalKey();
  final GlobalKey actionButtonKey = GlobalKey();
  //final ValueNotifier<bool> _showGradient = ValueNotifier(true);
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);

  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  late ScrollController _scrollController;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;
  // Na classe _SingleScreenTemplateState, adicione:
  bool _isInitialized = false;
  GlobalKey _contentKey = GlobalKey(); // novo

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addObserver(this);

    // Inicia a verificação após a construção inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkContentSize();
    });

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

    // Agenda uma verificação após um breve delay para garantir que o conteúdo foi renderizado
    Future.delayed(Duration(milliseconds: 50), () {
      if (!mounted) return;

      try {
        final RenderBox? box = _contentKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final contentHeight = box.size.height;
          final viewportHeight = MediaQuery.of(context).size.height -
              (MediaQuery.of(context).padding.top + 
              MediaQuery.of(context).padding.bottom + 
              kToolbarHeight); // Considera a AppBar

          final hasScrollableContent = contentHeight > viewportHeight;
          
          if (hasScrollableContent && _scrollController.hasClients) {
            setState(() {
              _isInitialized = true;
              _scrollProgress.value = _scrollController.offset / _scrollController.position.maxScrollExtent;
            });
            //print('Conteúdo scrollável detectado: altura do conteúdo = $contentHeight, altura da viewport = $viewportHeight');
          } else if (!_isInitialized) {
            // Tenta novamente se ainda não estiver inicializado
            _checkContentSize();
          }
        }
      } catch (e) {
        print('Erro ao verificar tamanho do conteúdo: $e');
        if (!_isInitialized) {
          _checkContentSize();
        }
      }
    });
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

  void _updateScrollProgress() {
    if (_scrollController.hasClients) {
      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final currentOffset = _scrollController.offset;
      //print('maxScrollExtent: $maxScrollExtent, offset: $currentOffset');
      if (maxScrollExtent > 0) {
        _scrollProgress.value = currentOffset / maxScrollExtent;
        //print('Scroll progress atualizado para: ${_scrollProgress.value}');
      } else {
        _scrollProgress.value = 0.0;
        //print('Scroll progress definido para 0.0');
      }
    }
  }

  bool _hasScrollableContent() {
    if (!mounted || !_scrollController.hasClients) return false;
    try {
      // Primeiro verifica se o ScrollController tem posição válida
      if (!_scrollController.position.hasPixels ||
          !_scrollController.position.hasViewportDimension) {
        return false;
      }

      final viewportHeight = MediaQuery.of(context).size.height -
          (MediaQuery.of(context).padding.top +
              MediaQuery.of(context).padding.bottom +
              kToolbarHeight);

      final contentHeight = _scrollController.position.viewportDimension +
          _scrollController.position.maxScrollExtent;

      return contentHeight > viewportHeight && contentHeight > 0;
    } catch (e) {
      // Log mais descritivo do erro
      print('Erro ao verificar conteúdo scrollável: $e');
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
        //print('Scroll progress atualizado para: ${_scrollProgress.value}');
      }
    } catch (e) {
      print('Erro no scroll listener: $e');
    }
  }


  @override
  void didUpdateWidget(SingleScreenTemplate<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Detectar mudanças nos cardSections
    if (widget.cardSections != oldWidget.cardSections) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollProgress.value = _scrollController.position.maxScrollExtent > 0
              ? _scrollController.offset / _scrollController.position.maxScrollExtent
              : 0.0;
          //print('Scroll progress atualizado via didUpdateWidget.');
        }
      });
    }

    // Detectar mudanças nos customTutorialSteps
    if (widget.customTutorialSteps != oldWidget.customTutorialSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollProgress.value = _scrollController.position.maxScrollExtent > 0
              ? _scrollController.offset / _scrollController.position.maxScrollExtent
              : 0.0;
          //print('Scroll progress atualizado via didUpdateWidget (customTutorialSteps).');
        }
      });
    }

    // Detectar mudanças nos customActionTutorialSteps
    if (widget.customActionTutorialSteps != oldWidget.customActionTutorialSteps) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scrollController.hasClients) {
          _scrollProgress.value = _scrollController.position.maxScrollExtent > 0
              ? _scrollController.offset / _scrollController.position.maxScrollExtent
              : 0.0;
          //print('Scroll progress atualizado via didUpdateWidget (customActionTutorialSteps).');
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

  void _handleTargetClick(TargetFocus target) {
    if (target.identify == "backButton") {
      _scrollToAndFocus(summarySectionKey);
    } else if (target.identify == "moreOptions") {
      _scrollToAndFocus(summarySectionKey);
      final dynamic popUpMenuButton = moreOptionsKey.currentState;
      popUpMenuButton?.showButtonMenu();
    } else if (target.identify == "moreOptionsButton") {
      //print('Agora clicou nele.');

    } else if (widget.customTutorialSteps.isNotEmpty) {
      if (target.identify == "summarySection") {
        final firstEntry = widget.customTutorialSteps.entries.first;
        final firstKey = firstEntry.value['key'] as GlobalKey;
        _scrollToAndFocus(firstKey);
      } else if (target.identify == 'alterarOption') {
        // Preciso implementar para fechar o menu, mas ainda não consegui.
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
              //_scrollToAndFocus(nextKey);
            } else {
            }
            break;
          }
        }

        //_scrollToAndFocus(firstKey);
      }
    }
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

    //_scrollToAndFocus(summarySectionKey);
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "summarySection",
        keyTarget: summarySectionKey,
        description: S.of(context).summary_of_information(widget.nomeTutorial),
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    widget.customTutorialSteps.forEach((key, value) {
      //print('key: $key, value: $value, value[key]: ${value['key']}, value[message]: ${value['message']}');
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: key,
          description: value['message'] as String,
          keyTarget: value['key'] as GlobalKey,
          shape: ObjectTemplate.getShapeFromString(value['shape'] as String?),
          align: value.containsKey('align')
              ? ObjectTemplate.getAlignFromString(value['align'] as String?)
              : ContentAlign.bottom,
          focusPadding: (value['focusPadding'] as double?) ?? 10.0, // Se for null, usa 10.0
          textPadding: (value['textPadding'] as double?) ?? 20.0,
          fatorReducaoQuadro: (value['fatorReducaoQuadro'] as double?),
        ),
      );
    });

    if ((widget.customActionTutorialSteps != null) && (widget.customActionTutorialSteps.isNotEmpty)) {
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
            shape: ObjectTemplate.getShapeFromString(
                value['shape'] as String?),
            align: value.containsKey('align')
                ? ObjectTemplate.getAlignFromString(value['align'] as String?)
                : ContentAlign.top,
          ),
        );
      });
    }

    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "moreOptions",
        keyTarget: moreOptionsKey,
        description: (widget.moduleName == 'produtores' || widget.moduleName == 'propriedades')
          ? S.of(context).click_to_see_more_options_restricted
          : S.of(context).click_to_see_more_options,
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "ajudaOption",
        keyTarget: ajudaOptionKey,
        description: S.of(context).click_to_show_help_tutorial,
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    if (widget.canEdit) {
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "alterarOption",
          keyTarget: alterarOptionKey,
          description: S.of(context).click_to_edit(widget.nomeTutorial),
          shape: ShapeLightFocus.RRect,
          align: ContentAlign.bottom,
        ),
      );
    }

    if (widget.canDelete) {
      targets.add(
        ObjectTemplate.getTutorialTarget(
          identify: "removerOption",
          keyTarget: removerOptionKey,
          description: S.of(context).click_to_remove(widget.nomeTutorial),
          shape: ShapeLightFocus.RRect,
          align: ContentAlign.bottom,
        ),
      );
    }

    return targets;
  }

  Future<void> _confirmDelete() async {
    /*
    print('serviceName: ${widget.serviceName}');
    print('itemIdValue: ${widget.itemIdValue}');
    print('itemName: ${widget.itemName}');
    print('fieldReference: ${widget.fieldReference}');
    print('onSuccessDeleteDialog: ${widget.onSuccessDeleteDialog}');
    */
    //print('onSuccessDeleteDialog: ${widget.onSuccessDeleteDialog.runtimeType}')
    await DialogScreen.confirmDelete(
      context,
      serviceName: widget.serviceName,
      itemIdValue: widget.itemIdValue,
      itemName: widget.itemName,
      onSuccessDialog: widget.onSuccessDeleteDialog ?? () {
        Navigator.of(context).pop(true);
      },
    );
  }

  _exitButton() {
    Navigator.of(context).pop(widget.returnObject);
  }

  @override
  Widget build(BuildContext context) {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context);
    final bool canEdit = widget.canEdit || appStateManager.canEdit(widget.moduleName);
    final bool canDelete = widget.canDelete || appStateManager.canDelete(widget.moduleName);
    final bool canView = widget.canView || appStateManager.canView(widget.moduleName);
    final FormatacaoUtil formatacaoUtil = appStateManager.formatacao;
    final ThemeData theme = Theme.of(context);

    List<Widget> appBarActions = [];

    appBarActions.add(
      PopupMenuButton<String>(
        key: moreOptionsKey,
        icon: Icon(Icons.more_vert),
        onSelected: (String result) {
          if (result == S.of(context).help) {
            _startTutorial();
          } else if (result == S.of(context).edit && widget.onEditPressed != null) {
            widget.onEditPressed!();
          } else if (result == S.of(context).remove) {
            if (widget.onDeletePressed != null) {
              widget.onDeletePressed!();
            } else {
              _confirmDelete();
            }
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          PopupMenuItem<String>(
            value: S.of(context).help,
            key: ajudaOptionKey,
            child: Text(S.of(context).help, style: Theme.of(context).popupMenuTheme.textStyle),
          ),
          if (canEdit)
            PopupMenuItem<String>(
              value: S.of(context).edit,
              key: alterarOptionKey,
              child: Text(S.of(context).edit, style: Theme.of(context).popupMenuTheme.textStyle),
            ),
          if (canDelete)
            PopupMenuItem<String>(
              value: S.of(context).remove,
              key: removerOptionKey,
              child: Text(S.of(context).remove, style: Theme.of(context).popupMenuTheme.textStyle),
            ),
        ],
        offset: Offset(0, 56),
      ),
    );

    if (widget.additionalActions != null) {
      appBarActions.addAll(widget.additionalActions!);
    }

    // Adicionar um post frame callback para garantir que o progresso de rolagem seja atualizado após a construção
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollProgress.value = _scrollController.position.maxScrollExtent > 0
            ? _scrollController.offset / _scrollController.position.maxScrollExtent
            : 0.0;
        //print('Scroll progress atualizado via postFrameCallback no build: ${_scrollProgress.value}');
      }
    });

    return WillPopScope(
      onWillPop: () async {
        if (widget.onWillPop != null) {
          return await widget.onWillPop();
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
            onPressed: () {
              _exitButton();
            },
          ),
          title: Text(widget.title, style: theme.textTheme.displayLarge),
          centerTitle: true,
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: 4,
          actions: appBarActions,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                key: _contentKey, // Adicione a key aqui
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    key: summarySectionKey,
                    padding: const EdgeInsets.all(16.0),
                    child: widget.summarySection,
                  ),
                  if (widget.cardSections != null)
                    ...widget.cardSections!.map((section) => 
                      ObjectTemplate.buildCardSection(section, theme)),
                  SizedBox(height: 40),
                ],
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
                                    // No indicador inferior
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
                  child: Icon(widget.isExpanded ? Icons.close : Icons.add, key: actionButtonKey),
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