import 'package:flutter/material.dart';
import 'package:planejacampo/models/registro_coleta.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_coleta_form_screen.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_coleta_screen.dart';
import 'package:planejacampo/services/registro_coleta_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class RegistrosColetasListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const RegistrosColetasListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _RegistrosColetasListScreenState createState() => _RegistrosColetasListScreenState();
}

class _RegistrosColetasListScreenState extends State<RegistrosColetasListScreen> {
  final String _moduleName = 'registrosColetas';
  final RegistroColetaService _registroColetaService = RegistroColetaService();
  late Future<List<RegistroColeta>> _registrosColetasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _registrosColetasFuture = _loadRegistros();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registrosColetasListScreen');
    appStateManager.setShowTutorial('registrosColetasListScreen', false);
  }

  Future<List<RegistroColeta>> _loadRegistros() async {
    try {
      return await _registroColetaService.getByPropriedadeId(
        Provider.of<AppStateManager>(context, listen: false).activePropriedadeId!,
      );
    } catch (e) {
      throw e;
    }
  }

  void _refreshRegistros() {
    _returnObject = true;
    setState(() {
      _registrosColetasFuture = _loadRegistros();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<RegistroColeta>(
      icon: Icons.assignment,
      future: _registrosColetasFuture,
      serviceName: _registroColetaService,
      itemTitleBuilder: (registro) =>
          FormatacaoUtil.formatDate(registro.dataColeta),
      itemSubtitleBuilder: (registro) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).quantity_boxes}: ${registro.quantidadeCaixa ?? 0}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${S.of(context).average_weight_box}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.pesoMedioCaixa ?? 0.0)} ${S.of(context).kilogram}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        );
      },
      moduleName: _moduleName,
      title: widget.isSelectMode
          ? S.of(context).select_collection_record
          : S.of(context).collection_records,
      customTutorialSteps: _buildCustomTutorialSteps(),
      errorText: S.of(context).error_loading_description(S.of(context).collection_records),
      formScreenBuilder: (registro) => RegistroColetaFormScreen(registroColeta: registro),
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemExpandedContentWidgets: (registro) => [
        Text(
          '${S.of(context).total_weight}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.pesoTotal ?? 0.0)} ${S.of(context).kilogram}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
      itemLeadingIcon: Icons.assignment,
      loadingText: S.of(context).loading,
      nomeTutorial: S.of(context).collection_record,
      nomeTutorialPlural: S.of(context).collection_records,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshRegistros,
      showTutorial: _showTutorial,
      viewScreenBuilder: (registro) => RegistroColetaScreen(registroColeta: registro!),
      onWillPop: () async => true,
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}