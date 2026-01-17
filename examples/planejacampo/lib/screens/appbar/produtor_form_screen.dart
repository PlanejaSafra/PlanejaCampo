import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:planejacampo/models/produtor.dart';
import 'package:planejacampo/services/produtor_service.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/utils/produtor_options.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/utils/formatacao_util.dart';

class ProdutorFormScreen extends StatefulWidget {
  final Produtor? produtor;

  const ProdutorFormScreen({super.key, this.produtor});

  @override
  _ProdutorFormScreenState createState() => _ProdutorFormScreenState();
}

class _ProdutorFormScreenState extends State<ProdutorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Produtor _currentProdutor;
  late String _selectedType;
  late TextEditingController _nomeController;
  late ProdutorService _produtorService;
  late bool _canEditPermissions;
  final GlobalKey _produtorFormKey = GlobalKey();
  final GlobalKey _permissionsKey = GlobalKey();
  final GlobalKey _addPermissionKey = GlobalKey();
  Object _returnObject = '';

  bool _isInitialized = false;

  bool _showTutorial = false;

  bool _canEdit = false;
  bool _canDelete = false;
  bool _canCreateMoreProdutores = false;

  String? _currentUserEmail;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _produtorService = ProdutorService();
    _nomeController = TextEditingController();
    _canEditPermissions = false; // Valor padrão inicial

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canEdit = widget.produtor == null || appStateManager.canEditProdutor(widget.produtor!);
    _canDelete = widget.produtor == null || appStateManager.canDeleteProdutor(widget.produtor!);
    _canCreateMoreProdutores = appStateManager.canCreateMoreProdutores;
    _currentUserEmail = appStateManager.currentUserEmail;

    _showTutorial = appStateManager.showTutorial('produtorFormScreen');
    appStateManager.setShowTutorial('produtorFormScreen', false);

    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_isInitialized) {
      _currentProdutor = widget.produtor ??
          Produtor(
            id: DateTime.now().toString(),
            nome: '',
            status: ProdutorOptions.getLocalizedStatus(context).entries.firstWhere((entry) => entry.value == S.of(context).active).key,
            tipo: ProdutorOptions.getLocalizedTipo(context).entries.firstWhere((entry) => entry.value == S.of(context).individual).key,
            documento: '',
            permissoes: [],
            criadorId: AppStateManager().currentUserId,
            // licencas é composto por tipo, que por padrão é 'AcessoBasico', e dataExpiracao, que por padrão é nulo.
            licencas: [
              {
                'tipo': 'AcessoBasico',
                'dataExpiracao': null // Licença sem data de expiração
              }
            ],
          );
      _selectedType = _currentProdutor.tipo;
      _nomeController.text = _currentProdutor.nome;
      _isInitialized = true;
    }
  }

  void _checkPermissions() {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    final String? userRole = appStateManager.currentUserRole;

    // Verifica se o usuário tem permissão de editar baseado na role
    if (userRole == null) {
      _canEditPermissions = true;
    } else {
      _canEditPermissions = userRole == 'Admin' || userRole == 'Produtor' || userRole == 'Gerente';
    }
  }

  @override
  Future<void> _confirmDelete(BuildContext context) async {
    if (_canDelete) {
      final hasRelatedData = await ProdutorService().hasRelatedData(_currentProdutor.id);
      if (hasRelatedData) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.of(context).confirm_deletion),
            content: Text(S.of(context).confirm_deletion_message_exists_properties),
            actions: [
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(S.of(context).delete),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirm ?? false) {
          final doubleConfirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(S.of(context).confirm_deletion),
              content: Text(S.of(context).confirm_final_deletion_message_producer),
              actions: [
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).confirm_final_deletion_message_producer),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ],
            ),
          );

          if (doubleConfirm ?? false) {
            _returnObject = true;
            await _produtorService.deleteProdutor(_currentProdutor.id);
            Navigator.pop(context);
          }
        }
      } else {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(S.of(context).confirm_deletion),
            content: Text(S.of(context).confirm_deletion_message(S.of(context).rural_producer)),
            actions: [
              TextButton(
                child: Text(S.of(context).cancel),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text(S.of(context).delete),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        );

        if (confirm ?? false) {
          _returnObject = true;
          await _produtorService.deleteProdutor(_currentProdutor.id);
          Navigator.pop(context);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_delete(S.of(context).rural_producer)),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  String _capitalizeWords(String value) {
    return value.split(' ').map((word) {
      if (word.isNotEmpty) {
        return word[0].toUpperCase() + word.substring(1).toLowerCase();
      }
      return word;
    }).join(' ');
  }

  Future<void> _saveProdutor() async {
    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _canCreateMoreProdutores = await appStateManager.checkCanCreateMoreProdutores();

    if (_canEdit && _canCreateMoreProdutores) {
      if (_formKey.currentState?.validate() ?? false) {
        _formKey.currentState?.save();
        
        // Mostrar o indicador de carregamento
        _showLoadingDialog(context);

        try {
          if (widget.produtor == null) {
            await _produtorService.add(_currentProdutor);
          } else {
            await _produtorService.update(_currentProdutor.id, _currentProdutor);
          }
          _returnObject = _currentProdutor;
          Navigator.of(context).pop(); // Fechar o indicador de carregamento
          Navigator.of(context).pop(_returnObject); // Fechar a tela atual e retornar o objeto
        } catch (e) {
          Navigator.of(context).pop(); // Fechar o indicador de carregamento
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).error_saving_producer(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_or_edit(_canCreateMoreProdutores ? S.of(context).rural_producer : S.of(context).no_more_producers_allowed)),
          backgroundColor: Colors.red,
        ),
      );
      _returnObject = false;
      Navigator.of(context).pop(false);
    }
  }


  void _addPermission() async {
    if (!_canEditPermissions || !_canEdit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_users),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TextEditingController emailController = TextEditingController();
    String? selectedRole = ProdutorOptions.permissoes.first; // Valor inicial padrão

    final bool? result = await ObjectTemplate.showCustomDialog(
      context: context,
      title: S.of(context).add_permission,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: emailController,
            decoration: ObjectTemplate.getInputDecoration(context, 'E-mail'),
          ),
          const SizedBox(height: 10), // Espaçamento entre campos
          ObjectTemplate.getDropdownButtonFormField(
            context: context,
            labelText: S.of(context).permissao, // Internacionalizado
            value: ProdutorOptions.getLocalizedPermissoes(context)[selectedRole] ?? '',
            items: ProdutorOptions.getLocalizedPermissoesString(context), // Obtém a lista de permissões traduzidas
            onChanged: (String? value) {
              setState(() {
                // Converte o valor internacionalizado de volta para o valor interno
                selectedRole = ProdutorOptions.getLocalizedPermissoes(context).entries.firstWhere((entry) => entry.value == value).key;
              });
            },
          ),
        ],
      ),
      onCancel: () => Navigator.of(context).pop(false),
      onSave: () async {
        final String email = emailController.text;
        final bool emailValid = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);

        if (email.isEmpty || !emailValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).please_enter_valid_email),
              backgroundColor: Colors.red,
            ),
          );
          return; // Não fechar o diálogo
        }

        if (selectedRole == null || selectedRole!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).please_select_valid_role),
              backgroundColor: Colors.red,
            ),
          );
          return; // Não fechar o diálogo
        }

        try {
          await _produtorService.addPermission(_currentProdutor.id, email, selectedRole!);
          setState(() {
            _currentProdutor.permissoes.add({
              'usuarioId': '',
              'email': email,
              'role': selectedRole!,
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).permission_added_successfully)),
          );
          _returnObject = _currentProdutor;
          Navigator.of(context).pop(true); // Fechar o diálogo
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).error_adding_permission(e.toString()))),
          );
        }
      },
    );

    if (result ?? false) {
      // Código para ser executado após fechar o diálogo, se necessário
    }
  }

  void _editPermission(Map<String, String> permissao) async {
    if (_canEdit) {
      final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
      final String? currentUserEmail = appStateManager.currentUserEmail;
      final bool isCurrentUser = permissao['email'] == currentUserEmail;

      final TextEditingController emailController = TextEditingController(text: permissao['email']);
      String? selectedRole = permissao['role'];

      final bool? result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(S.of(context).edit_permission, style: Theme.of(context).textTheme.bodyMedium),
                if (!isCurrentUser)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: Theme.of(context).iconTheme.color, // Usando a cor do tema atual
                    onPressed: () {
                      _returnObject = _currentProdutor;
                      Navigator.of(context).pop(); // Fechar o diálogo de edição
                      _deletePermission(permissao); // Chamar o método para deletar
                    },
                  ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: emailController,
                    decoration: ObjectTemplate.getInputDecoration(context, S.of(context).email),
                    readOnly: true,
                  ),
                  const SizedBox(height: 10),
                  ObjectTemplate.getDropdownButtonFormField(
                    context: context,
                    labelText: S.of(context).permissao, // Internacionalizado
                    value: selectedRole ?? '', // Trate o caso em que selectedRole pode ser null
                    items: ProdutorOptions.getLocalizedPermissoesString(context),
                    onChanged: isCurrentUser
                        ? (_) {}
                        : (String? value) {
                            setState(() {
                              selectedRole = value;
                            });
                          },
                  ),
                ],
              ),
            ),
            actions: <Widget>[
              ElevatedButton(
                child: Text(S.of(context).cancel), // Internacionalizado
                onPressed: () => Navigator.of(context).pop(false),
              ),
              if (!isCurrentUser && _canEdit)
                ElevatedButton(
                  child: Text(S.of(context).save), // Internacionalizado
                  onPressed: () {
                    _returnObject = _currentProdutor;
                    Navigator.of(context).pop(true);
                  },
                ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            backgroundColor: Theme.of(context).dialogBackgroundColor,
          );
        },
      );

      if (result ?? false && !isCurrentUser) {
        try {
          await _produtorService.updatePermission(_currentProdutor.id, permissao['usuarioId']!, selectedRole!);
          setState(() {
            permissao['role'] = selectedRole!;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão atualizada com sucesso.')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar permissão: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para editar as permissões deste Usuário.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  void _deletePermission(Map<String, String> permissao) async {
    if (_canDelete) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Deseja realmente excluir esta permissão?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Excluir'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );

      if (confirm ?? false) {
        try {
          _returnObject = _currentProdutor;
          await _produtorService.deletePermission(_currentProdutor.id, permissao['usuarioId']!);
          setState(() {
            _currentProdutor.permissoes.remove(permissao);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão excluída com sucesso.')),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir permissão: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você não tem permissão para remover estas permissões.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.of(context).pop(false);
    }
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded; // Alterna o estado
    });
    return _isExpanded;
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // O diálogo não pode ser fechado tocando fora dele
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false, // Impede que o usuário feche o diálogo pressionando o botão de voltar
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget _buildPermissoesSection() {
      return Container(
        key: _permissionsKey,
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
          border: Border.all(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                S.of(context).people_with_access,
                style: theme.textTheme.titleSmall,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: _currentProdutor.permissoes.map((Map<String, String> permissao) {
                  final bool isCurrentUser = permissao['email'] == _currentUserEmail;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      title: Text('${S.of(context).email}: ${permissao['email']}', style: theme.textTheme.bodySmall),
                      subtitle: Text('${S.of(context).permissao}: ${ProdutorOptions.getLocalizedPermissoes(context)[permissao['role']] ?? permissao['role'] ?? ''}'),
                      trailing: (_canEditPermissions && !isCurrentUser)
                          ? IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _editPermission(permissao);
                              },
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }

    return FormTemplate(
      title: widget.produtor == null ? S.of(context).add_producer : S.of(context).edit_rural_producer,
      formKey: _formKey,
      onSave: _canEdit ? _saveProdutor : () {},
      moduleName: 'produtores',
      nomeTutorial: S.of(context).rural_producer,
      additionalFloatingActionButtons: (BuildContext context) => [
        if (_canEditPermissions)
          ObjectTemplate.buildCustomFloatingActionButton(
            key: _addPermissionKey,
            context: context,
            onPressed: () {
              setState(() {
                _toggleFloatingActionButton();
                // Contraia o botão principal
              });
              //_toggleFloatingActionButton();
              _addPermission();
            },
            icon: Icons.person_add,
            text: S.of(context).grant_access,
            heroTag: 'addPermission',
          ),
      ],
      isNewItem: widget.produtor == null,
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial, // Adicionado
      isExpanded: _isExpanded, // Passa o estado para o template
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      customTutorialSteps: {
        'customProdutorForm': {
          'key': _produtorFormKey,
          'message': S.of(context).edit_rural_producer_info,
          'shape': 'RRect',
        },
        'customPermissions': {
          'key': _permissionsKey,
          'message': S.of(context).grant_access_other_users,
          'shape': 'RRect',
          'align': 'ContentAlign.top',
        },
      },
      customActionTutorialSteps: {
        'addPermission': {
          'key': _addPermissionKey,
          'message': S.of(context).click_to_grant_access,
          'shape': 'Circle',
          'align': 'ContentAlign.top',
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
                style: theme.textTheme.bodyMedium,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return S.of(context).enter_name;
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentProdutor = _currentProdutor.copyWith(nome: value ?? '');
                },
              ),
              SizedBox(height: 16),

              // Tipo de Produtor
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).producer_type,
                value: _selectedType,
                dropdownItems: ProdutorOptions.getLocalizedTipo(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(context).select_type;
                  }
                  return null;
                },
                suffixIcon: Icon(Icons.business),
              ),
              SizedBox(height: 16),

              // CPF/CNPJ
              TextFormField(
                decoration: ObjectTemplate.getInputDecoration(
                  context,
                  _selectedType == 'Pessoa Física' ? S.of(context).cpf : S.of(context).cnpj,
                  suffixIcon: Icon(Icons.badge),
                ),
                initialValue: _currentProdutor.documento,
                inputFormatters: [
                  FormatacaoUtil.getDocumentoMaskFormatter(
                      _selectedType,
                      Localizations.localeOf(context).toLanguageTag()
                  ),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return _selectedType == 'Pessoa Física'
                        ? S.of(context).enter_cpf
                        : S.of(context).enter_cnpj;
                  }
                  return null;
                },
                onSaved: (value) {
                  _currentProdutor = _currentProdutor.copyWith(documento: value ?? '');
                },
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 24),

              // Seção Status
              Row(
                children: [
                  Icon(Icons.info, color: theme.colorScheme.primary),
                  SizedBox(width: 8),
                  Text(
                    S.of(context).status,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              // Status
              ObjectTemplate.getDropdownButtonFormField(
                context: context,
                labelText: S.of(context).status,
                value: _currentProdutor.status,
                dropdownItems: ProdutorOptions.getLocalizedStatus(context).entries.map((entry) =>
                    DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    )
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _currentProdutor = _currentProdutor.copyWith(
                      status: newValue ?? '',
                    );
                  });
                },
                suffixIcon: Icon(Icons.toggle_on),
              ),
              SizedBox(height: 24),

              // Seção de Permissões
              ObjectTemplate.buildFormSection(
                context: context,
                title: S.of(context).people_with_access,
                icon: Icons.people,
                children: _currentProdutor.permissoes.map((Map<String, String> permissao) {
                  final bool isCurrentUser = permissao['email'] == _currentUserEmail;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ListTile(
                      leading: Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text(
                          '${S.of(context).email}: ${permissao['email']}',
                          style: Theme.of(context).textTheme.bodySmall
                      ),
                      subtitle: Text(
                          '${S.of(context).permissao}: ${ProdutorOptions.getLocalizedPermissoes(context)[permissao['role']] ?? permissao['role'] ?? ''}'
                      ),
                      trailing: (_canEditPermissions && !isCurrentUser)
                          ? IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editPermission(permissao),
                      )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
