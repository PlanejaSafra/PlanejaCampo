import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/talhao.dart'; // Importação adicional
import 'package:planejacampo/screens/agro/atividade_rural_form_screen.dart';
import 'package:planejacampo/screens/agro/atividade_rural_screen.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart'; // Importação adicional
import 'package:planejacampo/utils/atividade_rural_options.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:planejacampo/widgets/object_template.dart'; // Importação adicional
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class AtividadesRuraisListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const AtividadesRuraisListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _AtividadesRuraisListScreenState createState() => _AtividadesRuraisListScreenState();
}

class _AtividadesRuraisListScreenState extends State<AtividadesRuraisListScreen> {
  final String _moduleName = 'atividadesRurais';
  final AtividadeRuralService _atividadeRuralService = AtividadeRuralService();
  final TalhaoService _talhaoService = TalhaoService();
  late Future<List<AtividadeRural>> _atividadesFuture;
  Map<String, List<Talhao>> _talhoesMap = {};
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _atividadesFuture = _loadData();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('atividadesRuraisListScreen');
    appStateManager.setShowTutorial('atividadesRuraisListScreen', false);
  }

  Future<List<AtividadeRural>> _loadData() async {
    try {
      final String propriedadeId = Provider.of<AppStateManager>(context, listen: false).activePropriedadeId!;
      final atividades = await _atividadeRuralService.getByPropriedadeId(propriedadeId);

      // Carrega talhões para cada atividade
      for (var atividade in atividades) {
        if (atividade.talhoes != null && atividade.talhoes!.isNotEmpty) {
          final talhoes = await _talhaoService.getByIds(atividade.talhoes!);
          _talhoesMap[atividade.id] = talhoes;
        } else {
          _talhoesMap[atividade.id] = [];
        }
      }

      return atividades;
    } catch (e) {
      throw e;
    }
  }

  void _refreshAtividades() {
    _returnObject = true;
    setState(() {
      _talhoesMap.clear();
      _atividadesFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);

    return ListTemplate<AtividadeRural>(
      icon: CustomIcons.farming_time_bold,
      future: _atividadesFuture,
      serviceName: _atividadeRuralService,
      moduleName: _moduleName,
      title: widget.isSelectMode ? S.of(context).select_activity : S.of(context).rural_activities,
      itemTitleBuilder: (atividade) => atividade.nome,
      itemSubtitleBuilder: (atividade) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${S.of(context).type}: ${AtividadeRuralOptions.getLocalizedTiposAtividades(context)[atividade.tipo] ?? atividade.tipo}',
          ),
          Text(
            '${S.of(context).categoria}: ${AtividadeRuralOptions.getLocalizedSubtiposAtividades(context)[atividade.tipo]?.firstWhere(
                  (subtipo) => subtipo == atividade.subtipo,
              orElse: () => atividade.subtipo,
            ) ?? atividade.subtipo}',
          ),
          Text(
            '${S.of(context).start_date}: ${FormatacaoUtil.formatDate(atividade.dataInicio)}',
          ),
        ],
      ),
      itemExpandedContentWidgets: (atividade) {
        final List<Widget> widgets = [];
        final talhoes = _talhoesMap[atividade.id] ?? [];

        if (atividade.dataFim != null) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.event_busy, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('${S.of(context).end_date}: ${FormatacaoUtil.formatDate(atividade.dataFim!)}'),
                ],
              ),
            ),
          );
        }

        if (talhoes.isNotEmpty) {
          widgets.add(const SizedBox(height: 16));
          widgets.add(
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              child: Text(
                S.of(context).plots,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );

          widgets.addAll(
            talhoes.map((talhao) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(talhao.nome)),
                  Text(
                    '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ha',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList(),
          );
        }

        return widgets;
      },
      itemLeadingIcon: CustomIcons.farming_time_bold,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshAtividades,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).rural_activity,
      nomeTutorialPlural: S.of(context).rural_activities,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      onSetMode: (atividade) => appStateManager.setActiveAtividadeRural(atividade),
      viewScreenBuilder: (atividade) => AtividadeRuralScreen(atividadeRural: atividade!),
      formScreenBuilder: (atividade) => AtividadeRuralFormScreen(atividadeRural: atividade),
      onWillPop: () async {
        if (appStateManager.activeAtividadeRural == null) {
          _returnObject = false;
        }
        return true;
      },
    );
  }
}