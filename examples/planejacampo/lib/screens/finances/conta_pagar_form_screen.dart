import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/banco.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/screens/appbar/pessoas_list_screen.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/banco_service.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/utils/conta_bancaria_options.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';
import 'package:planejacampo/widgets/form_template.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

class ContaPagarFormScreen extends StatefulWidget {
  final ContaPagar? contaPagar;

  const ContaPagarFormScreen({
    Key? key,
    this.contaPagar,
  }) : super(key: key);

  @override
  _ContaPagarFormScreenState createState() => _ContaPagarFormScreenState();
}

class _ContaPagarFormScreenState extends State<ContaPagarFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ContaPagarService _contaPagarService = ContaPagarService();
  final PessoaService _pessoaService = PessoaService();
  final ContaService _contaService = ContaService();

  // Controladores formatados para valores
  late TextEditingController _valorController;
  late TextEditingController _valorPagoController;
  final TextEditingController _fornecedorController = TextEditingController();
  final FocusNode _fornecedorFocusNode = FocusNode();

  // Keys para tutorial
  final GlobalKey _fornecedorKey = GlobalKey();
  final GlobalKey _valorKey = GlobalKey();
  final GlobalKey _dataEmissaoKey = GlobalKey();
  final GlobalKey _dataVencimentoKey = GlobalKey();
  final GlobalKey _meioPagamentoKey = GlobalKey();
  final GlobalKey _contaIdKey = GlobalKey();
  final GlobalKey _valorPagoKey = GlobalKey();
  final GlobalKey _dataPagamentoKey = GlobalKey();

  late String _produtorId;

  // Campos do formulário
  String _id = '';
  String? _contaId;
  double _valor = 0.0;
  double _valorPago = 0.0;
  String _status = 'aberto';
  DateTime _dataEmissao = DateTime.now();
  DateTime _dataVencimento = DateTime.now().add(Duration(days: 30));
  DateTime? _dataPagamento;
  String? _numeroDocumento;
  String _meioPagamento = 'Boleto'; // Default para primeiro item da lista
  int? _numeroParcela;
  int? _totalParcelas;
  String _origemId = ''; // Manual por padrão
  String _origemTipo = 'manual'; // Manual por padrão
  String _categoria = '';
  String? _observacoes;
  bool _ativo = true;
  String? _fornecedorId;

  // Listas para dropdowns
  List<Pessoa> _fornecedores = [];
  List<Conta> _contas = [];
  List<String> _categorias = ['Despesa Geral', 'Insumo', 'Manutenção', 'Operacional', 'Funcionários', 'Impostos', 'Outros'];

  bool _isLoading = false;
  bool _isEditMode = false;
  bool _isLoadingContas = true;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.contaPagar != null;

    // Inicializa controladores com formatação para valores
    _valorController = FormatacaoUtil.getMaskedTextController(widget.contaPagar?.valor ?? 0.0);
    _valorPagoController = FormatacaoUtil.getMaskedTextController(widget.contaPagar?.valorPago ?? 0.0);

    // Adiciona listeners para validações em tempo real
    _valorController.addListener(_updateValues);
    _valorPagoController.addListener(_checkValorPagoStatus);

    _loadData();
  }

  // Atualiza valores do estado quando inputs mudam
  void _updateValues() {
    try {
      final locale = Localizations.localeOf(context).toString();
      final valor = NumberFormat.decimalPattern(locale).parse(_valorController.text).toDouble();
      setState(() {
        _valor = valor;
      });
    } catch (e) {
      // Ignora erros durante digitação
    }
  }

  // Validação para valor pago e data de pagamento
  void _checkValorPagoStatus() {
    try {
      final locale = Localizations.localeOf(context).toString();
      final valorPago = NumberFormat.decimalPattern(locale).parse(_valorPagoController.text).toDouble();

      setState(() {
        _valorPago = valorPago;

        // Atualiza status baseado no valor pago
        if (valorPago >= _valor) {
          _status = 'pago';
        } else if (valorPago > 0) {
          _status = 'parcial';
        } else {
          _status = 'aberto';
        }

        // Se valor pago for zero, remove data de pagamento
        if (valorPago == 0) {
          _dataPagamento = null;
        }
        // Se valor pago for positivo e não há data, define data atual
        else if (valorPago > 0 && _dataPagamento == null) {
          _dataPagamento = DateTime.now();
        }
      });
    } catch (e) {
      // Ignora erros durante digitação
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Obter produtorId ativo
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _produtorId = appStateManager.activeProdutorId ?? '';

    try {
      // Carregar fornecedores
      final fornecedores = await _pessoaService.getAll();

      // Carregar contas bancárias disponíveis
      final contas = await ContaBancariaOptions.buscarContasBancarias(
          _contaService, _produtorId);

      setState(() {
        _fornecedores = fornecedores;
        _contas = contas;
        _isLoadingContas = false;

        if (_isEditMode) {
          _populateFormWithExistingData();
        }

        _isLoading = false;
      });

      // Verificar se o meio de pagamento requer conta de pagamento
      _checkMeioPagamentoRequirements();
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

  void _selecionarFornecedor() async {
    final fornecedor = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PessoasListScreen(isSelectMode: true, vinculos: ['Fornecedor']),
      ),
    );
    if (fornecedor != null) {
      setState(() {
        _fornecedorId = fornecedor.id;
        _fornecedorController.text = fornecedor.nome;
      });
    }
  }

  void _populateFormWithExistingData() {
    final ContaPagar contaPagar = widget.contaPagar!;

    _id = contaPagar.id;
    _contaId = contaPagar.contaId;
    _valor = contaPagar.valor;
    _valorPago = contaPagar.valorPago;
    _status = contaPagar.status;
    _dataEmissao = contaPagar.dataEmissao;
    _dataVencimento = contaPagar.dataVencimento;
    _dataPagamento = contaPagar.dataPagamento;
    _numeroDocumento = contaPagar.numeroDocumento;
    _meioPagamento = contaPagar.meioPagamento;
    _numeroParcela = contaPagar.numeroParcela;
    _totalParcelas = contaPagar.totalParcelas;
    _origemId = contaPagar.origemId;
    _origemTipo = contaPagar.origemTipo;
    _categoria = contaPagar.categoria;
    _observacoes = contaPagar.observacoes;
    _ativo = contaPagar.ativo;
    _fornecedorId = contaPagar.fornecedorId;

    // Inicializa os controladores com os valores
    _valorController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_valor);
    _valorPagoController.text = FormatacaoUtil.formatNumberWithTwoDecimalPlaces(_valorPago);

    // Carregar nome do fornecedor para o controller
    if (_fornecedorId != null && _fornecedorId!.isNotEmpty) {
      _carregarNomeFornecedor(_fornecedorId!);
    }
  }

  void _carregarNomeFornecedor(String fornecedorId) async {
    final fornecedor = await _pessoaService.getById(fornecedorId);
    if (fornecedor != null && mounted) {
      setState(() {
        _fornecedorController.text = fornecedor.nome;
      });
    }
  }

  // Método para verificar se o meio de pagamento selecionado requer conta associada
  void _checkMeioPagamentoRequirements() {
    setState(() {
      // Se o meio de pagamento não requer conta, limpar a seleção
      if (!MeioPagamentoOptions.requiresContaPagamento(_meioPagamento)) {
        _contaId = null;
        return;
      }

      // Verificar se a conta atualmente selecionada ainda é válida para o novo meio de pagamento
      bool contaAtualValida = false;
      if (_contaId != null) {
        contaAtualValida = _contas.any((conta) =>
        conta.id == _contaId &&
            ContaBancariaOptions.isContaAllowedForPagamento(_meioPagamento, conta)
        );
      }

      // Se a conta atual não for válida para o novo meio de pagamento, redefina
      if (!contaAtualValida) {
        // Tenta obter uma conta padrão ou a primeira disponível
        _contaId = _getRecommendedContaId(_meioPagamento);
      }
    });
  }

  // Obtém o ID da conta recomendada para o meio de pagamento
  String? _getRecommendedContaId(String meioPagamento) {
    final contasDisponiveis = _contas.where((conta) =>
        ContaBancariaOptions.isContaAllowedForPagamento(meioPagamento, conta)
    ).toList();

    if (contasDisponiveis.isEmpty) {
      return null;
    }

    // Primeiro tenta encontrar uma conta padrão para este meio de pagamento
    final contaPadrao = ContaBancariaOptions.getDefaultContaBancaria(meioPagamento, _contas);

    if (contaPadrao != null) {
      return contaPadrao.id;
    }

    // Se não houver conta padrão, retorna a primeira conta disponível
    return contasDisponiveis.first.id;
  }

  // Conta quantas contas estão disponíveis para o meio de pagamento selecionado
  int _countContasForMeioPagamento(String meioPagamento) {
    return _contas.where((conta) =>
        ContaBancariaOptions.isContaAllowedForPagamento(meioPagamento, conta)
    ).length;
  }

  // Verifica a consistência entre valor pago e data de pagamento
  bool _verificarConsistenciaValorEData() {
    // Converte os valores para números
    final locale = Localizations.localeOf(context).toString();
    double valorPago;

    try {
      valorPago = NumberFormat.decimalPattern(locale).parse(_valorPagoController.text).toDouble();
    } catch (e) {
      valorPago = 0.0;
    }

    // Verifica consistência entre valor pago e data de pagamento
    if (valorPago > 0 && _dataPagamento == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).payment_date_required_when_paid_amount_is_greater_than_zero),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (valorPago == 0 && _dataPagamento != null) {
      // Auto-corrigir: se valor pago for zero, remove a data de pagamento
      setState(() {
        _dataPagamento = null;
      });
    }

    return true;
  }

  Future<bool> _onWillPop() async {
    // Verifica consistência entre valor pago e data de pagamento
    if (!_verificarConsistenciaValorEData()) {
      return false;
    }

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

  Future<void> _saveContaPagar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Verifica consistência entre valor pago e data de pagamento
    if (!_verificarConsistenciaValorEData()) {
      return;
    }

    _formKey.currentState!.save();

    // Converte os valores dos controladores para números
    final locale = Localizations.localeOf(context).toString();
    final valor = NumberFormat.decimalPattern(locale).parse(_valorController.text).toDouble();
    final valorPago = NumberFormat.decimalPattern(locale).parse(_valorPagoController.text).toDouble();

    // Validação adicional: se o status é "pago", o valor pago deve ser >= valor total
    if (_status == 'pago' && valorPago < valor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).paid_amount_must_be_greater_or_equal_to_total_amount),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      ContaPagar contaPagar = ContaPagar(
        id: _isEditMode ? _id : '',
        produtorId: _produtorId,
        contaId: _contaId,
        valor: valor,
        valorPago: valorPago,
        status: _status,
        dataEmissao: _dataEmissao,
        dataVencimento: _dataVencimento,
        dataPagamento: _dataPagamento,
        numeroDocumento: _numeroDocumento,
        meioPagamento: _meioPagamento,
        numeroParcela: _numeroParcela,
        totalParcelas: _totalParcelas,
        origemId: _origemId.isEmpty ? 'manual' : _origemId,
        origemTipo: _origemTipo.isEmpty ? 'manual' : _origemTipo,
        categoria: _categoria,
        observacoes: _observacoes,
        ativo: _ativo,
        fornecedorId: _fornecedorId,
      );

      if (_isEditMode) {
        await _contaPagarService.atualizarContaPagar(contaPagar);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).account_payable_updated_successfully)),
        );
      } else {
        final docId = await _contaPagarService.registrarContaPagar(contaPagar);
        if (docId != null) {
          contaPagar = ContaPagar(
            id: docId,
            produtorId: _produtorId,
            contaId: _contaId,
            valor: valor,
            valorPago: valorPago,
            status: _status,
            dataEmissao: _dataEmissao,
            dataVencimento: _dataVencimento,
            dataPagamento: _dataPagamento,
            numeroDocumento: _numeroDocumento,
            meioPagamento: _meioPagamento,
            numeroParcela: _numeroParcela,
            totalParcelas: _totalParcelas,
            origemId: _origemId.isEmpty ? 'manual' : _origemId,
            origemTipo: _origemTipo.isEmpty ? 'manual' : _origemTipo,
            categoria: _categoria,
            observacoes: _observacoes,
            ativo: _ativo,
            fornecedorId: _fornecedorId,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).account_payable_created_successfully)),
        );
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(contaPagar);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).error_saving_account_payable(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return FormTemplate(
      title: _isEditMode ? S.of(context).edit_account_payable : S.of(context).new_account_payable,
      moduleName: 'bancos',
      formKey: _formKey,
      returnObject: _isEditMode ? widget.contaPagar! : '',
      onWillPop: _onWillPop,
      onSave: _saveContaPagar,
      isNewItem: !_isEditMode,
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Identificação
            Text(
              S.of(context).basic_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Fornecedor
            TextFormField(
              key: _fornecedorKey,
              controller: _fornecedorController,
              focusNode: _fornecedorFocusNode,
              readOnly: true,
              onTap: _selecionarFornecedor,
              decoration: InputDecoration(
                labelText: S.of(context).supplier,
                suffixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
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
              key: _valorKey,
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

            // Data de Emissão
            GestureDetector(
              key: _dataEmissaoKey,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataEmissao,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _dataEmissao = date;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: S.of(context).issue_date,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: FormatacaoUtil.formatDate(_dataEmissao),
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

            // Data de Vencimento
            GestureDetector(
              key: _dataVencimentoKey,
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataVencimento,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _dataVencimento = date;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: S.of(context).due_date,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  controller: TextEditingController(
                    text: FormatacaoUtil.formatDate(_dataVencimento),
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
            SizedBox(height: 24),

            // Número do Documento
            TextFormField(
              initialValue: _numeroDocumento ?? '',
              decoration: InputDecoration(
                labelText: S.of(context).document_number,
                border: OutlineInputBorder(),
              ),
              onSaved: (value) {
                _numeroDocumento = value?.isNotEmpty == true ? value : null;
              },
            ),
            SizedBox(height: 16),

            // Seção de Pagamento
            Text(
              S.of(context).payment_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Valor Pago
            TextFormField(
              key: _valorPagoKey,
              controller: _valorPagoController,
              decoration: InputDecoration(
                labelText: S.of(context).paid_amount,
                prefixText: currencySymbol,
                border: OutlineInputBorder(),
                helperText: S.of(context).enter_payment_amount_if_already_paid,
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Valor pago pode ser vazio (zero) inicialmente
                }
                try {
                  final valorPago = double.parse(value.replaceAll(',', '.'));
                  if (valorPago < 0) {
                    return S.of(context).value_must_be_greater_than_or_equal_to_zero;
                  }
                } catch (e) {
                  return S.of(context).invalid_number;
                }
                return null;
              },
            ),
            SizedBox(height: 16),

            // Data de Pagamento
            GestureDetector(
              key: _dataPagamentoKey,
              onTap: () async {
                // Não permitir a seleção de data se o valor pago for zero
                final valorPagoText = _valorPagoController.text.replaceAll(',', '.');
                double valorPago = 0.0;
                try {
                  valorPago = double.parse(valorPagoText);
                } catch (e) {
                  // Tratamento de erro
                }

                if (valorPago <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).paid_amount_must_be_greater_than_zero_to_set_payment_date),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                final date = await showDatePicker(
                  context: context,
                  initialDate: _dataPagamento ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    _dataPagamento = date;
                  });
                }
              },
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: S.of(context).payment_date,
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                    helperText: _valorPago > 0
                        ? S.of(context).required_for_paid_amount
                        : S.of(context).only_available_when_paid_amount_is_set,
                  ),
                  controller: TextEditingController(
                    text: _dataPagamento != null ?
                    FormatacaoUtil.formatDate(_dataPagamento!) : '',
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // Meio de Pagamento
            DropdownButtonFormField<String>(
              key: _meioPagamentoKey,
              decoration: InputDecoration(
                labelText: S.of(context).payment_method,
                border: OutlineInputBorder(),
              ),
              value: _meioPagamento,
              items: MeioPagamentoOptions.formasDePagamento.map((meio) {
                return DropdownMenuItem<String>(
                  value: meio,
                  child: Text(MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[meio] ?? meio),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _meioPagamento = value!;
                  _checkMeioPagamentoRequirements();
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

            // Conta Bancária (exibir somente se o meio de pagamento exigir e houver mais de uma conta disponível)
            if (MeioPagamentoOptions.requiresContaPagamento(_meioPagamento) &&
                _countContasForMeioPagamento(_meioPagamento) > 1)
              Column(
                children: [
                  DropdownButtonFormField<String?>(
                    key: _contaIdKey,
                    decoration: InputDecoration(
                      labelText: S.of(context).account,
                      border: OutlineInputBorder(),
                    ),
                    value: _contaId,
                    items: [
                      ..._contas
                          .where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(_meioPagamento, conta))
                          .map((conta) {
                        return DropdownMenuItem<String?>(
                          value: conta.id,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                                  FutureBuilder<Banco?>(
                                    future: BancoService().getById(conta.bancoId!),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData && snapshot.data != null) {
                                        return Text(
                                          snapshot.data!.nome,
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                Text(
                                  conta.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                    selectedItemBuilder: (BuildContext context) {
                      return _contas
                          .where((conta) => ContaBancariaOptions.isContaAllowedForPagamento(_meioPagamento, conta))
                          .map<Widget>((conta) {
                        return Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (conta.bancoId != null && conta.bancoId!.isNotEmpty)
                                FutureBuilder<Banco?>(
                                  future: BancoService().getById(conta.bancoId!),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data != null) {
                                      return Flexible(
                                        child: Text(
                                          '${snapshot.data!.nome} - ',
                                          style: Theme.of(context).textTheme.bodySmall,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              Flexible(
                                child: Text(
                                  conta.nome,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                    onChanged: (String? value) {
                      setState(() {
                        _contaId = value;
                      });
                    },
                    validator: (value) {
                      if (MeioPagamentoOptions.requiresContaPagamento(_meioPagamento) && (value == null || value.isEmpty)) {
                        return S.of(context).required_field;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                ],
              ),

            // Informações de Parcela
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _numeroParcela?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: S.of(context).installment_number,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      _numeroParcela = value?.isNotEmpty == true ? int.tryParse(value!) : null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _totalParcelas?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: S.of(context).total_installments,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      _totalParcelas = value?.isNotEmpty == true ? int.tryParse(value!) : null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Seção de Categorização
            Text(
              S.of(context).categorization,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Categoria
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: S.of(context).category,
                border: OutlineInputBorder(),
              ),
              value: _categorias.contains(_categoria) ? _categoria : _categorias.first,
              items: _categorias.map((categoria) {
                return DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _categoria = value!;
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

            // Observações
            TextFormField(
              initialValue: _observacoes ?? '',
              decoration: InputDecoration(
                labelText: S.of(context).notes,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onSaved: (value) {
                _observacoes = value?.isNotEmpty == true ? value : null;
              },
            ),
          ],
        ),
      ),
    );
  }
}