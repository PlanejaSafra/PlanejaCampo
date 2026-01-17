// banco_form_screen.dart
import 'package:flutter/material.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/screens/finances/conta_dialog_screen.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/utils/estados_options.dart'; // Importando EstadosOptions

class BancoFormScreen extends StatefulWidget {
  final Banco? banco;

  const BancoFormScreen({Key? key, this.banco}) : super(key: key);

  @override
  _BancoFormScreenState createState() => _BancoFormScreenState();
}

class _BancoFormScreenState extends State<BancoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Banco _currentBanco;
  late TextEditingController _nomeController;
  // Removendo o controlador de texto para siglaPaisController
  // late TextEditingController _siglaPaisController;
  late TextEditingController _enderecoController;
  late TextEditingController _telefoneController;
  late TextEditingController _contatoController;
  late ContaService _contaService;
  late BancoService _bancoService;
  final GlobalKey _bancoFormKey = GlobalKey();
  final GlobalKey _addContaKey = GlobalKey();
  final String moduleName = 'bancos';
  bool _hasChanges = false;
  bool _canEdit = false;
  bool _canDelete = false;
  bool _showTutorial = false;
  bool _isExpanded = false;
  Object _returnObject = false;

  late ContaDialogScreen _contaDialogScreen;
  List<Conta> _temporaryContas = [];

  // Variável para armazenar a sigla do país selecionado
  String? _selectedCountrySigla;

  final GlobalKey _contasKey = GlobalKey();
  final GlobalKey _firstContaMoreOptionsKey = GlobalKey();
  final GlobalKey _firstContaEditKey = GlobalKey();
  final GlobalKey _firstContaDeleteKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = appStateManager.canEdit(moduleName);
    _canDelete = appStateManager.canDelete(moduleName);

    _showTutorial = appStateManager.showTutorial('bancoFormScreen');
    appStateManager.setShowTutorial('bancoFormScreen', false);

    _bancoService = BancoService();
    _contaService = ContaService();
    _currentBanco = widget.banco ??
        Banco(
          id: DateTime.now().toString(),
          nome: '',
          siglaPais: '',
          produtorId: appStateManager.activeProdutorId ?? '',
        );

    if (widget.banco == null) {
      _temporaryContas = [];
    } else {
      // Load existing contas from the database if editing an existing banco
      _loadExistingContas();
    }

    _contaDialogScreen = ContaDialogScreen(
      bancoId: _currentBanco.id,
      contaService: _contaService,
      canEdit: _canEdit,
      canDelete: _canDelete,
      onUpdate: () {
        _returnObject = true;
        setState(() {});
      },
      contasKey: _contasKey,
      firstContaMoreOptionsKey: _firstContaMoreOptionsKey,
      firstContaEditKey: _firstContaEditKey,
      firstContaDeleteKey: _firstContaDeleteKey,
      temporaryContas: _temporaryContas,
    );

    _nomeController = TextEditingController(text: _currentBanco.nome);
    // Removendo o controlador de texto para siglaPaisController
    // _siglaPaisController = TextEditingController(text: _currentBanco.siglaPais);
    _enderecoController = TextEditingController(text: _currentBanco.endereco);
    _telefoneController = TextEditingController(text: _currentBanco.telefone);
    _contatoController = TextEditingController(text: _currentBanco.contato);

    // Inicializando a seleção do país com base no banco atual (se existir)
    if (_currentBanco.siglaPais.isNotEmpty) {
      _selectedCountrySigla = _currentBanco.siglaPais;
    }
  }

  Future<void> _loadExistingContas() async {
    // Load existing contas from the database
    List<Conta> existingContas = await _contaService.getByAttributes({'bancoId': _currentBanco.id});
    setState(() {
      _temporaryContas = existingContas;
    });
  }

  Future<void> _saveBanco() async {
    if (_canEdit) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        if (widget.banco == null) {
          // Save the bank and get the new ID
          final newBancoId = await _bancoService.add(_currentBanco, returnId: true);

          // Update the _currentBanco with the new ID
          _currentBanco = _currentBanco.copyWith(id: newBancoId);

          // Save the temporary contas to the database
          for (Conta conta in _temporaryContas) {
            Conta newConta = conta.copyWith(
              bancoId: newBancoId,
              produtorId: _currentBanco.produtorId,
            );
            await _contaService.add(newConta);
          }
        } else {
          await _bancoService.update(_currentBanco.id, _currentBanco);

          // Update contas
          for (Conta conta in _temporaryContas) {
            if (conta.id.startsWith('temp_')) {
              // New conta
              Conta newConta = conta.copyWith(
                bancoId: _currentBanco.id,
                produtorId: _currentBanco.produtorId,
              );
              await _contaService.add(newConta);
            } else {
              // Existing conta
              await _contaService.update(conta.id, conta);
            }
          }
        }
        _returnObject = widget.banco == null ? true : _currentBanco;
        Navigator.of(context).pop(_returnObject);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_save(S.of(context).bank)),
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

  // Substitua o método _buildContasSection() existente por este:
  Widget _buildContasSection() {
    return _contaDialogScreen.buildContasSection(context);
  }

  Future<void> _addConta() async {
    _toggleFloatingActionButton();
    bool? result = await _contaDialogScreen.addConta(context);
    if (result == true) {
      _returnObject = true;
      setState(() {});
    }
  }

  Future<void> _editConta(Conta conta) async {
    bool? result = await _contaDialogScreen.editConta(context, conta);
    if (result == true) {
      _returnObject = true;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obter a lista de países localizados
    final Map<String, String> paisesMap = EstadosOptions.getLocalizedPaises(context);

    // Mapear a lista de países para DropdownMenuItems
    final List<DropdownMenuItem<String>> paisesDropdownItems = EstadosOptions.paises.map((pais) {
      String nomeLocalizado = paisesMap[pais['nome']!] ?? pais['nome']!;
      return DropdownMenuItem<String>(
        value: pais['sigla']!,
        child: Text(nomeLocalizado),
      );
    }).toList();

    return FormTemplate(
      title: widget.banco == null ? S.of(context).add_bank : S.of(context).edit_bank,
      formKey: _formKey,
      onSave: _saveBanco,
      moduleName: moduleName,
      additionalFloatingActionButtons: (BuildContext context) => [
        ObjectTemplate.buildCustomFloatingActionButton(
          context: context,
          onPressed: () async {
            await _addConta();
          },
          icon: Icons.add,
          text: S.of(context).add_account,
          key: _addContaKey,
          heroTag: 'addConta',
        ),
      ],
      isNewItem: widget.banco == null,
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: {
        'customBancoForm': {
          'key': _bancoFormKey,
          'message': S.of(context).edit_bank_info,
          'shape': 'RRect',
          'align': 'ContentAlign.bottom',
        },
        'customContasCardKey': {
          'key': _contasKey,
          'message': S.of(context).manage_accounts_info,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
        'customContaMoreOptionsKey': {
          'key': _firstContaMoreOptionsKey,
          'message': S.of(context).manage_accounts_info,
          'align': 'ContentAlign.top',
        },
      },
      customActionTutorialSteps: {
        'addConta': {
          'key': _addContaKey,
          'message': S.of(context).click_to_add_account,
        },
      },
      returnObject: _returnObject,
      onWillPop: () async {
        Navigator.of(context).pop(_hasChanges ? true : _currentBanco);
        return false;
      },
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                key: _bancoFormKey,
                children: [
                  // Campo para Nome do Banco
                  TextFormField(
                    controller: _nomeController,
                    decoration: ObjectTemplate.getInputDecoration(context, S.of(context).name),
                    style: Theme.of(context).textTheme.bodyMedium,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return S.of(context).enter_bank_name;
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _currentBanco = _currentBanco.copyWith(nome: value ?? '');
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // ** Substituindo o TextFormField de siglaPais por DropdownButtonFormField **
                  ObjectTemplate.getDropdownButtonFormField(
                    context: context,
                    labelText: S.of(context).country,
                    value: _selectedCountrySigla,
                    dropdownItems: paisesDropdownItems,
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedCountrySigla = newValue;
                        _currentBanco = _currentBanco.copyWith(siglaPais: newValue ?? '');
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return S.of(context).select_country;
                      }
                      return null;
                    },
                    onSaved: (value) {
                      _currentBanco = _currentBanco.copyWith(siglaPais: value ?? '');
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Campo para Endereço
                  TextFormField(
                    controller: _enderecoController,
                    decoration: ObjectTemplate.getInputDecoration(context, S.of(context).address),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onSaved: (value) {
                      _currentBanco = _currentBanco.copyWith(endereco: value);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Campo para Telefone
                  TextFormField(
                    controller: _telefoneController,
                    decoration: ObjectTemplate.getInputDecoration(context, S.of(context).phone),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onSaved: (value) {
                      _currentBanco = _currentBanco.copyWith(telefone: value);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Campo para Contato
                  TextFormField(
                    controller: _contatoController,
                    decoration: ObjectTemplate.getInputDecoration(context, S.of(context).contact),
                    style: Theme.of(context).textTheme.bodyMedium,
                    onSaved: (value) {
                      _currentBanco = _currentBanco.copyWith(contato: value);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),
            _buildContasSection(),
          ],
        ),
      ),
    );
  }
}
