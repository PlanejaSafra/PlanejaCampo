import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/screens/appbar/propriedade_form_screen.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'dart:io';
import 'package:planejacampo/utils/validators.dart';

class PropriedadeScreen extends StatefulWidget {
  final Propriedade propriedade;

  const PropriedadeScreen({
    Key? key,
    required this.propriedade,
  }) : super(key: key);

  @override
  _PropriedadeScreenState createState() => _PropriedadeScreenState();
}

class _PropriedadeScreenState extends State<PropriedadeScreen> {
  final GlobalKey _addTalhaoKey = GlobalKey();
  final String _moduleName = 'propriedades';
  final PropriedadeService _propriedadeService = PropriedadeService();
  final TalhaoService _talhaoService = TalhaoService();
  late Future<Propriedade?> _futurePropriedade;
  late Future<List<Talhao>> _futureTalhoes;
  bool _showTutorial = false;
  late bool _canEdit;
  late bool _canDelete;
  late bool _canDeleteTalhao;
  late Propriedade _currentPropriedade;
  Object _returnObject = '';

  final GlobalKey _talhoesKey = GlobalKey();

  late TalhaoDialogScreen _talhaoDialogScreen;
  bool _isExpanded = false;

  // Definição das GlobalKeys para o primeiro talhão
  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstTalhaoEditKey = GlobalKey();
  final GlobalKey _firstTalhaoDeleteKey = GlobalKey();
  final GlobalKey _importTalhaoKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _currentPropriedade = widget.propriedade;
    _loadPropriedade();
    _checkPermissions();
    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: widget.propriedade.id,
      talhaoService: _talhaoService,
      canEdit: _canEdit,
      canDelete: _canDeleteTalhao,
      onUpdate: () {
        _returnObject = true;
        _loadPropriedade();
        setState(
                () {}); // Atualiza a tela quando um talhão é adicionado, editado ou removido
      },
      firstTalhaoMoreOptionsKey: _firstTalhaoMoreOptionsKey,
      firstTalhaoEditKey: _firstTalhaoEditKey,
      firstTalhaoDeleteKey: _firstTalhaoDeleteKey,
    );
    final AppStateManager appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('propriedadeScreen');
    appStateManager.setShowTutorial('propriedadeScreen', false);
  }

  void _loadPropriedade() async {
    setState(() {
      _futurePropriedade = _propriedadeService.getById(widget.propriedade.id);
      _futureTalhoes = _talhaoService.getByAttributes({'propriedadeId': widget.propriedade.id});
    });
  }

  void _checkPermissions() {
    final appStateManager =
    Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
      //print('propriedadeScreen - canEdit: $_canEdit, _canDelete: $_canDelete');
      _canDeleteTalhao = _canDelete;
      if (_canDelete) {
        if (widget.propriedade.id == appStateManager.activePropriedadeId) {
          _canDelete = false;
        }
      }
    });
  }

  void _navigateToFormScreen() {
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            PropriedadeFormScreen(propriedade: _currentPropriedade),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    )
        .then((updatedPropriedade) {
      if (updatedPropriedade != null) {
        setState(() {
          _returnObject = true;
          if (updatedPropriedade is Propriedade) {
            _currentPropriedade = updatedPropriedade;
          }
          _loadPropriedade(); // Recarrega os talhões para refletir as alterações
        });
        // Remova ou comente a linha abaixo
        // Navigator.of(context).pop(_returnObject);
      }
    });
  }



  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded; // Alterna o estado
    });
    return _isExpanded;
  }

  // Método de importação atualizado para atualizar talhões existentes ou adicionar novos
  Future<void> _importTalhoes(BuildContext context) async {
    try {
      // Abrir o seletor de arquivos para escolher KML/KMZ
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['kml', 'kmz'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String extension = result.files.single.extension!.toLowerCase();

        List<Talhao> importedTalhoes = [];

        if (extension == 'kmz') {
          // Descompactar KMZ para extrair o arquivo KML
          List<int> bytes = await File(filePath).readAsBytes();
          Archive archive = ZipDecoder().decodeBytes(bytes);
          for (var file in archive) {
            if (file.isFile && file.name.toLowerCase().endsWith('.kml')) {
              String kmlContent = String.fromCharCodes(file.content as List<int>);
              importedTalhoes.addAll(Validators().parseKml(_currentPropriedade, kmlContent));
            }
          }
        } else if (extension == 'kml') {
          // Ler o conteúdo do arquivo KML diretamente
          String kmlContent = await File(filePath).readAsString();
          importedTalhoes.addAll(Validators().parseKml(_currentPropriedade, kmlContent));
        }

        if (importedTalhoes.isNotEmpty) {
          // Recupera os talhões existentes para a propriedade atual
          List<Talhao> existingTalhoes = await _talhaoService.getByAttributes({
            'propriedadeId': _currentPropriedade.id,
          });

          // Cria um mapa para facilitar a busca por nome
          Map<String, Talhao> existingTalhoesMap = {
            for (var talhao in existingTalhoes) talhao.nome.toLowerCase(): talhao
          };

          // Itera sobre os talhões importados
          for (var importedTalhao in importedTalhoes) {
            String talhaoNomeKey = importedTalhao.nome.toLowerCase();

            if (existingTalhoesMap.containsKey(talhaoNomeKey)) {
              // Talhão existente encontrado, atualiza suas informações
              Talhao existingTalhao = existingTalhoesMap[talhaoNomeKey]!;

              // Atualiza as coordenadas e recalcula a área
              double novaArea = Validators().calculatePolygonArea(
                importedTalhao.coordenadas!.map((coord) => [coord['lat']!, coord['lon']!]).toList(),
              );

              Talhao updatedTalhao = existingTalhao.copyWith(
                coordenadas: importedTalhao.coordenadas,
                area: novaArea,
              );

              await _talhaoService.update(existingTalhao.id, updatedTalhao);
              print('Talhão atualizado: ${updatedTalhao.nome} com ID: ${updatedTalhao.id}');
            } else {
              // Talhão não existe, adiciona como novo
              await _talhaoService.add(importedTalhao);
              print('Talhão adicionado: ${importedTalhao.nome} com ID: ${importedTalhao.id}');
            }
          }

          // Atualizar a lista de talhões após a importação
          setState(() {
            _returnObject = true;
            _loadPropriedade(); // Recarrega os talhões para refletir as alterações
          });

          // Exibir mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).plots_imported_successfully(importedTalhoes.length)),
            ),
          );
        } else {
          // Exibir mensagem se nenhum talhão foi encontrado no arquivo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).no_plots_found_in_file)),
          );
        }
      }
    } catch (e) {
      // Exibir mensagem de erro em caso de falha na importação
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).error_importing_plots(e.toString()))),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_returnObject);
        return false; // Impede o comportamento padrão de pop
      },
      child: SingleScreenTemplate(
        title: S.of(context).property_details,
        moduleName: _moduleName,
        showTutorial: _showTutorial,
        nomeTutorial: S.of(context).agricultural_property,
        nomeTutorialPlural: S.of(context).agricultural_properties,
        returnObject: _returnObject,
        onWillPop: () async {
          return true; // Permite a navegação
        },
        canEdit: _canEdit,
        canDelete: _canDelete,
        onEditPressed: _canEdit ? () => _navigateToFormScreen() : null,
        summarySection: _buildSummarySection(),
        serviceName: _propriedadeService,
        itemIdValue: widget.propriedade.id,
        itemName: S.of(context).agricultural_properties,
        fieldReference: 'propriedadeId',
        cardSections: _buildTalhoesCards(),
        isExpanded: _isExpanded, // Passa o estado para o template
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: {
          'customTalhoes': {
            'key': _talhoesKey,
            'message': S.of(context).property_plots_listed,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          if (FormatacaoUtil.hasValidPosition(_firstTalhaoMoreOptionsKey))
            'moreOptionsButton': {
              'key': _firstTalhaoMoreOptionsKey,
              'message': S.of(context).click_to_see_more_options_on_first_plot,
              'shape': 'Circle',
              'align': 'ContentAlign.top',
              'hasMoreOptions': true,
            },
          /*
          'customFirstTalhaoEdit': {
            'key': _firstTalhaoEditKey,
            'message': S.of(context).click_to_edit_first_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
          'customFirstTalhaoDelete': {
            'key': _firstTalhaoDeleteKey,
            'message': S.of(context).click_to_delete_first_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
          */
        },
        customActionTutorialSteps: {
          'addTalhao': {
            'key': _addTalhaoKey,
            'message': S.of(context).add_plot,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
          'importTalhao': {
            'key': _importTalhaoKey, // Defina uma chave específica se desejar
            'message': S.of(context).import_plots,
            'shape': 'Circle',
            'align': 'ContentAlign.top',
          },
        },
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();
              // Contraia o botão principal
              bool? result = await _talhaoDialogScreen.addTalhao(context);
              if (result == true) {
                _returnObject = true;
                setState(() {}); // Força a reconstrução da tela para atualizar a lista de talhões
              }
            },
            icon: Icons.add,
            text: S.of(context).add_plot,
            key: _addTalhaoKey,
            heroTag: 'addTalhao',
          ),
          // Botão de Importação Adicionado
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();
              await _importTalhoes(context);
            },
            icon: Icons.upload_file,
            text: S.of(context).import_plots,
            key: _importTalhaoKey, // Utiliza a chave definida
            heroTag: 'importTalhao',
          ),
        ],
      ),
    );
  }


  Widget _buildSummarySection() {
    return FutureBuilder<Propriedade?>(
      future: _futurePropriedade,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final propriedade = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Utilizando InfoRow para cada campo com ícones
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.home_work, // Ícone representativo para Nome da Propriedade
                    label: S.of(context).name,
                    value: propriedade.nome,
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.area_chart, // Ícone representativo para Área
                    label: S.of(context).area,
                    value: '${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(propriedade.area)} ${S.of(context).hectares}',
                  ),
                  const SizedBox(height: 8),
                  ObjectTemplate.buildInfoRow(
                    context: context,
                    icon: Icons.sync_alt, // Ícone representativo para Modo de Movimentação
                    label: S.of(context).movement_mode,
                    value: propriedade.modoMovimentacaoEstoque,
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

/*
  List<CardSection> _buildTalhoesCards() {
    return [
      CardSection(
        key: _talhoesKey,
        title: S.of(context).plots,
        icon: CustomIcons.field, // Ícone representativo para Talhão
        cards: [
          FutureBuilder<List<Talhao>>(
            future: _futureTalhoes,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListTile(
                  leading: const CircularProgressIndicator(),
                  title: Text(S.of(context).loading),
                );
              } else if (snapshot.hasError) {
                return ListTile(
                  leading: Icon(Icons.error, color: Theme.of(context).colorScheme.error),
                  title: Text(S.of(context).error_loading),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return ListTile(
                  leading: Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                  title: Text(S.of(context).plot_not_found),
                );
              } else {
                return Column(
                  children: snapshot.data!.map((talhao) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: Icon(
                          CustomIcons.field, // Use um ícone adequado para Talhão
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          talhao.nome,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _talhaoDialogScreen.editTalhao(context, talhao);
                            } else if (value == 'delete') {
                              _talhaoDialogScreen.deleteTalhao(context, talhao);
                            }
                          },
                          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                            PopupMenuItem<String>(
                              value: 'edit',
                              child: Text(S.of(context).edit),
                            ),
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text(S.of(context).delete),
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
        ],
      ),
    ];
  }


  List<CardSection> _buildTalhoesCards() {
    return [
      CardSection(
        key: _talhoesKey,
        title: S.of(context).plots,
        cards: [
          FutureBuilder<List<Talhao>>(
            future: _futureTalhoes,
            builder: (context, snapshot) {
              return _talhaoDialogScreen.buildTalhoesCards(context, snapshot);
            },
          ),
        ],
      ),
    ];
  }

  */

  List<CardSection> _buildTalhoesCards() {
    return [
      ObjectTemplate.buildCardSectionWithFuture<Talhao>(
        key: _talhoesKey,
        title: S.of(context).plots,
        iconePrincipal: Icons.landscape,
        future: _futureTalhoes,
        itemTitle: (talhao) => talhao.nome,
        itemSubtitle: (talhao) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${S.of(context).area}: ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(talhao.area)} ${S.of(context).hectares}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );
        },
        onEdit: (talhao) => _talhaoDialogScreen.editTalhao(context, talhao),
        onDelete: (talhao) => _talhaoDialogScreen.deleteTalhao(context, talhao),
        itemLeadingIcon: CustomIcons.field,
        loadingText: S.of(context).loading,
        errorText: S.of(context).error_loading,
        notFoundText: S.of(context).plot_not_found,
        firstItemMoreOptionsKey: _firstTalhaoMoreOptionsKey, // Adicionando a chave aqui
      ),
    ];
  }



}
