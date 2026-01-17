import 'package:flutter/material.dart';
import 'package:planejacampo/models/registro_chuva.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/screens/appbar/registro_chuva_form_screen.dart';
import 'package:planejacampo/screens/appbar/registro_chuva_screen.dart';
import 'package:planejacampo/services/registro_chuva_service.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class RegistrosChuvasListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;

  const RegistrosChuvasListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
  }) : super(key: key);

  @override
  _RegistrosChuvasListScreenState createState() => _RegistrosChuvasListScreenState();
}

class _RegistrosChuvasListScreenState extends State<RegistrosChuvasListScreen> {
  final String _moduleName = 'registrosChuvas';
  final RegistroChuvaService _registroChuvaService = RegistroChuvaService();
  final PropriedadeService _propriedadeService = PropriedadeService();
  late Future<Map<String, Propriedade>> _registrosEPropriedadesFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _registrosEPropriedadesFuture = _loadRegistrosEPropriedades();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('registrosChuvasListScreen');
    appStateManager.setShowTutorial('registrosChuvasListScreen', false);
  }

  Future<Map<String, Propriedade>> _loadRegistrosEPropriedades() async {
    try {
      final Map<String, Propriedade> propriedadesMap = {};
      final registros = await _registroChuvaService.getByProdutorId(
        Provider.of<AppStateManager>(context, listen: false).activeProdutorId!,
      );

      for (var registro in registros) {
        if (registro.propriedadeId.isNotEmpty) {
          final propriedade = await _propriedadeService.getById(registro.propriedadeId);
          if (propriedade != null) {
            propriedadesMap[registro.id] = propriedade;
          }
        }
      }

      return propriedadesMap;
    } catch (e) {
      throw e;
    }
  }

  Future<List<RegistroChuva>> _getRegistrosOrdenados() async {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final registros = await _registroChuvaService.getByProdutorId(
      appStateManager.activeProdutorId!,
    );

    registros.sort((a, b) => b.data.compareTo(a.data));

    return registros;
  }

  void _refreshRegistros() {
    _returnObject = true;
    setState(() {
      _registrosEPropriedadesFuture = _loadRegistrosEPropriedades();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appStateManager = Provider.of<AppStateManager>(context);

    return FutureBuilder<Map<String, Propriedade>>(
      future: _registrosEPropriedadesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        }

        final propriedadesMap = snapshot.data ?? {};

        return ListTemplate<RegistroChuva>(
          icon: Icons.water_drop,
          future: _getRegistrosOrdenados(),
          serviceName: _registroChuvaService,
          itemTitleBuilder: (registro) {
            final propriedade = propriedadesMap[registro.id];
            return propriedade?.nome ?? S.of(context).unknown_property;
          },
          itemSubtitleBuilder: (registro) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).date}: ${FormatacaoUtil.formatDate(registro.data)}',
              ),
              Text(
                '${S.of(context).rain_quantity}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(registro.quantidade)} mm',
              ),
            ],
          ),
          moduleName: _moduleName,
          title: widget.isSelectMode ? S.of(context).click_to_select_rain_record : S.of(context).rain_records,
          customTutorialSteps: _buildCustomTutorialSteps(),
          errorText: S.of(context).error_loading,
          formScreenBuilder: (registro) => RegistroChuvaFormScreen(registroChuva: registro),
          isSelectMode: widget.isSelectMode,
          isSetMode: widget.isSetMode,
          itemLeadingIcon: Icons.water_drop,
          loadingText: S.of(context).loading,
          nomeTutorial: S.of(context).rain_record,
          nomeTutorialPlural: S.of(context).rain_records,
          notFoundText: S.of(context).not_found,
          onRefresh: _refreshRegistros,
          showTutorial: _showTutorial,
          viewScreenBuilder: (registro) => RegistroChuvaScreen(registroChuva: registro!),
          onWillPop: () async => true,
        );
      },
    );
  }

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {};
  }
}