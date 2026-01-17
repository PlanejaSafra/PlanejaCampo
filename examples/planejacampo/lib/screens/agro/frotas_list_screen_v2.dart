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
  /*
  void _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FrotaFormScreen()),
    );
    if (result != null && result != '') {
      _returnObject = result;
      if (result is! bool || result != false) {
        _refreshFrotas();
      }
    }
  }


  Future<void> _confirmDelete(Frota frota) async {
    await DialogScreen.confirmDelete(
      context,
      serviceName: _frotaService,
      itemIdValue: frota.id,
      itemName: S.of(context).fleet,
      onSuccessDialog: () {
        Navigator.of(context).pop(true);
        _refreshFrotas();
      },
    );
  }

  void _navigateToViewScreen(Frota frota) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FrotaScreen(frota: frota)),
    );
    if (result != null && result != '') {
      _returnObject = result;
      if (result is! bool || result != false) {
        _refreshFrotas();
      }
    }
  }

  void _navigateToFormScreen(Frota frota) {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FrotaFormScreen(frota: frota),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((updatedFrota) {
      if (updatedFrota != null) {
        _returnObject = true;
        _refreshFrotas();
      }
    });
  }
  */

  @override
  Widget build(BuildContext context) {
    return ListTemplate<Frota>(
      icon: Icons.directions_car,
      future: _frotasFuture,
      serviceName: _frotaService,
      itemTitleBuilder: (frota) => frota.nome,
      itemSubtitleBuilder: (frota) => Text(
        '${S.of(context).type}: ${FrotaOptions.getLocalizedTiposFrota(context)[frota.tipo] ?? frota.tipo}',
        //style: Theme.of(context).textTheme.bodyMedium,
      ),
      moduleName: _moduleName,
      title: S.of(context).fleets,
      customTutorialSteps: _buildCustomTutorialSteps(),
      errorText: S.of(context).error_loading,
      formScreenBuilder: (frota) => FrotaFormScreen(frota: frota),
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      itemExpandedContentWidgets: (frota) => [
        if (frota.modelo != null) Text('${S.of(context).model}: ${frota.modelo}'),
        if (frota.anoFabricacao != null) Text('${S.of(context).years}: ${frota.anoFabricacao}'),
        if (frota.valor != null) Text('${S.of(context).value}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.valor!)}'),
        if (frota.horimetroOdometro != null) Text('${S.of(context).odometer}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(frota.horimetroOdometro!)}'),
        if (frota.vidaUtil != null) Text('${S.of(context).useful_life}: ${frota.vidaUtil} ${S.of(context).years}'),
        if (frota.dataAquisicao != null) Text('${S.of(context).acquisition_date}: ${FormatacaoUtil.formatDate(frota.dataAquisicao!)}'),
        if (frota.observacoes != null) Text('${S.of(context).observations}: ${frota.observacoes}'),
        if (frota.identificador != null) Text('${S.of(context).identifier}: ${frota.identificador}'),
      ],
      itemLeadingIcon: Icons.directions_car,
      loadingText: S.of(context).loading,
      nomeTutorial: 'Frotas',
      nomeTutorialPlural: 'Frotas',
      notFoundText: S.of(context).not_found,
      //onTap: (frota) => _navigateToViewScreen(frota),
      //onEdit: (frota) => _navigateToFormScreen(frota),
      //onDelete: (frota) => _confirmDelete(frota),
      //onSetMode: widget.isSetMode ? (frota) => _navigateToFormScreen(frota) : null,
      //onAddPressed: _navigateToAdd,
      //onHelpPressed: widget.isSelectMode ? null : () {}, // Ajuste conforme necessário
      //showDeleteButton: widget.isSelectMode,
      //onDeletePressed: widget.isSelectMode ? () {} : null, // Ajuste conforme necessário
      onRefresh: _refreshFrotas,
      showTutorial: _showTutorial,
      viewScreenBuilder: (frota) => FrotaScreen(frota: frota!),
      onWillPop: () async => true,
    );
  }


  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    // Implemente conforme a lógica necessária
    return {};
  }
}
