// lancamento_contabil_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_projetado_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:provider/provider.dart';

class LancamentoContabilFormScreen extends StatefulWidget {
  final LancamentoContabil? lancamento;

  const LancamentoContabilFormScreen({
    Key? key,
    this.lancamento,
  }) : super(key: key);

  @override
  _LancamentoContabilFormScreenState createState() => _LancamentoContabilFormScreenState();
}

class _LancamentoContabilFormScreenState extends State<LancamentoContabilFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final LancamentoContabilProjetadoService _lancamentoProjetadoService =
  LancamentoContabilProjetadoService();
  final ContaContabilService _contaContabilService = ContaContabilService();

  late TextEditingController _valorController;
  late TextEditingController _descricaoController;

  late String _produtorId;
  bool _isLoading = false;
  bool _isEditMode = false;
  bool _modoAvancado = false; // Toggle entre modo simples e avançado

  // Campos do formulário
  String _id = '';
  String? _contaContabilId;
  String _tipo = 'Debito';
  double _valor = 0.0;
  DateTime _data = DateTime.now();
  String? _descricao;

  // Modo avançado - partidas dobradas
  List<PartidaLancamento> _partidas = [];

  List<ContaContabil> _contasAnaliticas = [];
  bool _isLoadingContas = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.lancamento != null;

    _valorController = FormatacaoUtil.getMaskedTextController(
        widget.lancamento?.valor ?? 0.0
    );
    _descricaoController = TextEditingController(
        text: widget.lancamento?.descricao ?? ''
    );

    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _produtorId = appStateManager.activeProdutorId ?? '';

    try {
      // Carregar apenas contas analíticas (que podem receber lançamentos)
      final contas = await _contaContabilService.getByAttributes({
        'produtorId': _produtorId,
        'tipo': 'analitica',
        'ativo': true,
        'languageCode': appStateManager.appLocale.languageCode,
      });

      setState(() {
        _contasAnaliticas = contas;
        _isLoadingContas = false;

        if (_isEditMode) {
          _populateFormWithExistingData();
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar dados: $e');
      setState(() {
        _isLoading = false;
        _isLoadingContas = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).error_loading_data)),
      );
    }
  }

  void _populateFormWithExistingData() {
    final lancamento = widget.lancamento!;

    _id = lancamento.id;
    _contaContabilId = lancamento.contaContabilId;
    _tipo = lancamento.tipo;
    _valor = lancamento.valor;
    _data = lancamento.data;
    _descricao = lancamento.descricao;

    _valorController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_valor);
    _descricaoController.text = _descricao ?? '';
  }

  Future<bool> _onWillPop() async {
    if (_formKey.currentState!.validate()) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).unsaved_changes),
        content: Text(S.of(context).discard_changes_question),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.of(context).discard),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Future<void> _saveLancamento() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();

    // Converter valor
    final locale = Localizations.localeOf(context).toString();
    final valor = NumberFormat.decimalPattern(locale).parse(_valorController.text).toDouble();

    if (valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).value_must_be_greater_than_zero),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_modoAvancado) {
        // Modo avançado - criar múltiplas partidas
        await _salvarPartidasDobradas();
      } else {
        // Modo simples - criar lançamento único
        await _salvarLancamentoSimples(valor);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? S.of(context).entry_updated_successfully
              : S.of(context).entry_created_successfully),
        ),
      );

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).error_saving_entry(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _salvarLancamentoSimples(double valor) async {
    final conta = _contasAnaliticas.firstWhere((c) => c.id == _contaContabilId);

    await _lancamentoProjetadoService.registrarLancamentosOperacao(
      operacao: 'LancamentoManual',
      produtorId: _produtorId,
      data: _data,
      origemId: DateTime.now().millisecondsSinceEpoch.toString(),
      origemTipo: 'manual',
      valor: valor,
      descricao: _descricaoController.text,
      contaContabil: conta,
    );
  }

  Future<void> _salvarPartidasDobradas() async {
    // TODO: Implementar salvamento de múltiplas partidas
    // Validar que débitos = créditos
    // Criar lançamentos para cada partida com mesmo loteId
  }

  void _adicionarPartida() {
    setState(() {
      _partidas.add(PartidaLancamento(
        contaContabilId: null,
        tipo: 'Debito',
        valor: 0.0,
      ));
    });
  }

  void _removerPartida(int index) {
    setState(() {
      _partidas.removeAt(index);
    });
  }

  double _calcularTotalDebitos() {
    return _partidas
        .where((p) => p.tipo == 'Debito')
        .fold(0.0, (sum, p) => sum + p.valor);
  }

  double _calcularTotalCreditos() {
    return _partidas
        .where((p) => p.tipo == 'Credito')
        .fold(0.0, (sum, p) => sum + p.valor);
  }

  bool _partidasBalanceadas() {
    return _calcularTotalDebitos() == _calcularTotalCreditos();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return FormTemplate(
      title: _isEditMode
          ? S.of(context).edit_accounting_entry
          : S.of(context).new_accounting_entry,
      moduleName: 'contabil',
      formKey: _formKey,
      returnObject: _isEditMode ? widget.lancamento! : '',
      onWillPop: _onWillPop,
      onSave: _saveLancamento,
      isNewItem: !_isEditMode,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Toggle modo simples/avançado
            Card(
              child: SwitchListTile(
                title: Text(S.of(context).advanced_mode),
                subtitle: Text(S.of(context).double_entry_bookkeeping),
                value: _modoAvancado,
                onChanged: (value) {
                  setState(() {
                    _modoAvancado = value;
                    if (value && _partidas.isEmpty) {
                      // Inicializar com 2 partidas
                      _partidas = [
                        PartidaLancamento(
                          contaContabilId: null,
                          tipo: 'Debito',
                          valor: 0.0,
                        ),
                        PartidaLancamento(
                          contaContabilId: null,
                          tipo: 'Credito',
                          valor: 0.0,
                        ),
                      ];
                    }
                  });
                },
              ),
            ),
            SizedBox(height: 16),

            if (!_modoAvancado) ...[
              // MODO SIMPLES
              _buildModoSimples(theme, currencySymbol),
            ] else ...[
              // MODO AVANÇADO
              _buildModoAvancado(theme, currencySymbol),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModoSimples(ThemeData theme, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).basic_information,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),

        // Data
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _data,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _data = date;
              });
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: S.of(context).date,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: FormatacaoUtil.formatDate(_data),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).required_field;
                }
                return null;
              },
            ),
          ),
        ),
        SizedBox(height: 16),

        // Tipo (Débito/Crédito)
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: S.of(context).type,
            border: OutlineInputBorder(),
          ),
          value: _tipo,
          items: [
            DropdownMenuItem(
              value: 'Debito',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                  SizedBox(width: 8),
                  Text(S.of(context).debit),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'Credito',
              child: Row(
                children: [
                  Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(S.of(context).credit),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            setState(() {
              _tipo = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required_field;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Conta Contábil
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: S.of(context).account,
            border: OutlineInputBorder(),
            helperText: S.of(context).select_account_for_entry,
          ),
          value: _contaContabilId,
          items: _contasAnaliticas.map((conta) {
            return DropdownMenuItem<String>(
              value: conta.id,
              child: Text('${conta.codigo} - ${conta.nome}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _contaContabilId = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required_field;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Valor
        TextFormField(
          controller: _valorController,
          decoration: InputDecoration(
            labelText: S.of(context).amount,
            prefixText: currencySymbol,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          inputFormatters: <TextInputFormatter>[
            FormatacaoUtil.instance.decimalInputFormatter,
          ],
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required_field;
            }
            try {
              final valor = double.parse(value.replaceAll(',', '.'));
              if (valor <= 0) {
                return S.of(context).value_must_be_greater_than_zero;
              }
            } catch (e) {
              return S.of(context).invalid_number;
            }
            return null;
          },
        ),
        SizedBox(height: 16),

        // Descrição
        TextFormField(
          controller: _descricaoController,
          decoration: InputDecoration(
            labelText: S.of(context).description,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return S.of(context).required_field;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildModoAvancado(ThemeData theme, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).double_entry_entries,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          S.of(context).total_debits_must_equal_credits,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 16),

        // Data comum para todas as partidas
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _data,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
            );
            if (date != null) {
              setState(() {
                _data = date;
              });
            }
          },
          child: AbsorbPointer(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: S.of(context).date,
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              controller: TextEditingController(
                text: FormatacaoUtil.formatDate(_data),
              ),
            ),
          ),
        ),
        SizedBox(height: 16),

        // Lista de partidas
        ..._partidas.asMap().entries.map((entry) {
          final index = entry.key;
          final partida = entry.value;
          return _buildPartidaCard(index, partida, theme, currencySymbol);
        }).toList(),

        // Botão adicionar partida
        OutlinedButton.icon(
          onPressed: _adicionarPartida,
          icon: Icon(Icons.add),
          label: Text(S.of(context).add_entry),
        ),
        SizedBox(height: 16),

        // Totalizadores
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _partidasBalanceadas()
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _partidasBalanceadas() ? Colors.green : Colors.red,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).total_debits,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_calcularTotalDebitos())}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).total_credits,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_calcularTotalCreditos())}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.of(context).balance,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      if (_partidasBalanceadas())
                        Icon(Icons.check_circle, color: Colors.green, size: 20)
                      else
                        Icon(Icons.error, color: Colors.red, size: 20),
                      SizedBox(width: 4),
                      Text(
                        '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces((_calcularTotalDebitos() - _calcularTotalCreditos()).abs())}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _partidasBalanceadas() ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Descrição geral
        TextFormField(
          controller: _descricaoController,
          decoration: InputDecoration(
            labelText: S.of(context).general_description,
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildPartidaCard(int index, PartidaLancamento partida, ThemeData theme, String currencySymbol) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${S.of(context).entry} ${index + 1}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_partidas.length > 2)
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removerPartida(index),
                  ),
              ],
            ),
            SizedBox(height: 12),

            // Tipo
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: S.of(context).type,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: partida.tipo,
              items: [
                DropdownMenuItem(
                  value: 'Debito',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text(S.of(context).debit),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'Credito',
                  child: Row(
                    children: [
                      Icon(Icons.arrow_downward, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Text(S.of(context).credit),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  partida.tipo = value!;
                });
              },
            ),
            SizedBox(height: 12),

            // Conta
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: S.of(context).account,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              value: partida.contaContabilId,
              items: _contasAnaliticas.map((conta) {
                return DropdownMenuItem<String>(
                  value: conta.id,
                  child: Text(
                    '${conta.codigo} - ${conta.nome}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  partida.contaContabilId = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).required_field;
                }
                return null;
              },
            ),
            SizedBox(height: 12),

            // Valor
            TextFormField(
              decoration: InputDecoration(
                labelText: S.of(context).amount,
                prefixText: currencySymbol,
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: <TextInputFormatter>[
                FormatacaoUtil.instance.decimalInputFormatter,
              ],
              onChanged: (value) {
                try {
                  final locale = Localizations.localeOf(context).toString();
                  partida.valor = NumberFormat.decimalPattern(locale).parse(value).toDouble();
                  setState(() {}); // Atualizar totalizadores
                } catch (e) {
                  // Ignorar erros durante digitação
                }
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return S.of(context).required_field;
                }
                try {
                  final valor = double.parse(value.replaceAll(',', '.'));
                  if (valor <= 0) {
                    return S.of(context).value_must_be_greater_than_zero;
                  }
                } catch (e) {
                  return S.of(context).invalid_number;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _valorController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }
}

// Classe auxiliar para partidas no modo avançado
class PartidaLancamento {
  String? contaContabilId;
  String tipo;
  double valor;

  PartidaLancamento({
    required this.contaContabilId,
    required this.tipo,
    required this.valor,
  });
}