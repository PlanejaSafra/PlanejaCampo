import 'package:flutter/material.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:planejacampo/services/app_state_manager.dart';

class ContaDialogScreen {
  final String? bancoId;
  final ContaService contaService;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onUpdate;
  final GlobalKey contasKey;
  final GlobalKey firstContaMoreOptionsKey;
  final GlobalKey firstContaEditKey;
  final GlobalKey firstContaDeleteKey;
  List<Conta>? temporaryContas;

  ContaDialogScreen({
    this.bancoId,
    required this.contaService,
    required this.canEdit,
    required this.canDelete,
    required this.onUpdate,
    required this.contasKey,
    required this.firstContaDeleteKey,
    required this.firstContaEditKey,
    required this.firstContaMoreOptionsKey,
    this.temporaryContas,
  });

  // Method to add a conta
  Future<bool?> addConta(BuildContext context) async {
    if (canEdit) {
      return await _showContaDialog(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_add_accounts),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Method to edit a conta
  Future<bool?> editConta(BuildContext context, Conta conta) async {
    if (canEdit) {
      return await _showContaDialog(context, conta: conta);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_edit_accounts),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Method to delete a conta
  Future<void> deleteConta(BuildContext context, Conta conta) async {
    if (canDelete) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(S.of(context).confirm_deletion),
          content: Text(S.of(context).confirm_deletion_message(S.of(context).account)),
          actions: <Widget>[
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
        if (bancoId == null || bancoId!.isEmpty) {
          // Operate on the temporary list
          temporaryContas?.removeWhere((c) => c.id == conta.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).account_deleted_temporarily)),
          );
          onUpdate();
        } else {
          // Delete from the database
          try {
            await contaService.delete(conta.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).account_deleted_successfully)),
            );
            onUpdate();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.of(context).error_deleting_account(e.toString()))),
            );
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).no_permission_to_delete_accounts),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Certifique-se de que o método buildContasSection() está assim:
  Widget buildContasSection(BuildContext context) {
    if (bancoId == null || bancoId!.isEmpty) {
      // Exibir contas da lista temporária
      return buildTemporaryContasSection(context);
    } else {
      // Exibir contas do banco de dados
      return Container(
        key: contasKey,
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 10,
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                S.of(context).accounts,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FutureBuilder<List<Conta>>(
                future: contaService.getByAttributes({'bancoId': bancoId}),
                builder: (context, snapshot) {
                  return buildContasCards(context, snapshot);
                },
              ),
            ),
          ],
        ),
      );
    }
  }


  // Method to build the temporary contas section
  Widget buildTemporaryContasSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              S.of(context).accounts,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: (temporaryContas != null && temporaryContas!.isNotEmpty)
                ? Column(
                    children: temporaryContas!.map((conta) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        child: ListTile(
                          title: Text('${S.of(context).name}: ${conta.nome}', style: Theme.of(context).textTheme.bodySmall),
                          subtitle: Text('${S.of(context).type}: ${ContaBancariaOptions.getLocalizedTipos(context)[conta.tipo] ?? conta.tipo}'),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (String result) {
                              if (result == 'edit') {
                                editConta(context, conta);
                              } else if (result == 'delete') {
                                deleteConta(context, conta);
                              }
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Text(S.of(context).edit, style: Theme.of(context).popupMenuTheme.textStyle),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Text(S.of(context).delete, style: Theme.of(context).popupMenuTheme.textStyle),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : Card(child: ListTile(title: Text(S.of(context).not_found))),
          ),
        ],
      ),
    );
  }

  // Method to build the contas cards from the database
  Widget buildContasCards(BuildContext context, AsyncSnapshot<List<Conta>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Card(child: ListTile(title: Text(S.of(context).loading)));
    } else if (snapshot.hasError) {
      return Card(child: ListTile(title: Text(S.of(context).error_loading)));
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return Card(child: ListTile(title: Text(S.of(context).not_found)));
    } else {
      final List<Conta> contas = snapshot.data!;
      return Column(
        children: contas.asMap().entries.map((entry) {
          final int index = entry.key;
          final Conta conta = entry.value;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              title: Text('${S.of(context).name}: ${conta.nome}', style: Theme.of(context).textTheme.bodySmall),
              subtitle: Text('${S.of(context).type}: ${ContaBancariaOptions.getLocalizedTipos(context)[conta.tipo] ?? conta.tipo}'),
              trailing: PopupMenuButton<String>(
                key: index == 0 ? firstContaMoreOptionsKey : null,
                icon: const Icon(Icons.more_vert),
                onSelected: (String result) {
                  if (result == 'edit') {
                    editConta(context, conta);
                  } else if (result == 'delete') {
                    deleteConta(context, conta);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    key: index == 0 ? firstContaEditKey : null,
                    child: Text(S.of(context).edit, style: Theme.of(context).popupMenuTheme.textStyle),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    key: index == 0 ? firstContaDeleteKey : null,
                    child: Text(S.of(context).delete, style: Theme.of(context).popupMenuTheme.textStyle),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  // Method to show the conta dialog
  Future<bool?> _showContaDialog(BuildContext context, {Conta? conta}) async {
    final _formKey = GlobalKey<FormState>();
    String nome = conta?.nome ?? '';
    String tipo = conta?.tipo ?? '';
    String? numeroConta = conta?.numeroConta;
    double saldoInicial = conta?.saldoInicial ?? 0.0;
    String? descricao = conta?.descricao;
    String? cartaoBandeira = conta?.cartaoBandeira;
    double? limiteCredito = conta?.limiteCredito;
    int? diaFechamentoFatura = conta?.diaFechamentoFatura;
    int? diaVencimentoFatura = conta?.diaVencimentoFatura;

    return await showDialog<bool>(
      context: context,
      builder: (context) {
        // Using StatefulBuilder to manage local state within the dialog
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(conta == null
                  ? S.of(context).add_account
                  : S.of(context).edit_account),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: nome,
                        decoration:
                            ObjectTemplate.getInputDecoration(context, S.of(context).name),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return S.of(context).enter_name;
                          }
                          return null;
                        },
                        onSaved: (value) {
                          nome = value ?? '';
                        },
                      ),
                      const SizedBox(height: 16.0),
                      ObjectTemplate.getDropdownButtonFormField(
                        context: context,
                        labelText: S.of(context).type,
                        value: tipo,
                        dropdownItems: ContaBancariaOptions.tipos.map((option) =>
                            DropdownMenuItem<String>(
                              value: option,
                              child: Text(ContaBancariaOptions.getLocalizedTipos(context)[option] ?? option),
                            )
                        ).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            tipo = newValue ?? '';
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.of(context).please_select_account_type;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        initialValue: numeroConta,
                        decoration: ObjectTemplate.getInputDecoration(
                          context,
                          tipo == 'Crédito' ? S.of(context).card_number : S.of(context).account_number,
                        ),
                        onSaved: (value) {
                          numeroConta = value;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        initialValue: saldoInicial.toString(),
                        decoration: ObjectTemplate.getInputDecoration(context, S.of(context).initial_balance),
                        keyboardType: TextInputType.number,
                        onSaved: (value) {
                          saldoInicial = double.tryParse(value ?? '') ?? 0.0;
                        },
                      ),
                      const SizedBox(height: 16.0),
                      TextFormField(
                        initialValue: descricao,
                        decoration: ObjectTemplate.getInputDecoration(context, S.of(context).description),
                        onSaved: (value) {
                          descricao = value;
                        },
                      ),
                      if (tipo == 'Crédito') ...[
                        const SizedBox(height: 16.0),
                        TextFormField(
                          initialValue: cartaoBandeira,
                          decoration: ObjectTemplate.getInputDecoration(context, S.of(context).card_brand),
                          onSaved: (value) {
                            cartaoBandeira = value;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          initialValue: limiteCredito?.toString(),
                          decoration: ObjectTemplate.getInputDecoration(context, S.of(context).credit_limit),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            limiteCredito = double.tryParse(value ?? '');
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          initialValue: diaFechamentoFatura?.toString(),
                          decoration: ObjectTemplate.getInputDecoration(context, S.of(context).billing_closing_day),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            diaFechamentoFatura = int.tryParse(value ?? '');
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          initialValue: diaVencimentoFatura?.toString(),
                          decoration: ObjectTemplate.getInputDecoration(context, S.of(context).billing_due_day),
                          keyboardType: TextInputType.number,
                          onSaved: (value) {
                            diaVencimentoFatura = int.tryParse(value ?? '');
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
                TextButton(
                  child: Text(S.of(context).save),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      Conta newConta = Conta(
                        id: conta?.id ?? DateTime.now().toString(),
                        nome: nome,
                        tipo: tipo,
                        numeroConta: numeroConta,
                        bancoId: bancoId,
                        saldoInicial: saldoInicial,
                        descricao: descricao,
                        cartaoBandeira: tipo == 'Crédito' ? cartaoBandeira : null,
                        limiteCredito: tipo == 'Crédito' ? limiteCredito : null,
                        diaFechamentoFatura: tipo == 'Crédito' ? diaFechamentoFatura : null,
                        diaVencimentoFatura: tipo == 'Crédito' ? diaVencimentoFatura : null,
                        produtorId: Provider.of<AppStateManager>(context, listen: false).activeProdutorId ?? '',
                      );
                      if (bancoId == null || bancoId!.isEmpty) {
                        // Operate on the temporary list
                        if (conta == null) {
                          temporaryContas?.add(newConta);
                        } else {
                          int index = temporaryContas?.indexWhere((c) => c.id == conta.id) ?? -1;
                          if (index >= 0) {
                            temporaryContas![index] = newConta;
                          }
                        }
                        onUpdate();
                        Navigator.of(context).pop(true);
                      } else {
                        // Save directly to the database
                        if (conta == null) {
                          // Add new conta
                          contaService.add(newConta).then((_) {
                            onUpdate();
                            Navigator.of(context).pop(true);
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.of(context).error_adding_account(e.toString()))),
                            );
                          });
                        } else {
                          // Update existing conta
                          contaService.update(newConta.id, newConta).then((_) {
                            onUpdate();
                            Navigator.of(context).pop(true);
                          }).catchError((e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(S.of(context).error_updating_account(e.toString()))),
                            );
                          });
                        }
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
