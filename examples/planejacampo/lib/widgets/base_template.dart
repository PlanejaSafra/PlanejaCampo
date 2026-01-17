import 'package:flutter/material.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_generator_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacoes_list_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/resultados_analises_solos_list_screen.dart';
import 'package:planejacampo/screens/finances/contas_pagar_list_screen.dart';
import 'package:planejacampo/screens/finances/lancamentos_contabeis_list_screen.dart';
import 'package:planejacampo/utils/atividade_rural_options.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/screens/finance_screen.dart';
import 'package:planejacampo/screens/home_screen.dart';
import 'package:planejacampo/screens/appbar/settings_screen.dart';
import 'package:planejacampo/screens/appbar/propriedades_list_screen.dart';
import 'package:planejacampo/screens/appbar/produtores_list_screen.dart';
import 'package:planejacampo/screens/appbar/itens_list_screen.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/screens/appbar/compra/compras_list_screen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:planejacampo/route_observer.dart';
import 'package:planejacampo/themes.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/screens/appbar/registros_chuvas_list_screen.dart';
import 'package:planejacampo/screens/finances/bancos_list_screen.dart';
import 'package:planejacampo/screens/agro/silvicultura/registros_coletas_list_screen.dart';
import 'package:planejacampo/screens/agro/silvicultura/registros_entregas_list_screen.dart';
import 'package:planejacampo/screens/finances/relatorio_compras.dart';
import 'package:planejacampo/themes/chart_theme.dart';
import 'package:planejacampo/screens/agro/atividades_rurais_list_screen.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/screens/agro/operacoes_rurais_list_screen.dart';
import 'package:planejacampo/utils/modules.dart';
import 'package:planejacampo/screens/agro/tipos_operacoes_rurais_list_screen.dart';
import 'package:planejacampo/screens/agro/frotas_list_screen.dart';

class BaseTemplate extends StatefulWidget {
  final String title;
  final Widget body;
  final int? selectedIndex;
  final FloatingActionButton? floatingActionButton;
  final bool showBottomNavigationBar;
  final List<Widget>? appBarActions;
  final bool showTutorial;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onTutorialFinished;
  final VoidCallback? onNavigationReturn;

  const BaseTemplate({
    Key? key,
    required this.title,
    required this.body,
    this.selectedIndex,
    this.floatingActionButton,
    this.showBottomNavigationBar = true,
    this.appBarActions,
    this.showTutorial = false,
    this.onHelpPressed,
    this.onTutorialFinished,
    this.onNavigationReturn,
  }) : super(key: key);

  @override
  BaseTemplateState createState() => BaseTemplateState();
}

class BaseTemplateState extends State<BaseTemplate>
    with RouteAware, WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey appBarKey = GlobalKey();
  final GlobalKey moreOptionsKey = GlobalKey();
  final GlobalKey homeIconKey = GlobalKey();
  final GlobalKey agroIconKey = GlobalKey();
  final GlobalKey financeIconKey = GlobalKey();
  final GlobalKey selecionarProdutorKey = GlobalKey();
  final GlobalKey selecionarPropriedadeKey = GlobalKey();
  final GlobalKey selecionarAtividadeRuralKey = GlobalKey();
  final GlobalKey appBarHomeKey = GlobalKey();
  final GlobalKey produtoresKey = GlobalKey();
  final GlobalKey propriedadesKey = GlobalKey();
  final GlobalKey itensKey = GlobalKey();
  final GlobalKey pessoasKey = GlobalKey();
  final GlobalKey registrosChuvasKey = GlobalKey();
  final GlobalKey comprasKey = GlobalKey();
  final GlobalKey configuracoesKey = GlobalKey();
  final GlobalKey searchButtonKey = GlobalKey();

  List<TargetFocus> targets = [];
  TutorialCoachMark? tutorialCoachMark;
  bool _isTutorialRunning = false;
  bool _isRecreatingScrappedTutorial = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(
          Duration(milliseconds: 900)); // Ajuste o tempo conforme necessário
      if (mounted && widget.showTutorial && !_isTutorialRunning) {
        _startTutorial();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_isTutorialRunning) {
      tutorialCoachMark?.finish();
    }
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isTutorialRunning) {
      _isRecreatingScrappedTutorial = true;
      tutorialCoachMark?.finish();
      // Adicione um pequeno atraso antes de recriar o tutorial
      Future.delayed(Duration(milliseconds: 900), () {
        if (mounted) {
          _startTutorial();
        }
      });
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    if (widget.selectedIndex != index) {
      switch (index) {
        case 0:
          _navigateTo(context, const HomeScreen(), '/');
          break;
        case 1:
          _navigateTo(context, const FinanceScreen(), '/finance');
          break;
      }
    }
  }

  void _navigateTo(BuildContext context, Widget screen, String routeName) {
    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        settings: RouteSettings(name: routeName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
      (Route<dynamic> route) => route.isFirst,
    );
  }

  void _closeDrawerAndNavigate(
      BuildContext context, VoidCallback navigationCallback) {
    if (scaffoldKey.currentState!.isDrawerOpen) {
      Navigator.of(context).pop();
      Future.delayed(const Duration(milliseconds: 300), navigationCallback);
    } else {
      navigationCallback();
    }
  }

  /*
  void _showPropriedadeSelection(BuildContext context) {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PropriedadesListScreen(
          onPropriedadeSelected: (propriedade) {
            if (propriedade != null) {
              Provider.of<AppStateManager>(context, listen: false)
                  .setActivePropriedade(propriedade);
            }
          },
          isFromMenu: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((_) {
      Provider.of<AppStateManager>(context, listen: false).notifyListeners();
    });
  }
  */
  void _showPropriedadeSelection(BuildContext context) {
    Navigator.of(context)
        .push<Object?>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PropriedadesListScreen(isSelectMode: true, isSetMode: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((result) {
      // Certifique-se de que o resultado não seja nulo ou um booleano
      /*
      Comentado porque tudo já é feito em propriedadesListScreen.
      if (result != null && result is Propriedade) {
        Propriedade selectedPropriedade = result;
        Provider.of<AppStateManager>(context, listen: false).setActivePropriedade(selectedPropriedade);
      }
      */
      Provider.of<AppStateManager>(context, listen: false).notifyListeners();
    });
  }

  Future<void> _showProdutorSelection(BuildContext context) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    final result = await navigator.push<Object?>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const ProdutoresListScreen(isSelectMode: true, isSetMode: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );

    if (result != null && result is Produtor) {
      // Um novo produtor foi selecionado
      // Aguarde 2 segundos
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          navigator.pushNamedAndRemoveUntil(
              '/', (Route<dynamic> route) => false);
        }
      });
    }
  }

  void _showAtividadeRuralSelection(BuildContext context) {
    Navigator.of(context)
        .push<Object?>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AtividadesRuraisListScreen(
                isSelectMode: true, isSetMode: true),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((result) {
      Provider.of<AppStateManager>(context, listen: false).notifyListeners();
    });
  }

  String _formatNome(String nome) {
    return nome
        .split(' ')
        .map((str) => str[0].toUpperCase() + str.substring(1).toLowerCase())
        .join(' ');
  }

  /*
  void _navigateAndCloseDrawer(BuildContext context, Widget screen, String routeName) {
    print('Entrou aqui...........................');
    if (scaffoldKey.currentState!.isDrawerOpen) {
      print('Entrou aqui 2...........................');
      Navigator.of(context).pop(); // Fecha o drawer se estiver aberto
      print('Entrou aqui 3...........................');
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screen,
        settings: RouteSettings(name: routeName),
      ),
    ).then((result) {
      print('Entrou aqui 4...........................');
      print('baseTemplate volta de _navigateAndCloseDrawer result: $result');
      if (result == true) {
        print('Entrou aqui 5...........................');
        // Se houve alteração nos dados, força uma atualização
        if (context.mounted) {
          print('Entrou aqui 6...........................');
          Provider.of<AppStateManager>(context, listen: false).notifyListeners();
          print('Entrou aqui 7...........................');
        }
      }
    });
  }
  */
  /*
  void _navigateAndCloseDrawer(
      BuildContext context, Widget screen, String routeName) {
    _closeDrawerAndNavigate(context, () => _navigateTo(context, screen, routeName));
  }

  */
  void _navigateAndCloseDrawer(
      BuildContext context, Widget screen, String routeName) {
    Navigator.of(context).pop(); // Fecha o Drawer se estiver aberto
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen))
        .then((result) {
      if (result != null && result != false) {  // ← Aceita qualquer retorno válido
        setState(() {});
        widget.onNavigationReturn?.call();
      }
    });
  }

  List<TargetFocus> _createTargets() {
    targets.clear();
    _initializeTargets(); // Chama _initializeTargets para garantir que todos os alvos sejam criados
    return targets; // Retorna a lista completa de alvos
  }

  void _updateTutorialPositions() {
    if (tutorialCoachMark != null) {
      tutorialCoachMark!.finish();
      Future.delayed(Duration(milliseconds: 300), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          tutorialCoachMark = TutorialCoachMark(
            targets: _createTargets(),
            colorShadow: AppThemes.tutorialColorShadow,
            skipWidget: ElevatedButton(
              onPressed: () {
                tutorialCoachMark?.skip();
              },
              child: Text(S.of(context).skip,
                  style: AppThemes.tutorialTextStyleSkip),
            ),
            textSkip: S.of(context).skip,
            textStyleSkip: AppThemes.tutorialTextStyleSkip,
            alignSkip: Alignment.center,
            paddingFocus: 10,
            opacityShadow: 0.95,
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
              _handleTargetClick(target);
            },
          )..show(context: context);
        });
      });
    }
  }

  void _initializeTargets() {
    final theme = Theme.of(context);
    targets.clear();

    // 1.1. Home (menu inferior)
    targets.add(
      TargetFocus(
        identify: "Home",
        keyTarget: homeIconKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child:
                Text(S.of(context).tutorial_home_button, // Internacionalizado
                    style: AppThemes.tutorialTextStyle,
                    textAlign: TextAlign.center),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );

    // 1.2. Finanças (menu inferior)
    targets.add(
      TargetFocus(
        identify: "Finances",
        keyTarget: financeIconKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Text(
                S.of(context).tutorial_finance_button, // Internacionalizado
                style: AppThemes.tutorialTextStyle,
                textAlign: TextAlign.center),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );

    // 1.3. Finanças (menu inferior)
    targets.add(
      TargetFocus(
        identify: "Agro",
        keyTarget: agroIconKey,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child:
                Text(S.of(context).tutorial_agro_button, // Internacionalizado
                    style: AppThemes.tutorialTextStyle,
                    textAlign: TextAlign.center),
          ),
        ],
        shape: ShapeLightFocus.Circle,
      ),
    );

    // 3. More Options (botão da barra de status)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "moreOptions",
        keyTarget: moreOptionsKey,
        description:
            S.of(context).click_to_see_more_options, // Internacionalizado
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    // 4. AppBar (botão de menu)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "Menu",
        keyTarget: appBarKey,
        description: S.of(context).tutorial_menu_button, // Internacionalizado
        shape: ShapeLightFocus.Circle,
        align: ContentAlign.bottom,
      ),
    );

    // 5.1. Selecionar Produtor (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "SelecionarProdutorKey",
        keyTarget: selecionarProdutorKey,
        description:
            S.of(context).click_to_select_producer, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 5.2. Selecionar Propriedade (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "SelecionarPropriedadeKey",
        keyTarget: selecionarPropriedadeKey,
        description:
            S.of(context).click_to_select_property, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 5.3. Selecionar Atividade Agrícola (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "SelecionarAtividadeRuralKey",
        keyTarget: selecionarAtividadeRuralKey,
        description:
            S.of(context).click_to_select_activity, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 7. Home (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "AppBarHomeKey",
        keyTarget: appBarHomeKey,
        description:
            S.of(context).tutorial_home_return_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 8. Produtores (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "ProdutoresKey",
        keyTarget: produtoresKey,
        description:
            S.of(context).tutorial_producers_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 9. Propriedades (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "PropriedadesKey",
        keyTarget: propriedadesKey,
        description:
            S.of(context).tutorial_properties_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 10. Itens, Insumos e Produtos (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "ItensKey",
        keyTarget: itensKey,
        description: S.of(context).tutorial_items_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.bottom,
      ),
    );

    // 11. Pessoas (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "PessoasKey",
        keyTarget: pessoasKey,
        description: S.of(context).tutorial_people_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.top,
      ),
    );

    // 12. Compras e Serviços (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "ComprasKey",
        keyTarget: comprasKey,
        description:
            S.of(context).tutorial_purchases_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.top,
      ),
    );
    // 13. Compras e Serviços (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "registrosChuvasKey",
        keyTarget: registrosChuvasKey,
        description:
            S.of(context).tutorial_rain_quantity_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.top,
      ),
    );
    // 14. Settings (dentro do AppBar)
    targets.add(
      ObjectTemplate.getTutorialTarget(
        identify: "SettingsAppBar",
        keyTarget: configuracoesKey,
        description:
            S.of(context).tutorial_settings_button, // Internacionalizado
        shape: ShapeLightFocus.RRect,
        align: ContentAlign.top,
      ),
    );
  }

  void _startTutorial() {
    if (!mounted || (_isTutorialRunning && !_isRecreatingScrappedTutorial)) {
      return;
    }
    _isTutorialRunning = true;
    _isRecreatingScrappedTutorial = false;

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
      alignSkip: Alignment.centerRight,
      paddingFocus: 10,
      opacityShadow: 0.95,
      onFinish: () {
        //print("Tutorial concluído");
        _isTutorialRunning = false;
        widget.onTutorialFinished?.call();
      },
      onSkip: () {
        //print("Tutorial pulado");
        _isTutorialRunning = false;
        widget.onTutorialFinished?.call();
        return true;
      },
      onClickTarget: (target) {
        //print("Clicked on target: ${target.identify}");
        _handleTargetClick(target);
      },
    )..show(context: context);
  }

  void _handleTargetClick(TargetFocus target) {
    //print("Clicked on target: ${target.identify}");
    if (target.identify == "Menu") {
      scaffoldKey.currentState?.openDrawer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ChartTheme chartTheme = theme.extension<ChartTheme>()!;

    final isDarkMode = theme.brightness == Brightness.dark;

    return Consumer<AppStateManager>(
      builder: (context, appStateManager, child) {
        if (appStateManager.producerChanged) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            //Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            //_showPropriedadeSelection(context);
            appStateManager.resetProducerChanged();
          });
        }

        return OrientationBuilder(builder: (context, orientation) {
          return Scaffold(
            key: scaffoldKey,
            appBar: AppBar(
              title: Text(
                widget.title,
                style: theme.textTheme.displayLarge,
              ),
              centerTitle: true,
              backgroundColor: theme.appBarTheme.backgroundColor,
              elevation: 4,
              leading: IconButton(
                key: appBarKey,
                icon: const Icon(Icons.menu),
                onPressed: () {
                  scaffoldKey.currentState?.openDrawer();
                },
              ),
              actions: widget.appBarActions ??
                  [
                    PopupMenuButton<String>(
                      key: moreOptionsKey,
                      icon: Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == S.of(context).help) {
                          if (widget.onHelpPressed != null) {
                            widget.onHelpPressed!();
                          }
                          _startTutorial();
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
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
                  ],
            ),
            drawer: _buildDrawer(context, appStateManager, theme),
            body: Container(
              color: theme.scaffoldBackgroundColor,
              child: widget.body,
            ),
            bottomNavigationBar:
                _buildBottomNavigationBar(context, appStateManager, theme),
            floatingActionButton: widget.floatingActionButton,
          );
        });
      },
    );
  }

  Widget _buildDrawer(
      BuildContext context, AppStateManager appStateManager, ThemeData theme) {
    return Drawer(
      child: Container(
        color: theme.colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            SizedBox(
              height: 304,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.of(context).producer,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showProdutorSelection(context),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                key: selecionarProdutorKey,
                                appStateManager.activeProdutor != null
                                    ? appStateManager.activeProdutor!.nome
                                    : S.of(context).select_producer,
                                style: theme.textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).agricultural_property,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showPropriedadeSelection(context),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                key: selecionarPropriedadeKey,
                                appStateManager.activePropriedade != null
                                    ? appStateManager.activePropriedade!.nome
                                    : S.of(context).select_property,
                                style: theme.textTheme.headlineMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        S.of(context).rural_activity,
                        style: theme.textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showAtividadeRuralSelection(context),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: appStateManager.activeAtividadeRural !=
                                      null
                                  ? Column(
                                      key: selecionarAtividadeRuralKey,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${AtividadeRuralOptions.getLocalizedTiposAtividades(context)[appStateManager.activeAtividadeRural!.tipo] ?? appStateManager.activeAtividadeRural!.tipo} - ' +
                                              '${AtividadeRuralOptions.getLocalizedSubtiposAtividades(context)[appStateManager.activeAtividadeRural!.tipo]?.firstWhere((subtipo) => subtipo == appStateManager.activeAtividadeRural!.subtipo, orElse: () => appStateManager.activeAtividadeRural!.subtipo) ?? appStateManager.activeAtividadeRural!.subtipo}',
                                          style: theme.textTheme.displaySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          appStateManager
                                              .activeAtividadeRural!.nome,
                                          style: theme.textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    )
                                  : Text(
                                      key: selecionarAtividadeRuralKey,
                                      S.of(context).select_rural_activity,
                                      style: theme.textTheme.displayMedium,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ListTile(
              key: appBarHomeKey,
              leading: Icon(Icons.home, color: theme.iconTheme.color),
              title: Text(S.of(context).home,
                  style: theme.textTheme.displayMedium),
              onTap: () {
                _navigateAndCloseDrawer(context, const HomeScreen(), '/');
              },
            ),
            ListTile(
                key: produtoresKey,
                leading: Icon(Icons.people, color: theme.iconTheme.color),
                title: Text(S.of(context).rural_producers,
                    style: theme.textTheme.displayMedium),
                onTap: () {
                  _navigateAndCloseDrawer(
                      context, const ProdutoresListScreen(), '/produtoresList');
                }),
            if (appStateManager.canView('propriedades'))
              ListTile(
                key: propriedadesKey,
                leading: Icon(Icons.business, color: theme.iconTheme.color),
                title: Text(S.of(context).agricultural_properties,
                    style: theme.textTheme.displayMedium),
                onTap: () {
                  _navigateAndCloseDrawer(context,
                      const PropriedadesListScreen(), '/propriedadesList');
                },
              ),
            if (appStateManager.canView('itens'))
              ListTile(
                  key: itensKey,
                  leading: Icon(Icons.inventory, color: theme.iconTheme.color),
                  title: Text(S.of(context).inputs_and_products,
                      style: theme.textTheme.displayMedium),
                  onTap: () {
                    _navigateAndCloseDrawer(
                        context, const ItensListScreen(), '/itensList');
                  }),
            if (appStateManager.canView('pessoas'))
              ListTile(
                key: pessoasKey,
                leading: Icon(Icons.business, color: theme.iconTheme.color),
                title: Text(S.of(context).people_entities,
                    style: theme.textTheme.displayMedium),
                onTap: () {
                  _navigateAndCloseDrawer(
                      context, PessoasListScreen(), '/pessoasList');
                },
              ),
            if (appStateManager.canView('compras'))
              ListTile(
                key: comprasKey,
                leading:
                    Icon(Icons.shopping_cart, color: theme.iconTheme.color),
                title: Text(S.of(context).purchase_services,
                    style: theme.textTheme.displayMedium),
                onTap: () {
                  _navigateAndCloseDrawer(
                      context, ComprasListScreen(), '/comprasList');
                },
              ),
            if (appStateManager.canView('registrosChuvas'))
              ListTile(
                key: registrosChuvasKey,
                leading:
                    Icon(Icons.cloudy_snowing, color: theme.iconTheme.color),
                title: Text(S.of(context).rain_records,
                    style: theme.textTheme.displayMedium),
                onTap: () {
                  _navigateAndCloseDrawer(context, RegistrosChuvasListScreen(),
                      '/registroschuvasList');
                },
              ),
            ListTile(
              key: configuracoesKey,
              leading: Icon(Icons.settings, color: theme.iconTheme.color),
              title: Text(S.of(context).settings,
                  style: theme.textTheme.displayMedium),
              onTap: () {
                _navigateAndCloseDrawer(
                    context, const SettingsScreen(), '/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildBottomNavigationBar(
      BuildContext context, AppStateManager appStateManager, ThemeData theme) {
    if (widget.showBottomNavigationBar && widget.selectedIndex != null) {
      return BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, key: homeIconKey),
            label: S.of(context).home,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money, key: financeIconKey),
            label: S.of(context).finances,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.agriculture, key: agroIconKey),
            label: S.of(context).agro,
          ),
        ],
        currentIndex: widget.selectedIndex ?? 0,
        selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
        unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
        backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
        onTap: (index) {
          if (index == 1) {
            _showFinanceMenu(context, theme);
          } else if (index == 2) {
            _showAgroMenu(context, theme);
          } else {
            _onItemTapped(context, index);
          }
        },
      );
    }
    return null;
  }

  void _showAgroMenu(BuildContext context, ThemeData theme) {
    AppStateManager appStateManager =
        Provider.of<AppStateManager>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: <Widget>[
              if (appStateManager.canView('atividadesRurais') && (Modules.canAccessModule('atividadesRurais', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(CustomIcons.farming_time_bold,
                    S.of(context).rural_activities, () {
                  _navigateAndCloseDrawer(context, AtividadesRuraisListScreen(),
                      '/atividadesRuraisList');
                }, theme),
              if (appStateManager.canView('operacoesRurais') && (Modules.canAccessModule('operacoesRurais', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    CustomIcons.trator_operacao_2, S.of(context).rural_operations, () {
                  _navigateAndCloseDrawer(
                      context,
                      OperacoesRuraisListScreen(
                          atividadeId:
                              appStateManager.activeAtividadeRural?.id ?? ''),
                      '/atividadesRuraisList');
                }, theme),
              if (appStateManager.canView('tiposOperacoesRurais') && (Modules.canAccessModule('tiposOperacoesRurais', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    CustomIcons.trator_operacao, S.of(context).tipos_operacoes_rurais, () {
                  _navigateAndCloseDrawer(
                      context,
                      TiposOperacoesRuraisListScreen(),
                      '/tiposOperacoesRuraisList');
                }, theme),
              if (appStateManager.canView('frotas') && (Modules.canAccessModule('frotas', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    CustomIcons.trator_bonito, S.of(context).fleet, () {
                  _navigateAndCloseDrawer(
                      context,
                      FrotasListScreen(isSelectMode: false,),
                      '/frotasList');
                }, theme),
              if (appStateManager.canView('recomendacoesAdubacao') && (Modules.canAccessModule('recomendacoesAdubacao', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    Icons.analytics, S.of(context).soil_analysis, () {
                  _navigateAndCloseDrawer(
                      context,
                      ResultadosAnalisesSolosListScreen(isSelectMode: false,),
                      '/resultadosAnalisesSolosList');
                }, theme),
              if (appStateManager.canView('recomendacoesAdubacao') && (Modules.canAccessModule('recomendacoesAdubacao', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    Icons.cached, S.of(context).recommendation, () {
                  _navigateAndCloseDrawer(
                      context,
                      RecomendacoesListScreen(),
                      '/recomendacoesScreen');
                }, theme),
              if (appStateManager.canView('registrosColetas') && (Modules.canAccessModule('registrosColetas', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    CustomIcons.rubber_tapper, S.of(context).rubber_collections, () {
                  _navigateAndCloseDrawer(context, RegistrosColetasListScreen(),
                      '/registrosColetasList');
                }, theme),
              if (appStateManager.canView('registrosEntregas') && (Modules.canAccessModule('registrosEntregas', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    Icons.local_shipping, S.of(context).rubber_delivery, () {
                  _navigateAndCloseDrawer(context,
                      RegistrosEntregasListScreen(), '/registrosEntregasList');
                }, theme),
            ],
          ),
        );
      },
    );
  }

  void _showFinanceMenu(BuildContext context, ThemeData theme) {
    AppStateManager appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            children: <Widget>[
              if (appStateManager.canView('bancos'))
                _buildMenuItem(Icons.payment, S.of(context).accounts_payable, () {
                  _navigateAndCloseDrawer(context, ContasPagarListScreen(),
                      '/contasPagarList');
                }, theme),
              if (appStateManager.canView('compras'))
                _buildMenuItem(Icons.report, S.of(context).purchase_report, () {
                  _navigateAndCloseDrawer(context, RelatorioComprasScreen(),
                      '/relatorioComprasScreen');
                }, theme),
              if (appStateManager.canView('bancos'))
                _buildMenuItem(Icons.account_balance, S.of(context).banks_icon,
                        () {
                      _navigateAndCloseDrawer(
                          context, BancosListScreen(), '/bancosList');
                    }, theme),
              if (appStateManager.canView('contabil') && (Modules.canAccessModule('contabil', appStateManager.activeAtividadeRural?.tipo, appStateManager.activeAtividadeRural?.subtipo) || (appStateManager.activeAtividadeRural == null)))
                _buildMenuItem(
                    Icons.account_balance_wallet_outlined, S.of(context).accounting_entries, () {
                  _navigateAndCloseDrawer(context,
                      LancamentosContabeisListScreen(), '/lancamentosContabeisList');
                }, theme),

            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
      IconData icon, String label, Function() onTap, ThemeData theme) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 48, color: theme.iconTheme.color),
          SizedBox(height: 8),
          Text(label, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
