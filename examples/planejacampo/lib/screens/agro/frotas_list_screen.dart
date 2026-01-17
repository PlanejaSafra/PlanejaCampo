import 'package:flutter/material.dart';
import 'package:planejacampo/models/frota.dart';
import 'package:planejacampo/screens/agro/frota_form_screen.dart';
import 'package:planejacampo/screens/agro/frota_screen.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/services/frota_service.dart';
import 'package:planejacampo/utils/frota_options.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class FrotasListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const FrotasListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _FrotasListScreenState createState() => _FrotasListScreenState();
}

class _FrotasListScreenState extends State<FrotasListScreen> {
  final String _moduleName = 'frotas';
  final FrotaService _frotaService = FrotaService();
  late Future<List<Frota>> _frotasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;
  //final GlobalKey _firstItemMoreOptionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _frotasFuture = _loadFrota();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('frotasListScreen');
    appStateManager.setShowTutorial('frotasListScreen', false);
  }

  Future<List<Frota>> _loadFrota() async {
    try {
      final frotas = await _frotaService.getByPropriedadeId(
        Provider.of<AppStateManager>(context, listen: false).activePropriedadeId!,
      );
      return frotas;
    } catch (e) {
      throw e;
    }
  }

  void _refreshFrotas() {
    _returnObject = true;
    setState(() {
      _frotasFuture = _loadFrota();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Frota>(
      icon: Icons.directions_car,
      future: _frotasFuture,
      serviceName: _frotaService,
      moduleName: _moduleName,
      title: S.of(context).fleets,
      itemTitleBuilder: (frota) => frota.nome,
      itemSubtitleBuilder: (frota) => Text(
        '${S.of(context).type}: ${FrotaOptions.getLocalizedTiposFrota(context)[frota.tipo] ?? frota.tipo}',
      ),
      itemExpandedContentWidgets: (frota) => [
        if (frota.modelo != null)
          Text('${S.of(context).model}: ${frota.modelo}'),
        if (frota.anoFabricacao != null)
          Text('${S.of(context).years}: ${frota.anoFabricacao}'),
        if (frota.valor != null)
          Text('${S.of(context).value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.valor!)}'),
        if (frota.horimetroOdometro != null)
          Text('${S.of(context).odometer}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horimetroOdometro!)}'),
        if (frota.vidaUtil != null)
          Text('${S.of(context).useful_life}: ${frota.vidaUtil} ${S.of(context).years}'),
        if (frota.dataAquisicao != null)
          Text('${S.of(context).acquisition_date}: ${FormatacaoUtil.formatDate(frota.dataAquisicao!)}'),
        if (frota.observacoes != null)
          Text('${S.of(context).observations}: ${frota.observacoes}'),
        if (frota.identificador != null)
          Text('${S.of(context).identifier}: ${frota.identificador}'),
      ],
      itemLeadingIcon: Icons.directions_car,
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshFrotas,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).fleet,
      nomeTutorialPlural: S.of(context).fleets,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      viewScreenBuilder: (frota) => FrotaScreen(frota: frota!),
      formScreenBuilder: (frota) => FrotaFormScreen(frota: frota),
      onWillPop: () async => true,
    );
  }


  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    // Implemente conforme a lógica necessária
    return {};
  }
}
