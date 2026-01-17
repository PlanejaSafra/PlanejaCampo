import 'package:flutter/material.dart';
import 'package:planejacampo/models/tipo_operacao_rural.dart';
import 'package:planejacampo/screens/agro/tipo_operacao_rural_form_screen.dart';
import 'package:planejacampo/screens/agro/tipo_operacao_rural_screen.dart';
import 'package:planejacampo/services/tipo_operacao_rural_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';

class TiposOperacoesRuraisListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const TiposOperacoesRuraisListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _TiposOperacoesRuraisListScreenState createState() => _TiposOperacoesRuraisListScreenState();
}

class _TiposOperacoesRuraisListScreenState extends State<TiposOperacoesRuraisListScreen> {
  final String _moduleName = 'tiposOperacoesRurais';
  final TipoOperacaoRuralService _tipoOperacaoRuralService = TipoOperacaoRuralService();
  late Future<List<TipoOperacaoRural>> _tiposFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _tiposFuture = _loadTiposOperacoes();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('tiposOperacoesRuraisListScreen');
    appStateManager.setShowTutorial('tiposOperacoesRuraisListScreen', false);
  }

  Future<List<TipoOperacaoRural>> _loadTiposOperacoes() async {
    try {
      List<TipoOperacaoRural> tipos = await _tipoOperacaoRuralService.getByAttributes({
        'siglaPais': Provider.of<AppStateManager>(context, listen: false).appLocale.countryCode
      });
      tipos.sort((a, b) => a.nome.compareTo(b.nome));
      return tipos;
    } catch (e) {
      throw e;
    }
  }

  void _refreshTipos() {
    _returnObject = true;
    setState(() {
      _tiposFuture = _loadTiposOperacoes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<TipoOperacaoRural>(
      icon: Icons.category,
      future: _tiposFuture,
      serviceName: _tipoOperacaoRuralService,
      itemTitleBuilder: (tipo) => tipo.nome,
      itemSubtitleBuilder: (tipo) => Text(tipo.descricao),
      moduleName: _moduleName,
      title: widget.isSelectMode ? S.of(context).select_operation_type : S.of(context).tipos_operacoes_rurais,
      customTutorialSteps: _buildCustomTutorialSteps(),
      errorText: S.of(context).error_loading,
      formScreenBuilder: (tipo) => TipoOperacaoRuralFormScreen(tipoOperacaoRural: tipo),
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemLeadingIcon: Icons.build,
      loadingText: S.of(context).loading,
      nomeTutorial: S.of(context).tipo_operacao_rural,
      nomeTutorialPlural: S.of(context).tipos_operacoes_rurais,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshTipos,
      showTutorial: _showTutorial,
      viewScreenBuilder: (tipo) => TipoOperacaoRuralScreen(tipoOperacaoRural: tipo!),
      onWillPop: () async => true,
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}