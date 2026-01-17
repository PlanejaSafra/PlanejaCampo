import 'package:flutter/material.dart';
import 'package:planejacampo/models/atividade_rural.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/services/atividade_rural_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/list_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';
import 'package:planejacampo/screens/appbar/talhao_screen.dart';



class TalhoesListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;
  final List<Talhao>? initialSelectedTalhoes;
  final String? atividadeId;

  const TalhoesListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
    this.initialSelectedTalhoes,
    this.atividadeId,
  }) : super(key: key);

  @override
  _TalhoesListScreenState createState() => _TalhoesListScreenState();
}

class _TalhoesListScreenState extends State<TalhoesListScreen> {
  final String _moduleName = 'talhoes';
  final TalhaoService _talhaoService = TalhaoService();
  late Future<List<Talhao>> _talhoesFuture;
  bool _showTutorial = false;
  Object _returnObject = '';

  List<String> _selectedTalhoes = [];

  late TalhaoDialogScreen _talhaoDialogScreen;

  @override
  void initState() {
    super.initState();
    _talhoesFuture = _loadTalhoes();
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('talhoesListScreen');
    appStateManager.setShowTutorial('talhoesListScreen', false);

    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: appStateManager.activePropriedadeId,
      talhaoService: _talhaoService,
      canEdit: appStateManager.canEdit(_moduleName),
      canDelete: appStateManager.canDelete(_moduleName),
      onUpdate: _refreshTalhoes,
      firstTalhaoMoreOptionsKey: GlobalKey(),
      firstTalhaoEditKey: GlobalKey(),
      firstTalhaoDeleteKey: GlobalKey(),
      temporaryTalhoes: [],
    );

    if (widget.initialSelectedTalhoes != null) {
      _selectedTalhoes = widget.initialSelectedTalhoes!.map((t) => t.id).toList();
    }
    //print("entrou no initState de talhoesListScreen");
  }

  Future<List<Talhao>> _loadTalhoes() async {
    try {
      final appStateManager = Provider.of<AppStateManager>(context, listen: false);
      final AtividadeRuralService atividadeRuralService = AtividadeRuralService();

      if (widget.atividadeId != null) {
        // Buscar a atividade rural
        AtividadeRural? atividadeRural = await atividadeRuralService.getById(widget.atividadeId!);

        if (atividadeRural != null && atividadeRural.talhoes != null && atividadeRural.talhoes!.isNotEmpty) {
          // Buscar os talhões associados à atividade
          List<Talhao> talhoes = [];
          for (String talhaoId in atividadeRural.talhoes!) {
            Talhao? talhao = await _talhaoService.getById(talhaoId);
            if (talhao != null) {
              talhoes.add(talhao);
            }
          }
          return talhoes;
        } else {
          // Se não houver talhões associados à atividade, retornar uma lista vazia
          return [];
        }
      } else {
        // Se não houver atividadeId, buscar todos os talhões do produtor
        return await _talhaoService.getByProdutorId(
          appStateManager.activeProdutorId!,
        );
      }
    } catch (e) {
      print('Erro ao carregar talhões: $e');
      throw e;
    }
  }

  void _refreshTalhoes() {
    _returnObject = true;
    setState(() {
      _talhoesFuture = _loadTalhoes();
    });
  }

  Future<void> _addTalhao() async {
    final bool? result = await _talhaoDialogScreen.addTalhao(context);
    if (result != null && result) {
      _refreshTalhoes();
    }
  }

  Future<void> _editTalhao(Talhao talhao) async {
    final bool? result = await _talhaoDialogScreen.editTalhao(context, talhao);
    if (result != null && result) {
      _refreshTalhoes();
    }
  }

  void _navigateToViewTalhao(Talhao talhao) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TalhaoScreen(talhao: talhao)),
    );
    if (result != null && result != '') {
      _returnObject = result;
      if (result is! bool || result != false) {
        _refreshTalhoes();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSelectMode
            ? (widget.atividadeId != null
            ? S.of(context).select_talhao_from_activity
            : S.of(context).select_talhao)
            : S.of(context).plots),
      ),
      body: FutureBuilder<List<Talhao>>(
        future: _talhoesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(S.of(context).error_loading));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(S.of(context).not_found));
          } else {
            final talhoes = snapshot.data!;
            return Column(
              children: [
                if (widget.isSelectMode)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _selectedTalhoes.isNotEmpty
                          ? () {
                        final selectedTalhoes = talhoes.where((talhao) =>
                            _selectedTalhoes.contains(talhao.id)).toList();
                        Navigator.of(context).pop(selectedTalhoes);
                      }
                          : null,
                      child: Text(S.of(context).confirm_selection),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: talhoes.length,
                    itemBuilder: (context, index) {
                      final talhao = talhoes[index];
                      final isSelected = _selectedTalhoes.contains(talhao.id);

                      return Card(
                        child: ListTile(
                          leading: widget.isSelectMode
                              ? Checkbox(
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setState(() {
                                if (selected == true) {
                                  _selectedTalhoes.add(talhao.id);
                                } else {
                                  _selectedTalhoes.remove(talhao.id);
                                }
                              });
                            },
                          )
                              : null,
                          title: Text(talhao.nome),
                          subtitle: Text('${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}'),
                          trailing: widget.isSelectMode
                              ? null
                              : IconButton(
                            icon: Icon(Icons.arrow_forward_ios),
                            onPressed: () => _navigateToViewTalhao(talhao),
                            tooltip: S.of(context).view_details,
                          ),
                          onTap: () {
                            if (widget.isSelectMode) {
                              setState(() {
                                if (isSelected) {
                                  _selectedTalhoes.remove(talhao.id);
                                } else {
                                  _selectedTalhoes.add(talhao.id);
                                }
                              });
                            } else {
                              _navigateToViewTalhao(talhao);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: widget.isSelectMode
          ? null
          : FloatingActionButton(
        onPressed: _addTalhao,
        child: Icon(Icons.add),
        tooltip: S.of(context).add_plot,
      ),
    );
  }
}