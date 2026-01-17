import 'package:flutter/material.dart';
import 'package:planejacampo/models/registro_entrega.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_entrega_form_screen.dart';
import 'package:planejacampo/screens/agro/silvicultura/registro_entrega_screen.dart';
import 'package:planejacampo/services/registro_entrega_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class RegistrosEntregasListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const RegistrosEntregasListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _RegistrosEntregasListScreenState createState() => _RegistrosEntregasListScreenState();
}

class _RegistrosEntregasListScreenState extends State<RegistrosEntregasListScreen> {
  final String _moduleName = 'registrosEntregas';
  final RegistroEntregaService _registroEntregaService = RegistroEntregaService();
  late Future<List<RegistroEntrega>> _registrosEntregasFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _registrosEntregasFuture = _registroEntregaService.getAll();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registrosEntregasListScreen');
    appStateManager.setShowTutorial('registrosEntregasListScreen', false);
  }

  void _refreshRegistros() {
    _returnObject = true;
    setState(() {
      _registrosEntregasFuture = _registroEntregaService.getAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTemplate<RegistroEntrega>(
      icon: Icons.local_shipping,
      future: _registrosEntregasFuture,
      serviceName: _registroEntregaService,
      itemTitleBuilder: (registro) =>
      '${S.of(context).delivery_date}: ${FormatacaoUtil.formatDate(registro.dataEntrega)}',
      itemSubtitleBuilder: (registro) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${S.of(context).quantity_boxes}: ${registro.quantidadeCaixas}'),
          Text('${S.of(context).total_weight_delivery}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.pesoTotalEntrega)} ${S.of(context).kilogram}'),
        ],
      ),
      moduleName: _moduleName,
      title: S.of(context).delivery_records,
      customTutorialSteps: _buildCustomTutorialSteps(),
      errorText: S.of(context).error_loading,
      formScreenBuilder: (registro) => RegistroEntregaFormScreen(registroEntrega: registro),
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemExpandedContentWidgets: (registro) => [
        Text('${S.of(context).producer_weight}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.pesoProdutor)} ${S.of(context).kilogram}'),
        if (registro.valorNegociadoPorKg != null)
          Text('${S.of(context).negotiated_value_per_kg}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.valorNegociadoPorKg!)}'),
        if (registro.valorProdutor != null)
          Text('${S.of(context).producer_value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.valorProdutor!)}'),
        if (registro.dataPrevistaRecebimento != null)
          Text('${S.of(context).expected_receipt_date}: ${FormatacaoUtil.formatDate(registro.dataPrevistaRecebimento!)}'),
        if (registro.quantidadeJaRecebida != null)
          Text('${S.of(context).quantity_already_received}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.quantidadeJaRecebida!)}'),
      ],
      itemLeadingIcon: Icons.local_shipping,
      loadingText: S.of(context).loading,
      nomeTutorial: S.of(context).delivery_record,
      nomeTutorialPlural: S.of(context).delivery_records,
      notFoundText: S.of(context).not_found,
      onRefresh: _refreshRegistros,
      showTutorial: _showTutorial,
      viewScreenBuilder: (registro) => RegistroEntregaScreen(registroEntrega: registro!),
      onWillPop: () async => true,
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}