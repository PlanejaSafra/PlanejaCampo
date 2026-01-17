import 'package:flutter/material.dart';
import 'package:flutter/src/services/text_formatter.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/pessoa_options.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:planejacampo/utils/validators.dart'; // Importando Validators
import 'package:planejacampo/l10n/l10n.dart'; // Importando L10n
import 'package:planejacampo/utils/formatacao_util.dart';


class PessoaFormScreen extends StatefulWidget {
  final Pessoa? pessoa;

  const PessoaFormScreen({super.key, this.pessoa});

  @override
  _PessoaFormScreenState createState() => _PessoaFormScreenState();
}

class _PessoaFormScreenState extends State<PessoaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final GlobalKey _detailFormKey = GlobalKey();
  late Pessoa _currentPessoa;
  late TextEditingController _nomeController;
  late TextEditingController _documentoController;
  late TextEditingController _telefoneController;
  late TextEditingController _emailController;
  late TextEditingController _enderecoController;
  late TextEditingController _notasController;
  late String _selectedTipo;
  late String _selectedVinculo;
  late PessoaService _pessoaService;
  bool _showTutorial = false;
  Object _returnObject = false;

  final _cpfMaskFormatter = MaskTextInputFormatter(mask: '###.###.###-##', filter: { "#": RegExp(r'[0-9]') });
  final _cnpjMaskFormatter = MaskTextInputFormatter(mask: '##.###.###/####-##', filter: { "#": RegExp(r'[0-9]') });

  @override
  void initState() {
    super.initState();
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final produtorId = Provider.of<AppStateManager>(context, listen: false).activeProdutor!.id;
    _pessoaService = PessoaService();
    _currentPessoa = widget.pessoa ?? Pessoa(
      id: '',
      produtorId: produtorId,
      nome: '',
      vinculo: PessoaOptions.vinculos[0],
      tipo: PessoaOptions.tipos[0],
      documento: '',
      telefone: '',
      email: '',
      endereco: '',
      notas: '',
    );
    _nomeController = TextEditingController(text: _currentPessoa.nome);
    _documentoController = TextEditingController(text: _currentPessoa.documento);
    _telefoneController = TextEditingController(text: _currentPessoa.telefone);
    _emailController = TextEditingController(text: _currentPessoa.email);
    _enderecoController = TextEditingController(text: _currentPessoa.endereco);
    _notasController = TextEditingController(text: _currentPessoa.notas);
    _selectedTipo = _currentPessoa.tipo ?? PessoaOptions.tipos[0];
    _selectedVinculo = _currentPessoa.vinculo ?? PessoaOptions.vinculos[0];

    _showTutorial = appStateManager.showTutorial('pessoaFormScreen');
    appStateManager.setShowTutorial('pessoaFormScreen', false);
  }

  void _savePessoa() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_currentPessoa.id.isEmpty) {
        await _pessoaService.add(_currentPessoa);
      } else {
        await _pessoaService.update(_currentPessoa.id, _currentPessoa);
      }
      if (widget.pessoa == null) {
        _returnObject = true;
      } else {
        _returnObject = _currentPessoa;
      }
      Navigator.of(context).pop(_returnObject);

      if (!mounted) return;
      //Provider.of<AppStateManager>(context, listen: false).notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormTemplate(
      title: widget.pessoa == null ? S.of(context).add_person : S.of(context).edit_person,  // Internacionalizado
      //showDeleteButton: widget.pessoa != null,
      /*
      onDeletePressed: () async {
        if (widget.pessoa != null) {
          await _pessoaService.delete(widget.pessoa!.id);
          Navigator.pop(context);
        }
      },
      */
      formKey: _formKey,
      onSave: _savePessoa,
      moduleName: 'pessoas',
      nomeTutorial: S.of(context).person,
      showTutorial: _showTutorial, // Adicionado
      customTutorialSteps: {
        'essoaForm': {
          'key': _detailFormKey,
          'message': S.of(context).click_to_edit(S.of(context).person),
          'shape': 'Circle',
          'align': 'ContentAlign.botton',
          'shape': 'RRect',
          'fatorReducaoQuadro': 0.6,
        },
      },
      returnObject: _returnObject,
      onWillPop: () async {
        return true; // Permite a navegação
      },
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            key: _detailFormKey,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seção de Identificação
              Row(
                children: [
                  Icon(Icons.person, color: theme.colorScheme.primary),
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
                    return S.of(context).enter_name;
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(nome: value ?? '');
                },
              ),
              SizedBox(height: 16),

              // Vínculo
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).relationship,
                value: _selectedVinculo,
                dropdownItems: PessoaOptions.getLocalizedVinculos(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedVinculo = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).select_relationship;
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    _currentPessoa = _currentPessoa.copyWith(vinculo: value);
                  }
                },
                suffixIcon: Icon(Icons.people_outline),
              ),
              SizedBox(height: 16),

              // Tipo
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).type,
                value: _selectedTipo,
                dropdownItems: PessoaOptions.getLocalizedTipos(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTipo = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).select_type;
                  }
                  return null;
                },
                onSaved: (value) {
                  if (value != null) {
                    _currentPessoa = _currentPessoa.copyWith(tipo: value);
                  }
                },
                suffixIcon: Icon(Icons.category),
              ),
              SizedBox(height: 16),

              // Documento
              TextFormField(
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  _selectedTipo == 'Pessoa Física' ? S.of(context).cpf : S.of(context).cnpj,
                  suffixIcon: Icon(Icons.badge),
                ),
                controller: _documentoController,
                inputFormatters: [
                  FormatacaoUtil.getDocumentoMaskFormatter(
                      _selectedTipo,
                      Localizations.localeOf(context).toLanguageTag()
                  ),
                ],
                validator: (value) {
                  if (_selectedTipo == 'Pessoa Física' && value!.isNotEmpty && !Validators.isValidCPF(value)) {
                    return S.of(context).invalid_cpf;
                  } else if (_selectedTipo == 'Pessoa Jurídica' && value!.isNotEmpty && !Validators.isValidCNPJ(value)) {
                    return S.of(context).invalid_cnpj;
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(documento: value ?? '');
                },
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 24),

              // Seção de Contato
              Row(
                children: [
                  Icon(Icons.contacts, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).contact,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Telefone
              TextFormField(
                controller: _telefoneController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).phone,
                  suffixIcon: Icon(Icons.phone),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(telefone: value ?? '');
                },
              ),
              SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).email,
                  suffixIcon: Icon(Icons.email),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(email: value ?? '');
                },
              ),
              SizedBox(height: 24),

              // Seção de Localização
              Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).details,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Endereço
              TextFormField(
                controller: _enderecoController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).address,
                  suffixIcon: Icon(Icons.home),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(endereco: value ?? '');
                },
              ),
              SizedBox(height: 16),

              // Notas
              TextFormField(
                controller: _notasController,
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  S.of(context).notes,
                  suffixIcon: Icon(Icons.note),
                ),
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                onSaved: (value) {
                  _currentPessoa = _currentPessoa.copyWith(notas: value ?? '');
                },
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}