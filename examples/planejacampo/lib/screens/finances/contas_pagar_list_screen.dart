import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/utils/meio_pagamento_options.dart';
import 'package:planejacampo/widgets/list_template_v3.dart';
import 'package:provider/provider.dart';

import 'conta_pagar_form_screen.dart';
import 'conta_pagar_screen.dart';

class ContasPagarListScreen extends StatefulWidget {
  final bool isSelectMode;
  final bool isSetMode;
  final String? statusFilter;

  const ContasPagarListScreen({
    Key? key,
    this.isSelectMode = false,
    this.isSetMode = false,
    this.statusFilter,
  }) : super(key: key);

  @override
  _ContasPagarListScreenState createState() => _ContasPagarListScreenState();
}

class _ContasPagarListScreenState extends State<ContasPagarListScreen> with SingleTickerProviderStateMixin {
  final String _moduleName = 'bancos';
  final ContaPagarService _contaPagarService = ContaPagarService();
  final PessoaService _pessoaService = PessoaService();
  final ContaService _contaService = ContaService();

  late Future<List<ContaPagar>> _contasPagarFuture;
  Object _returnObject = false;
  bool _showTutorial = false;

  // Mapas para armazenar nomes de fornecedores e contas
  Map<String, String> _nomesFornecedores = {};
  Map<String, String> _nomesContasPagamento = {};

  // Define as opções de filtro
  final List<String> _filterOptions = ['todos', 'aberto', 'parcial', 'pago', 'vencido'];
  String _currentFilter = 'todos';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();

    // Inicializa o controlador de tabs
    _tabController = TabController(length: _filterOptions.length, vsync: this);

    // Se um filtro inicial foi fornecido, usá-lo
    if (widget.statusFilter != null) {
      _currentFilter = widget.statusFilter!;
      // Seleciona a tab correspondente
      final index = _filterOptions.indexOf(_currentFilter);
      if (index >= 0) {
        _tabController.index = index;
      }
    }

    // Adiciona listener para mudança de tabs
    _tabController.addListener(_handleTabSelection);

    _loadContasPagar();

    final AppStateManager appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('contasPagarListScreen');
    appStateManager.setShowTutorial('contasPagarListScreen', false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging || _tabController.index != _filterOptions.indexOf(_currentFilter)) {
      setState(() {
        _currentFilter = _filterOptions[_tabController.index];
        _loadContasPagar();
      });
    }
  }

  void _loadContasPagar() {
    setState(() {
      _contasPagarFuture = _getFilteredContasPagar();
    });
  }

  Future<List<ContaPagar>> _getFilteredContasPagar() async {
    List<ContaPagar> contas;

    if (_currentFilter == 'vencido') {
      contas = await _contaPagarService.buscarContasVencidas();
    } else if (_currentFilter != 'todos') {
      contas = await _contaPagarService.buscarContasPorStatus(_currentFilter);
    } else {
      contas = await _contaPagarService.getAll();
    }

    // Carrega nomes de fornecedores e contas de pagamento
    await _carregarDadosRelacionados(contas);

    return contas;
  }

  Future<void> _carregarDadosRelacionados(List<ContaPagar> contas) async {
    // Carrega nomes dos fornecedores
    for (var conta in contas) {
      if (conta.fornecedorId != null && !_nomesFornecedores.containsKey(conta.fornecedorId)) {
        final fornecedor = await _pessoaService.getById(conta.fornecedorId!);
        if (fornecedor != null) {
          _nomesFornecedores[conta.fornecedorId!] = fornecedor.nome;
        }
      }

      // Carrega nomes das contas de pagamento
      if (conta.contaId != null && !_nomesContasPagamento.containsKey(conta.contaId)) {
        final contaPagto = await _contaService.getById(conta.contaId!);
        if (contaPagto != null) {
          _nomesContasPagamento[conta.contaId!] = contaPagto.nome;
        }
      }
    }
  }

  void _refreshContasPagar() {
    _returnObject = true;
    _nomesFornecedores.clear();
    _nomesContasPagamento.clear();
    _loadContasPagar();
  }

  Future<void> _registrarPagamento(ContaPagar contaPagar) async {
    if (contaPagar.status == 'pago') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).account_already_paid)),
      );
      return;
    }

    final valorRestante = contaPagar.valor - contaPagar.valorPago;

    try {
      final confirmPagamento = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(S.of(context).confirm_payment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).confirm_full_payment_question),
                const SizedBox(height: 8),
                Text(
                  '${S.of(context).amount}: ${S.of(context).currency_symbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(valorRestante)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(S.of(context).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(S.of(context).confirm),
              ),
            ],
          );
        },
      );

      if (confirmPagamento == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Text(S.of(context).processing),
                  ],
                ),
              ),
            );
          },
        );

        await _contaPagarService.registrarPagamento(
          contaPagar.id,
          valorRestante,
          dataPagamento: DateTime.now(),
        );

        Navigator.of(context).pop();
        _refreshContasPagar();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).payment_registered_successfully),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).error_registering_payment(e.toString())),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status) {
      case 'aberto':
        return Colors.blue;
      case 'parcial':
        return Colors.orange;
      case 'pago':
        return Colors.green;
      case 'vencido':
        return Colors.red;
      case 'cancelado':
        return Colors.grey;
      default:
        return theme.colorScheme.primary;
    }
  }

  String _getLocalizedStatus(BuildContext context, String status) {
    switch (status) {
      case 'aberto':
        return S.of(context).open;
      case 'parcial':
        return S.of(context).partially_paid;
      case 'pago':
        return S.of(context).paid;
      case 'vencido':
        return S.of(context).overdue;
      case 'cancelado':
        return S.of(context).canceled;
      case 'todos':
        return S.of(context).all;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    // Cria o TabBar
    final tabBar = PreferredSize(
      preferredSize: Size.fromHeight(kToolbarHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
          indicatorColor: theme.colorScheme.primary,
          tabs: _filterOptions.map((filter) {
            final status = _getLocalizedStatus(context, filter);
            final color = _getStatusColor(filter, theme);

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter != 'todos')
                    Container(
                      width: 12,
                      height: 12,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(status),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );

    return ListTemplate<ContaPagar>(
      icon: Icons.attach_money,
      future: _contasPagarFuture,
      serviceName: _contaPagarService,
      moduleName: _moduleName,
      title: S.of(context).accounts_payable,
      appBarBottom: tabBar,
      itemTitleBuilder: (contaPagar) => '${currencySymbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valor)}',
      itemSubtitleBuilder: (contaPagar) {
        final status = _getLocalizedStatus(context, contaPagar.status);
        final statusColor = _getStatusColor(contaPagar.status, theme);
        final fornecedorNome = contaPagar.fornecedorId != null ?
        _nomesFornecedores[contaPagar.fornecedorId] ?? S.of(context).unknown_supplier : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status
            Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: _getStatusColor(contaPagar.status, theme),
                    width: 2.5
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          contaPagar.status == 'pago' ? Icons.check_circle :
                          contaPagar.status == 'parcial' ? Icons.timelapse :
                          contaPagar.status == 'vencido' ? Icons.error_outline :
                          Icons.circle_outlined,
                          color: _getStatusColor(contaPagar.status, theme),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            status.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getStatusColor(contaPagar.status, theme),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  }
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fornecedorNome.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                              SizedBox(width: 8),
                              Expanded(child: Text(fornecedorNome)),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Icon(Icons.event, size: 16, color: theme.colorScheme.primary),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                                '${S.of(context).due_date}: ${FormatacaoUtil.formatDate(contaPagar.dataVencimento)}'
                            ),
                          ),
                        ],
                      ),
                      if (contaPagar.numeroDocumento != null && contaPagar.numeroDocumento!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(Icons.receipt, size: 16, color: theme.colorScheme.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    '${S.of(context).document}: ${contaPagar.numeroDocumento}'
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),


            // Barra de progresso para pagamentos parciais
            if (contaPagar.status == 'parcial')
              Container(
                margin: EdgeInsets.only(top: 12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: contaPagar.valorPago / contaPagar.valor,
                      backgroundColor: Colors.grey.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                    ),
                    SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Se o espaço for muito limitado, use Column em vez de Row
                        if (constraints.maxWidth < 220) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${S.of(context).paid}: ${currencySymbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valorPago)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${S.of(context).remaining}: ${currencySymbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valor - contaPagar.valorPago)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          );
                        } else {
                          // Versão com Row para espaços maiores
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${S.of(context).paid}: ${currencySymbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valorPago)}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${S.of(context).remaining}: ${currencySymbol} ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valor - contaPagar.valorPago)}',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    )
                  ],
                ),
              ),

            // Botão registrar pagamento, mantido visível no card
            if (contaPagar.status != 'pago' && contaPagar.status != 'cancelado')
              Container(
                margin: EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _registrarPagamento(contaPagar),
                      icon: Icon(Icons.check_circle_outline, size: 16),
                      label: Text(S.of(context).register_payment),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
      itemExpandedContentWidgets: (contaPagar) {
        final List<Widget> widgets = [];
        final ThemeData theme = Theme.of(context);
        final currencySymbol = S.of(context).currency_symbol;

        // Obter nomes armazenados nos mapas
        final fornecedorNome = contaPagar.fornecedorId != null ?
        _nomesFornecedores[contaPagar.fornecedorId] : null;
        final contaPagamentoNome = contaPagar.contaId != null ?
        _nomesContasPagamento[contaPagar.contaId] : null;

        // Área de detalhes adicionais
        widgets.add(
          Container(
            padding: EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerColor,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título da seção
                Text(
                  S.of(context).related_information,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 12),

                // Meio de pagamento
                if (contaPagar.meioPagamento.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.payment, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).payment_method}: ${MeioPagamentoOptions.getLocalizedMeiosDePagamento(context)[contaPagar.meioPagamento] ?? contaPagar.meioPagamento}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Conta de pagamento
                if (contaPagar.contaId != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).payment_account}: ${contaPagamentoNome ?? contaPagar.contaId}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Fornecedor/Pessoa
                if (contaPagar.fornecedorId != null && contaPagar.fornecedorId!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).supplier}: ${fornecedorNome ?? S.of(context).unknown_supplier}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Data de emissão
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${S.of(context).issue_date}: ${FormatacaoUtil.formatDate(contaPagar.dataEmissao)}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // Número do documento
                if (contaPagar.numeroDocumento != null && contaPagar.numeroDocumento!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.receipt, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).document_number}: ${contaPagar.numeroDocumento}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Informações de parcela
                if (contaPagar.numeroParcela != null && contaPagar.totalParcelas != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.payments, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).installment}: ${contaPagar.numeroParcela}/${contaPagar.totalParcelas}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Categoria
                if (contaPagar.categoria.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.category, size: 16, color: theme.colorScheme.primary),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${S.of(context).category}: ${contaPagar.categoria}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Observações
                if (contaPagar.observacoes != null && contaPagar.observacoes!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 8, top: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).notes,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          contaPagar.observacoes!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );

        // Histórico de pagamentos, se aplicável
        if (contaPagar.status == 'parcial' || contaPagar.status == 'pago') {
          widgets.add(
            Container(
              padding: EdgeInsets.only(top: 16, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).payment_history,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (contaPagar.valorPago > 0)
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${S.of(context).paid_amount}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valorPago)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                          if (contaPagar.dataPagamento != null)
                            Padding(
                              padding: EdgeInsets.only(left: 24, top: 4),
                              child: Text(
                                '${S.of(context).payment_date}: ${FormatacaoUtil.formatDate(contaPagar.dataPagamento!)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return widgets;
      },
      itemLeadingIcon: Icons.receipt_long,
      cardDecoration: (contaPagar) => BoxDecoration(
        color: contaPagar.status != 'pago' &&
            contaPagar.status != 'cancelado' &&
            contaPagar.dataVencimento.isBefore(DateTime.now())
            ? Colors.red.withOpacity(0.1)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contaPagar.status == 'vencido'
              ? Colors.red.withOpacity(0.5)
              : theme.dividerColor.withOpacity(0.2),
          width: contaPagar.status == 'vencido' ? 1.5 : 1,
        ),
      ),
      loadingText: S.of(context).loading,
      errorText: S.of(context).error_loading,
      notFoundText: S.of(context).no_accounts_payable_found,
      onRefresh: _refreshContasPagar,
      showTutorial: _showTutorial,
      nomeTutorial: S.of(context).account_payable,
      nomeTutorialPlural: S.of(context).accounts_payable,
      isSelectMode: widget.isSelectMode,
      isSetMode: widget.isSetMode,
      viewScreenBuilder: (contaPagar) => ContaPagarScreen(contaPagar: contaPagar!),
      formScreenBuilder: (contaPagar) => ContaPagarFormScreen(contaPagar: contaPagar),
      onWillPop: () async => true,
    );
  }
}