import 'package:flutter/material.dart';
import 'package:planejacampo/icons/custom_icons.dart';
import 'package:planejacampo/models/propriedade.dart';
import 'package:planejacampo/models/talhao.dart';
import 'package:planejacampo/services/propriedade_service.dart';
import 'package:planejacampo/services/talhao_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/utils/propriedade_options.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:flutter/services.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/screens/appbar/talhao_dialog_screen.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'dart:io';
import 'package:planejacampo/utils/validators.dart';


class PropriedadeFormScreen extends StatefulWidget {
  final Propriedade? propriedade;

  const PropriedadeFormScreen({Key? key, this.propriedade}) : super(key: key);

  @override
  _PropriedadeFormScreenState createState() => _PropriedadeFormScreenState();
}

class _PropriedadeFormScreenState extends State<PropriedadeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Propriedade _currentPropriedade;
  late TextEditingController _nomeController;
  late TextEditingController _areaController;
  late TalhaoService _talhaoService;
  late PropriedadeService _propriedadeService;
  final GlobalKey _propriedadeFormKey = GlobalKey();
  final GlobalKey _modoMovimentacaoEstoqueKey = GlobalKey();
  final GlobalKey _talhoesKey = GlobalKey();
  final GlobalKey _addTalhaoKey = GlobalKey();
  final moduleName = 'propriedades';
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;
  bool _canChooseAuto = false;
  List<String> _allowedModoMovimentacaoEstoqueOptions = ['Desativado'];
  bool _canCreateMorePropriedades = false;  // Adicionar esta linha junto aos outros controles booleanos

  late TalhaoDialogScreen _talhaoDialogScreen;
  List<Talhao> _temporaryTalhoes = [];

  late Future<List<Talhao>> _futureTalhoes;

  // Definição das GlobalKeys para o primeiro talhão
  final GlobalKey _firstTalhaoMoreOptionsKey = GlobalKey();
  final GlobalKey _firstTalhaoEditKey = GlobalKey();
  final GlobalKey _firstTalhaoDeleteKey = GlobalKey();
  final GlobalKey _importTalhaoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit(moduleName);
    _canDelete = appStateManager.canDelete(moduleName);
    _canCreateMorePropriedades = appStateManager.canCreateMorePropriedades;
    _showTutorial = appStateManager.showTutorial('propriedadeFormScreen');
    appStateManager.setShowTutorial('propriedadeFormScreen', false);

    // Usar os métodos implementados no AppStateManager
    _allowedModoMovimentacaoEstoqueOptions = appStateManager.getAllowedModoMovimentacaoEstoqueOptions();
    
    _propriedadeService = PropriedadeService();
    _currentPropriedade = widget.propriedade ??
        Propriedade(
          id: DateTime.now().toString(),
          produtorId: appStateManager.activeProdutorId!,
          nome: '',
          area: 0.0,
          modoMovimentacaoEstoque: 'Desativado',
        );
    
    // Verificar se o modo atual é permitido para a licença
    if (!appStateManager.isModoMovimentacaoEstoqueAllowed(_currentPropriedade.modoMovimentacaoEstoque)) {
      _currentPropriedade = _currentPropriedade.copyWith(modoMovimentacaoEstoque: 'Desativado');
      _hasChanges = true;
    }
    
    // Determinar se pode usar modo Auto
    _canChooseAuto = appStateManager.isModoMovimentacaoEstoqueAllowed('Auto');
  

    _talhaoService = TalhaoService();

    _nomeController = TextEditingController(text: _currentPropriedade.nome);
    _areaController = FormatacaoUtil.getMaskedTextController(_currentPropriedade.area);

    if (widget.propriedade == null) {
      _temporaryTalhoes = [];
      _futureTalhoes = Future.value(_temporaryTalhoes);
    } else {
      _loadTalhoes();
    }

    // Determinar as opções de movimentação de estoque com base na licença
    _determineModoMovimentacaoEstoqueOptions(appStateManager);

    _talhaoDialogScreen = TalhaoDialogScreen(
      propriedadeId: widget.propriedade?.id,
      talhaoService: _talhaoService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: () {
        _returnObject = true;
        _loadTalhoes();
        setState(() {}); // Atualiza a tela quando um talhão é adicionado, editado ou removido
      },
      temporaryTalhoes: _temporaryTalhoes,
      firstTalhaoMoreOptionsKey: _firstTalhaoMoreOptionsKey,
      firstTalhaoEditKey: _firstTalhaoEditKey,
      firstTalhaoDeleteKey: _firstTalhaoDeleteKey,
    );
  }

  void _determineModoMovimentacaoEstoqueOptions(AppStateManager appStateManager) {
    final activeProdutor = appStateManager.activeProdutor;

    bool hasAdminLicense = false;
    bool hasOtherLicense = false;

    if (activeProdutor != null && activeProdutor.licencas != null) {
      for (var licenca in activeProdutor.licencas!) {
        String tipoLicenca = licenca['tipo'] ?? 'AcessoBasico';
        if (ProdutorService().isLicencaValida(activeProdutor, tipoLicenca)) {
          if (tipoLicenca == 'Admin') {
            hasAdminLicense = true;
            break; // Admin tem todas as permissões, não precisa verificar mais
          } else if (tipoLicenca != 'AcessoBasico') {
            hasOtherLicense = true;
          }
        }
      }
    }

    // Obtém todas as opções possíveis
    List<String> todasOpcoes = PropriedadeOptions.modoMovimentacaoEstoque;

    if (hasAdminLicense) {
      _allowedModoMovimentacaoEstoqueOptions = List.from(todasOpcoes);
    } else if (hasOtherLicense) {
      // Exclui 'Auto' das opções
      _allowedModoMovimentacaoEstoqueOptions = todasOpcoes.where((opcao) => opcao != 'Auto').toList();
    } else {
      // Apenas 'Desativado' está disponível
      _allowedModoMovimentacaoEstoqueOptions = ['Desativado'];
    }

    // Atualiza a propriedade atual se não estiver nas opções permitidas
    if (!_allowedModoMovimentacaoEstoqueOptions.contains(_currentPropriedade.modoMovimentacaoEstoque)) {
      _currentPropriedade = _currentPropriedade.copyWith(modoMovimentacaoEstoque: 'Desativado');
      _hasChanges = true; // Indica que houve mudanças
    }

    // Atualiza a flag para controlar a exibição do campo
    _canChooseAuto = hasAdminLicense;

  }


  void _loadTalhoes() {
    if (widget.propriedade != null) {
      _futureTalhoes = _talhaoService
          .getByAttributes({'propriedadeId': widget.propriedade!.id}).then((existingTalhoes) {
        return existingTalhoes + _temporaryTalhoes;
      });
    } else {
      _futureTalhoes = Future.value(_temporaryTalhoes);
    }
  }


  Future<void> _savePropriedade() async {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canCreateMorePropriedades = await appStateManager.checkCanCreateMorePropriedades();

    if (_canEdit && _canCreateMorePropriedades) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        try {
          if (widget.propriedade == null) {
            // Adiciona nova propriedade
            final newPropriedadeId = await _propriedadeService.add(_currentPropriedade, returnId: true);
            _currentPropriedade = _currentPropriedade.copyWith(id: newPropriedadeId);
            print('Propriedade adicionada com ID: $newPropriedadeId');

            // Adiciona cada talhão importado
            for (Talhao talhao in _temporaryTalhoes) {
              Talhao newTalhao = talhao.copyWith(
                propriedadeId: newPropriedadeId,
                produtorId: _currentPropriedade.produtorId,
              );
              await _talhaoService.add(newTalhao);
              print('Talhão adicionado: ${newTalhao.nome} com ID: ${newTalhao.id}');
            }
          } else {
            // Atualiza propriedade existente
            await _propriedadeService.update(_currentPropriedade.id, _currentPropriedade);
            print('Propriedade atualizada com ID: ${_currentPropriedade.id}');

            // Adiciona cada talhão importado
            for (Talhao talhao in _temporaryTalhoes) {
              Talhao newTalhao = talhao.copyWith(
                propriedadeId: _currentPropriedade.id,
                produtorId: _currentPropriedade.produtorId,
              );
              await _talhaoService.add(newTalhao);
              print('Talhão adicionado: ${newTalhao.nome} com ID: ${newTalhao.id}');
            }
          }

          // Define o objeto de retorno
          _returnObject = widget.propriedade == null ? true : _currentPropriedade;

          if (!mounted) return; // Verifica se o widget ainda está montado
          Navigator.of(context).pop(_returnObject);
        } catch (e) {
          print('Erro ao salvar propriedade: $e');
          if (!mounted) return; // Verifica se o widget ainda está montado
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_property(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (!mounted) return; // Verifica se o widget ainda está montado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_or_edit(
              _canCreateMorePropriedades ?
              S.of(context).agricultural_property :
              S.of(context).no_more_properties_allowed
          )),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }





  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
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
          // Recupera os talhões existentes na lista temporária
          Map<String, Talhao> existingTalhoesMap = {
            for (var talhao in _temporaryTalhoes) talhao.nome.toLowerCase(): talhao
          };

          for (var importedTalhao in importedTalhoes) {
            String talhaoNomeKey = importedTalhao.nome.toLowerCase();

            if (existingTalhoesMap.containsKey(talhaoNomeKey)) {
              // Talhão existente encontrado, atualiza suas informações
              Talhao existingTalhao = existingTalhoesMap[talhaoNomeKey]!;

              // Calcula a nova área a partir das coordenadas importadas
              double novaArea = Validators().calculatePolygonArea(
                importedTalhao.coordenadas!.map((coord) => [coord['lat']!, coord['lon']!]).toList(),
              );

              // Cria uma nova instância de Talhao com as informações atualizadas
              Talhao updatedTalhao = existingTalhao.copyWith(
                coordenadas: importedTalhao.coordenadas,
                area: novaArea,
              );

              // Substitui o talhão existente na lista temporária
              int index = _temporaryTalhoes.indexWhere(
                    (talhao) => talhao.nome.toLowerCase() == talhaoNomeKey,
              );
              if (index != -1) {
                _temporaryTalhoes[index] = updatedTalhao;
                print('Talhão atualizado: ${updatedTalhao.nome} com ID: ${updatedTalhao.id}');
              }
            } else {
              // Talhão não existe, adiciona como novo
              _temporaryTalhoes.add(importedTalhao);
              print('Talhão adicionado: ${importedTalhao.nome} com ID: ${importedTalhao.id}');
            }
          }

          setState(() {
            _hasChanges = true; // Indica que houve mudanças
          });

          // Atualizar a lista de talhões após a importação
          _loadTalhoes();

          // Exibir mensagem de sucesso com a quantidade de talhões importados
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
    final theme = Theme.of(context);
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? true : _currentPropriedade);
        return false;
      },
      child: FormTemplate(
        title: widget.propriedade == null ? S.of(context).add_agricultural_property : S.of(context).edit_agricultural_property,
        formKey: _formKey,
        onSave: _savePropriedade,
        moduleName: moduleName,
        additionalFloatingActionButtons: (BuildContext context) => [
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () async {
              _toggleFloatingActionButton();
              bool? result = await _talhaoDialogScreen.addTalhao(context);
              if (result == true) {
                _returnObject = true;
                setState(() {});
              }
            },
            icon: Icons.add,
            text: S.of(context).add_plot,
            key: _addTalhaoKey,
            heroTag: 'addTalhao',
          ),
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
        isNewItem: widget.propriedade == null,
        canEdit: _canEdit,
        canDelete: _canDelete,
        showTutorial: _showTutorial,
        isExpanded: _isExpanded,
        onFloatingActionButtonPressed: _toggleFloatingActionButton,
        customTutorialSteps: {
          'customPropriedadeForm': {
            'key': _propriedadeFormKey,
            'message': S.of(context).edit_agricultural_property_info,
            'shape': 'RRect',
            'align': 'ContentAlign.bottom',
          },
          'customModoMovimentacaoEstoque': {
            'key': _modoMovimentacaoEstoqueKey,
            'message': S.of(context).movement_mode_description,
            'shape': 'RRect',
            'align': 'ContentAlign.bottom',
          },
          'customTalhoes': {
            'key': _talhoesKey,
            'message': S.of(context).manage_plots_info,
            'shape': 'RRect',
            'align': 'ContentAlign.top',
          },
          'customFirstTalhaoMoreOptions': {
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
        returnObject: _returnObject,
        onWillPop: () async {
          return true;
        },
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seção Identificação
                Row(
                  children: [
                    Icon(Icons.business, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).identification,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Nome
                TextFormField(
                  controller: _nomeController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).name,
                    suffixIcon: Icon(Icons.edit),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return S.of(context).enter_property_name;
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _currentPropriedade = _currentPropriedade.copyWith(nome: value ?? '');
                  },
                ),
                SizedBox(height: 16),

                // Área
                TextFormField(
                  controller: _areaController,
                  decoration: ObjectTemplate.getInputDecoration(
                    context,
                    S.of(context).area_ha,
                    suffixIcon: Icon(Icons.straighten),
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return S.of(context).enter_property_area;
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _currentPropriedade = _currentPropriedade.copyWith(
                      area: FormatacaoUtil.instance.parseNumber(value ?? '') ?? 0.0,
                    );
                  },
                ),
                SizedBox(height: 24),

                // Seção Configurações
                Row(
                  children: [
                    Icon(Icons.settings, color: theme.colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      S.of(context).settings,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Modo de Movimentação
                ObjectTemplate.getDropdownButtonFormField(
                  context: context,
                  labelText: S.of(context).movement_mode,
                  value: _currentPropriedade.modoMovimentacaoEstoque,
                  dropdownItems: _allowedModoMovimentacaoEstoqueOptions.map((key) =>
                      DropdownMenuItem<String>(
                        value: key,
                        child: Text(PropriedadeOptions.getLocalizedModoMovimentacaoEstoque(context)[key]!),
                      )
                  ).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _currentPropriedade = _currentPropriedade.copyWith(
                        modoMovimentacaoEstoque: newValue ?? 'Desativado',
                      );
                      _hasChanges = true;
                    });
                  },
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
        cardSections: _buildTalhoesCards(),
      ),
    );
  }

  /*
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
  // Defina o método _buildTalhoesCards utilizando o ObjectTemplate
  List<CardSection> _buildTalhoesCards() {
    return [
      ObjectTemplate.buildCardSectionWithFuture<Talhao>(
        key: _talhoesKey,
        title: S.of(context).plots,
        iconePrincipal: Icons.landscape, // Ícone representativo para Talhão
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
        itemLeadingIcon: CustomIcons.field, // Opcional, pode ser omitido
        loadingText: S.of(context).loading,
        errorText: S.of(context).error_loading,
        notFoundText: S.of(context).plot_not_found,
      ),
    ];
  }
}