import 'package:flutter/material.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/screens/appbar/propriedade_form_screen.dart';
import 'package:planejacampo/screens/appbar/propriedade_screen.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/propriedade_options.dart';

class PropriedadesListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const PropriedadesListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _PropriedadesListScreenState createState() => _PropriedadesListScreenState();
}

class _PropriedadesListScreenState extends State<PropriedadesListScreen> {
  final String _moduleName = 'propriedades';
  final PropriedadeService _propriedadeService = PropriedadeService();
  final TalhaoService _talhaoService = TalhaoService();
  late Future<Map<String, List<Talhao>>> _propriedadesETalhoesFuture;
  Object _returnObject = false;
  bool _showTutorial = false;
  bool _isSnackBarVisible = false;

  @override
  void initState() {
    super.initState();
    _propriedadesETalhoesFuture = _loadPropriedadesETalhoes();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('propriedadesListScreen');
    appStateManager.setShowTutorial('propriedadesListScreen', false);
  }

  Future<Map<String, List<Talhao>>> _loadPropriedadesETalhoes() async {
    try {
      final Map<String, List<Talhao>> talhoesMap = {};
      final propriedades = await _propriedadeService.getByProdutorId(
        Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
      );

      for (var propriedade in propriedades) {
        final talhoes = await _talhaoService.getByPropriedadeId(propriedade.id);
        talhoesMap[propriedade.id] = talhoes;
      }

      return talhoesMap;
    } catch (e) {
      throw e;
    }
  }

  void _refreshPropriedades() {
    _returnObject = true;
    setState(() {
      _propriedadesETalhoesFuture = _loadPropriedadesETalhoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);

    return FutureBuilder<Map<String, List<Talhao>>>(
      future: _propriedadesETalhoesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        }

        final talhoesMap = snapshot.data ?? {};

        return ListTemplate<Propriedade>(
          icon: Icons.home_work,
          future: _propriedadeService.getByProdutorId(
            appStateManager.activeProdutorId!,
          ),
          serviceName: _propriedadeService,
          itemTitleBuilder: (propriedade) => propriedade.nome,
          itemSubtitleBuilder: (propriedade) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(propriedade.area)} ${S.of(context).hectares}',
              ),
              Text(
                '${S.of(context).movement_mode}: ${PropriedadeOptions.getLocalizedModoMovimentacaoEstoque(context)[propriedade.modoMovimentacaoEstoque] ?? propriedade.modoMovimentacaoEstoque}',
              ),
            ],
          ),
          moduleName: _moduleName,
          title: widget.isSelectMode ? S.of(context).select_property : S.of(context).agricultural_properties,
          customTutorialSteps: _buildCustomTutorialSteps(),
          errorText: S.of(context).error_loading,
          formScreenBuilder: (propriedade) => PropriedadeFormScreen(propriedade: propriedade),
          isSelectMode: widget.isSelectMode,
          isSetMode: widget.isSetMode,
          itemExpandedContentWidgets: (propriedade) {
            final List<Widget> widgets = [];
            final talhoes = talhoesMap[propriedade.id] ?? [];

            if (talhoes.isNotEmpty) {
              widgets.add(const SizedBox(height: 16));
              widgets.add(
                ObjectTemplate.buildCardSection(
                  CardSection(
                    title: S.of(context).plots,
                    icon: Icons.landscape,
                    cards: talhoes.map((talhao) {
                      return ListTile(
                        title: Text(
                          talhao.nome,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        subtitle: Text(
                          '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }).toList(),
                  ),
                  Theme.of(context),
                ),
              );
            }

            return widgets;
          },
          itemLeadingIcon: Icons.home_work,
          loadingText: S.of(context).loading,
          nomeTutorial: S.of(context).agricultural_property,
          nomeTutorialPlural: S.of(context).agricultural_properties,
          notFoundText: S.of(context).not_found,
          onRefresh: _refreshPropriedades,
          onSetMode: (propriedade) => appStateManager.setActivePropriedade(propriedade),

          showTutorial: _showTutorial,
          viewScreenBuilder: (propriedade) => PropriedadeScreen(propriedade: propriedade!),
          onWillPop: () async {
            if (appStateManager.activePropriedadeId == null) {
              if (!_isSnackBarVisible) {
                _isSnackBarVisible = true;
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).select_or_register_property),
                    duration: Duration(seconds: 2),
                  ),
                )
                    .closed
                    .then((reason) {
                  _isSnackBarVisible = false;
                });
              }
              _returnObject = false;
              return false;
            }
            _returnObject = false;
            return true;
          },
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}