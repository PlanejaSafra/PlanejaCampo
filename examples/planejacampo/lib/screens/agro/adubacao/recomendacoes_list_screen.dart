import 'package:flutter/material.dart';
import 'package:planejacampo/models/agro/adubacao/recomendacao.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_screen.dart';
import 'package:planejacampo/screens/agro/adubacao/recomendacao_generator_screen.dart';
import 'package:planejacampo/services/agro/adubacao/recomendacao_service.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/enums.dart';

class RecomendacoesListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const RecomendacoesListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _RecomendacoesListScreenState createState() => _RecomendacoesListScreenState();
}

class _RecomendacoesListScreenState extends State<RecomendacoesListScreen> {
  final String _moduleName = 'recomendacoesAdubacao';
  final RecomendacaoService _recomendacaoService = RecomendacaoService();
  late Future<List<Recomendacao>> _recomendacoesFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _recomendacoesFuture = _loadRecomendacoes();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('recomendacoesListScreen');
    appStateManager.setShowTutorial('recomendacoesListScreen', false);
  }

  Future<List<Recomendacao>> _loadRecomendacoes() async {
    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      final produtorId = appStateManager.activeProdutorId;
      if (produtorId == null) return [];

      return await _recomendacaoService.getByProdutorId(produtorId);
    } catch (e) {
      print('Erro ao carregar recomendações: $e');
      throw e;
    }
  }

  void _refreshRecomendacoes() {
    _returnObject = true;
    setState(() {
      _recomendacoesFuture = _loadRecomendacoes();
    });
  }

  String _formatDateRange(Recomendacao recomendacao) {
    return '${FormatacaoUtil.formatDate(recomendacao.dataRecomendacao)}';
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Recomendacao>(
      icon: Icons.science,
      future: _recomendacoesFuture,
      serviceName: _recomendacaoService,
      moduleName: _moduleName,
      title: S.of(context).fertilization_recommendations,
      itemTitleBuilder: (recomendacao) => _getTitleForRecomendacao(recomendacao),
      itemSubtitleBuilder: (recomendacao) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).date}: ${_formatDateRange(recomendacao)}'),
          Text('${S.of(context).crop_type}: ${recomendacao.tipoCultura.getLocalizedName(context)}'),
        ],
      ),
      itemExpandedContentWidgets: (recomendacao) => [
        Text('${S.of(context).expected_yield}: ${recomendacao.produtividadeEsperada.toStringAsFixed(1)} t/ha'),
        Text('${S.of(context).cultivation_system}: ${recomendacao.sistemaCultivo.getLocalizedName(context)}'),
        Text('${S.of(context).soil_texture}: ${recomendacao.texturaSolo.getLocalizedName(context)}'),
        Text('${S.of(context).irrigated}: ${recomendacao.irrigado ? S.of(context).yes : S.of(context).no}'),
        if (recomendacao.observacoes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              Text('${S.of(context).observations}:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...recomendacao.observacoes.map((obs) => Text('• $obs')).toList(),
            ],
          ),
      ],
      itemLeadingIcon: Icons.analytics,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshRecomendacoes,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).recommendation,
      nomeTutorialPlural: S.of(context).fertilization_recommendations,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      viewScreenBuilder: (recomendacao) => RecomendacaoScreen(recomendacao: recomendacao!),
      formScreenBuilder: (recomendacao) => RecomendacaoGeneratorScreen(), // Sempre cria uma nova
      onWillPop: () async => true,
    );
  }

  String _getTitleForRecomendacao(Recomendacao recomendacao) {
    // Composição do título com informações relevantes
    return '${recomendacao.tipoCultura.getLocalizedName(context)} - ${FormatacaoUtil.formatDate(recomendacao.dataPlantio)}';
  }
}