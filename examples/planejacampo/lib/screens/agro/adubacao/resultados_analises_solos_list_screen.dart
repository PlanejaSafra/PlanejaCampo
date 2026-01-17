import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/resultado_analise_solo.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/screens/agro/adubacao/resultado_analise_solo_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/resultado_analise_solo_form_screen.dart';
import 'package:planejacampo/services/agro/adubacao/resultado_analise_solo_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class ResultadosAnalisesSolosListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const ResultadosAnalisesSolosListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _ResultadosAnalisesSolosListScreenState createState() => _ResultadosAnalisesSolosListScreenState();
}

class _ResultadosAnalisesSolosListScreenState extends State<ResultadosAnalisesSolosListScreen> {
  final String _moduleName = 'recomendacoesAdubacao';
  final ResultadoAnaliseSoloService _analiseSoloService = ResultadoAnaliseSoloService();
  final TalhaoService _talhaoService = TalhaoService();
  late Future<List<ResultadoAnaliseSolo>> _analisesFuture;
  Map<String, Talhao> _talhoesCache = {};
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _analisesFuture = _loadData();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('resultadosAnalisesSolosListScreen');
    appStateManager.setShowTutorial('resultadosAnalisesSolosListScreen', false);
  }

  Future<List<ResultadoAnaliseSolo>> _loadData() async {
    try {
      final String propriedadeId = Provider.of<AppStateManager>(context, listen: false).activePropriedadeId!;
      final analises = await _analiseSoloService.getByPropriedadeId(propriedadeId);

      // Carrega talhões para cada análise
      for (var analise in analises) {
        if (analise.talhoes != null && analise.talhoes!.isNotEmpty) {
          for (var talhaoId in analise.talhoes!) {
            if (!_talhoesCache.containsKey(talhaoId)) {
              final talhao = await _talhaoService.getById(talhaoId);
              if (talhao != null) {
                _talhoesCache[talhaoId] = talhao;
              }
            }
          }
        }
      }

      return analises;
    } catch (e) {
      throw e;
    }
  }


  void _refreshAnalises() {
    _returnObject = true;
    setState(() {
      _talhoesCache.clear();
      _analisesFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<ResultadoAnaliseSolo>(
      icon: Icons.analytics,
      future: _analisesFuture,
      serviceName: _analiseSoloService,
      moduleName: _moduleName,
      title: widget.isSelectMode ? S.of(context).select_soil_analysis : S.of(context).soil_analyses,
      itemTitleBuilder: (analise) {
        if (analise.talhoes == null || analise.talhoes!.isEmpty) {
          return S.of(context).not_found;
        }
        final nomes = analise.talhoes!
            .map((id) => _talhoesCache[id]?.nome ?? S.of(context).not_found)
            .where((nome) => nome != S.of(context).not_found)
            .join(', ');
        return nomes.isNotEmpty ? nomes : S.of(context).not_found;
      },
      itemSubtitleBuilder: (analise) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${S.of(context).laboratory}: ${analise.laboratorioId}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${S.of(context).collection_date}: ${FormatacaoUtil.formatDate(analise.dataColeta)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${S.of(context).analysis_date}: ${FormatacaoUtil.formatDate(analise.dataAnalise)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      itemExpandedContentWidgets: (analise) {
        return [
          Text(
            '${S.of(context).ph_cacl2}: ${analise.pH.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            '${S.of(context).cation_exchange_capacity}: ${(analise.calcio + analise.magnesio + analise.potassio + analise.al + analise.hAl).toStringAsFixed(2)} cmolc/dm³',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (analise.profundidadeAmostra != null)
            Text(
              '${S.of(context).sample_depth}: ${analise.profundidadeAmostra}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          if (analise.metodologiaExtracao.isNotEmpty)
            Text(
              '${S.of(context).extraction_methodology}: ${analise.metodologiaExtracao}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ];
      },
      itemLeadingIcon: Icons.analytics,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_soil_analysis_found,
      onRefresh: _refreshAnalises,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).soil_analysis,
      nomeTutorialPlural: S.of(context).soil_analyses,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      viewScreenBuilder: (analise) => ResultadoAnaliseSoloScreen(resultadoAnaliseSolo: analise!),
      formScreenBuilder: (analise) => ResultadoAnaliseSoloFormScreen(resultadoAnaliseSolo: analise),
      onWillPop: () async => true,
    );
  }
}