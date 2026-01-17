import 'package:flutter/material.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';

class TalhaoScreen extends StatefulWidget {
  final String? propriedadeId;
  final Talhao? talhao; // Adicionado

  const TalhaoScreen({
    Key? key,
    this.propriedadeId,
    this.talhao, // Adicionado
  }) : super(key: key);

  @override
  _TalhaoScreenState createState() => _TalhaoScreenState();
}

class _TalhaoScreenState extends State<TalhaoScreen> {
  final String _moduleName = 'talhoes';
  final TalhaoService _talhaoService = TalhaoService();
  late Future<List<Talhao>> _futureTalhoes;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  List<Talhao>? _temporaryTalhoes;
  Object _returnObject = '';

  final GlobalKey _talhoesKey = GlobalKey();

  // Chaves para o primeiro talhão (para tutorial)
  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstTalhaoEditKey = GlobalKey();
  final GlobalKey _firstTalhaoDeleteKey = GlobalKey();

  late TalhaoDialogScreen _talhaoDialogScreen;

  @override
  void initState() {
    super.initState();
    _loadTalhoes();
    _checkPermissions();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('talhaoScreen');
    appStateManager.setShowTutorial('talhaoScreen', false);
    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: widget.propriedadeId,
      talhaoService: _talhaoService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: _loadTalhoes,
      firstTalhaoMoreOptionsKey: _firstTalhaoMoreOptionsKey,
      firstTalhaoEditKey: _firstTalhaoEditKey,
      firstTalhaoDeleteKey: _firstTalhaoDeleteKey,
      temporaryTalhoes: _temporaryTalhoes,
    );
  }

  void _loadTalhoes() {
    setState(() {
      if (widget.propriedadeId == null || widget.propriedadeId!.isEmpty) {
        _futureTalhoes = Future.value(_temporaryTalhoes ?? []);
      } else {
        _futureTalhoes = _talhaoService.getByAttributes({'propriedadeId': widget.propriedadeId});
      }
    });
  }

  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  void _addTalhao() async {
    final bool? result = await _talhaoDialogScreen.addTalhao(context);
    if (result == true) {
      _loadTalhoes();
    }
  }

  void _editTalhao(Talhao talhao) async {
    final bool? result = await _talhaoDialogScreen.editTalhao(context, talhao);
    if (result == true) {
      _loadTalhoes();
    }
  }

  void _deleteTalhao(Talhao talhao) async {
    await _talhaoDialogScreen.deleteTalhao(context, talhao);
    _loadTalhoes();
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).talhao_details,
      moduleName: _moduleName,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).plot,
      nomeTutorialPlural: S.of(context).plots,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      onEditPressed: _canEdit ? _addTalhao : null,
      onDeletePressed: _canDelete ? () {} : null,
      summarySection: _buildSummarySection(),
      serviceName: _talhaoService,
      itemIdValue: widget.propriedadeId ?? '',
      itemName: S.of(context).plot,
      fieldReference: 'propriedadeId',
      cardSections: [
        CardSection(
          title: S.of(context).plots,
          key: _talhoesKey,
          cards: _buildTalhoesCards(),
        ),
      ],
      customTutorialSteps: {
        'plotsSection': {
          'key': _talhoesKey,
          'message': S.of(context).plots_section_description,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
      },
      onFloatingActionButtonPressed: _canEdit ? () { _addTalhao(); return true; } : null, // Alterado aqui
    );
  }

  Widget _buildSummarySection() {
    return Text(
      S.of(context).manage_your_plots,
      style: Theme.of(context).textTheme.headlineSmall, // Atualizado
    );
  }

  List<Widget> _buildTalhoesCards() {
    return [
      FutureBuilder<List<Talhao>>(
        future: _futureTalhoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(child: ListTile(title: Text(S.of(context).loading)));
          } else if (snapshot.hasError) {
            return Card(child: ListTile(title: Text(S.of(context).error_loading)));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Card(child: ListTile(title: Text(S.of(context).not_found)));
          } else {
            final List<Talhao> talhoes = snapshot.data!;
            return Column(
              children: talhoes.asMap().entries.map((entry) {
                final int index = entry.key;
                final Talhao talhao = entry.value;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ExpansionTile(
                    key: index == 0 ? _firstTalhaoMoreOptionsKey : null,
                    title: Text(
                      '${S.of(context).name}: ${talhao.nome}',
                      style: Theme.of(context).textTheme.bodyLarge, // Atualizado
                    ),
                    subtitle: Text(
                      '${S.of(context).area}: ${talhao.area} ha',
                      style: Theme.of(context).textTheme.bodyMedium, // Atualizado
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context).coordinates,
                              style: Theme.of(context).textTheme.titleMedium, // Atualizado
                            ),
                            const SizedBox(height: 4.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: talhao.coordenadas!.map((coord) {
                                return Text(
                                  '${S.of(context).latitude}: ${coord['lat']}, ${S.of(context).longitude}: ${coord['lon']}',
                                  style: Theme.of(context).textTheme.bodyMedium, // Atualizado
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == 'edit') {
                          _editTalhao(talhao);
                        } else if (result == 'delete') {
                          _deleteTalhao(talhao);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'edit',
                          key: index == 0 ? _firstTalhaoEditKey : null,
                          child: Text(
                            S.of(context).edit,
                            style: Theme.of(context).popupMenuTheme.textStyle,
                          ),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          key: index == 0 ? _firstTalhaoDeleteKey : null,
                          child: Text(
                            S.of(context).delete,
                            style: Theme.of(context).popupMenuTheme.textStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }
        },
      ),
    ];
  }
}
