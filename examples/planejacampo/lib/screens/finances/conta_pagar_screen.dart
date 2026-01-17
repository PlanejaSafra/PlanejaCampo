import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta.dart';
import 'package:planejacampo/models/contabil/conta_pagar.dart';
import 'package:planejacampo/models/pessoa.dart';
import 'package:planejacampo/screens/finances/conta_pagar_form_screen.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_pagar_service.dart';
import 'package:planejacampo/services/contabil/conta_service.dart';
import 'package:planejacampo/services/pessoa_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/card_section.dart';
import 'package:planejacampo/widgets/dialog_screen.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:provider/provider.dart';

class ContaPagarScreen extends StatefulWidget {
  final ContaPagar contaPagar;

  const ContaPagarScreen({
    Key? key,
    required this.contaPagar,
  }) : super(key: key);

  @override
  _ContaPagarScreenState createState() => _ContaPagarScreenState();
}

class _ContaPagarScreenState extends State<ContaPagarScreen> {
  final String _moduleName = 'bancos';
  final ContaPagarService _contaPagarService = ContaPagarService();
  final PessoaService _pessoaService = PessoaService();
  final ContaService _contaService = ContaService();

  late Future<ContaPagar?> _futureContaPagar;
  late bool _canEdit;
  late bool _canDelete;
  late ContaPagar _currentContaPagar;
  Object _returnObject = '';
  bool _showTutorial = false;
  bool _isExpanded = false;

  Pessoa? _fornecedor;
  Conta? _conta;

  // Keys para tutorial
  final GlobalKey _pagamentoSectionKey = GlobalKey();
  final GlobalKey _registrarPagamentoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentContaPagar = widget.contaPagar;
    _loadData();
    _checkPermissions();

    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('contaPagarScreen');
    appStateManager.setShowTutorial('contaPagarScreen', false);
  }

  void _loadData() {
    _loadContaPagar();
    _loadRelatedData();
  }

  void _loadContaPagar() {
    setState(() {
      _futureContaPagar = _contaPagarService.getById(_currentContaPagar.id);
    });
  }

  Future<void> _loadRelatedData() async {
    try {
      if (_currentContaPagar.fornecedorId != null && _currentContaPagar.fornecedorId!.isNotEmpty) {
        final fornecedor = await _pessoaService.getById(_currentContaPagar.fornecedorId!);
        if (mounted) setState(() => _fornecedor = fornecedor);
      }

      if (_currentContaPagar.contaId != null && _currentContaPagar.contaId!.isNotEmpty) {
        final conta = await _contaService.getById(_currentContaPagar.contaId!);
        if (mounted) setState(() => _conta = conta);
      }
    } catch (e) {
      print('Erro ao carregar dados relacionados: $e');
    }
  }


  void _checkPermissions() {
    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    setState(() {
      _canEdit = appStateManager.canEdit(_moduleName);
      _canDelete = appStateManager.canDelete(_moduleName);
    });
  }

  bool _toggleFloatingActionButton() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    return _isExpanded;
  }

  Future<void> _registrarPagamento(ContaPagar contaPagar) async {
    // Verifica se já está pago
    if (contaPagar.status == 'pago') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).account_already_paid)),
      );
      return;
    }

    // Calcula o valor restante
    final valorRestante = contaPagar.valor - contaPagar.valorPago;

    try {
      // Exibe o diálogo para input do valor a pagar
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (BuildContext context) {
          final TextEditingController valorController = TextEditingController(
              text: FormatacaoUtil.formatNumberWithTwoDecimalPlaces(valorRestante)
          );
          final locale = AppStateManager().appLocale.toString();
          final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

          return AlertDialog(
            title: Text(S.of(context).register_payment),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${S.of(context).remaining_amount}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(valorRestante)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: valorController,
                  decoration: InputDecoration(
                    labelText: S.of(context).payment_amount,
                    prefixText: currencySymbol,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(S.of(context).cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  try {
                    double valor = double.parse(valorController.text.replaceAll(',', '.'));
                    if (valor <= 0 || valor > valorRestante) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.of(context).invalid_payment_amount)),
                      );
                      return;
                    }
                    Navigator.of(context).pop({
                      'valor': valor,
                      'data': DateTime.now(),
                    });
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.of(context).invalid_payment_amount)),
                    );
                  }
                },
                child: Text(S.of(context).confirm),
              ),
            ],
          );
        },
      );

      if (result != null) {
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

        // Registra o pagamento
        await _contaPagarService.registrarPagamento(
          contaPagar.id,
          result['valor'],
          dataPagamento: result['data'],
        );

        // Fecha o diálogo de processamento
        Navigator.of(context).pop();

        // Atualiza os dados
        _loadData();

        // Mostra confirmação de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).payment_registered_successfully),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _returnObject = true;
        });
      }
    } catch (e) {
      // Garante que o diálogo de processamento seja fechado
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

  Future<void> _cancelarContaPagar(ContaPagar contaPagar) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_cancellation),
          content: Text(S.of(context).confirm_account_payable_cancellation),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(S.of(context).confirm),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
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

        await _contaPagarService.cancelarContaPagar(contaPagar.id);

        // Fecha o diálogo de processamento
        Navigator.of(context).pop();

        // Atualiza os dados
        _loadData();

        // Mostra confirmação de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).account_payable_cancelled_successfully),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _returnObject = true;
        });
      } catch (e) {
        // Garante que o diálogo de processamento seja fechado
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_cancelling_account_payable(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ContaPagarFormScreen(contaPagar: _currentContaPagar),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    ).then((updatedContaPagar) {
      if (updatedContaPagar != null) {
        _returnObject = true;
        if (updatedContaPagar is ContaPagar) {
          setState(() {
            _currentContaPagar = updatedContaPagar;
          });
        }
        _loadData();
      }
    });
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
      default:
        return status;
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

  Map<String, Map<String, dynamic>> _buildCustomTutorialSteps() {
    return {
      'pagamentoSection': {
        'key': _pagamentoSectionKey,
        'message': S.of(context).payment_details_info,
        'shape': 'RRect',
        'align': 'ContentAlign.top',
      },
    };
  }

  Map<String, Map<String, dynamic>> _buildActionTutorialSteps() {
    return {
      'registrarPagamento': {
        'key': _registrarPagamentoKey,
        'message': S.of(context).register_payment_with_this_button,
        'shape': 'Circle',
        'align': 'ContentAlign.top',
      },
    };
  }

  Widget _buildContaPagarDetails(ContaPagar contaPagar) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;
    final status = _getLocalizedStatus(context, contaPagar.status);
    final statusColor = _getStatusColor(contaPagar.status, theme);
    final bool isVencido = contaPagar.status != 'pago' &&
        contaPagar.status != 'cancelado' &&
        contaPagar.dataVencimento.isBefore(DateTime.now());

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status e valor principal
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isVencido ? Icons.warning :
                          contaPagar.status == 'pago' ? Icons.check_circle :
                          contaPagar.status == 'cancelado' ? Icons.cancel :
                          Icons.pending,
                          color: statusColor,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),

                  // Valor principal
                  Text(
                    '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valor)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Progresso de pagamento para pagamentos parciais
                  if (contaPagar.status == 'parcial')
                    Column(
                      children: [
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: contaPagar.valorPago / contaPagar.valor,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${S.of(context).paid}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valorPago)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '${S.of(context).remaining}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(contaPagar.valor - contaPagar.valorPago)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Informações básicas
            Text(
              S.of(context).basic_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            if (_fornecedor != null)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.business,
                label: S.of(context).supplier,
                value: _fornecedor!.nome,
              ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.calendar_today,
              label: S.of(context).issue_date,
              value: FormatacaoUtil.formatDate(contaPagar.dataEmissao),
            ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.event,
              label: S.of(context).due_date,
              value: FormatacaoUtil.formatDate(contaPagar.dataVencimento),
            ),

            if (contaPagar.dataPagamento != null)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.check_circle,
                label: S.of(context).payment_date,
                value: FormatacaoUtil.formatDate(contaPagar.dataPagamento!),
              ),

            if (contaPagar.numeroDocumento != null && contaPagar.numeroDocumento!.isNotEmpty)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.receipt,
                label: S.of(context).document_number,
                value: contaPagar.numeroDocumento!,
              ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.payment,
              label: S.of(context).payment_method,
              value: contaPagar.meioPagamento,
            ),

            if (_conta != null)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.account_balance,
                label: S.of(context).account,
                value: _conta!.nome,
              ),

            if (contaPagar.numeroParcela != null && contaPagar.totalParcelas != null)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.view_list,
                label: S.of(context).installment,
                value: '${contaPagar.numeroParcela}/${contaPagar.totalParcelas}',
              ),

            SizedBox(height: 24),

            // Informações relacionadas
            Text(
              S.of(context).related_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.category,
              label: S.of(context).category,
              value: contaPagar.categoria,
            ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.source,
              label: S.of(context).origin,
              value: contaPagar.origemTipo,
            ),

            if (contaPagar.observacoes != null && contaPagar.observacoes!.isNotEmpty) ...[
              SizedBox(height: 24),

              Text(
                S.of(context).notes,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  contaPagar.observacoes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            SizedBox(height: 24),


          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<ContaPagar?>(
      future: _futureContaPagar,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final contaPagar = snapshot.data!;
          return _buildContaPagarDetails(contaPagar);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleScreenTemplate(
      title: S.of(context).account_payable_details,
      moduleName: _moduleName,
      returnObject: _returnObject,
      onWillPop: () async {
        return true;
      },
      canEdit: _canEdit,
      canDelete: _canDelete,
      showTutorial: _showTutorial,
      isExpanded: _isExpanded,
      onFloatingActionButtonPressed: _toggleFloatingActionButton,
      onEditPressed: _canEdit ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _contaPagarService,
      itemIdValue: widget.contaPagar.id,
      itemName: S.of(context).account_payable,
      fieldReference: 'contaPagarId',
      cardSections: [], // Lista vazia de CardSections
      customTutorialSteps: _buildCustomTutorialSteps(),
      customActionTutorialSteps: _buildActionTutorialSteps(),
      additionalFloatingActionButtons: (BuildContext context) => [
        if (!['pago', 'cancelado'].contains(_currentContaPagar.status))
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _registrarPagamento(_currentContaPagar);
            },
            icon: Icons.payment,
            text: S.of(context).register_payment,
            key: _registrarPagamentoKey,
            heroTag: 'registrarPagamento',
          ),
        if (_canEdit && _currentContaPagar.status != 'cancelado')
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: () {
              _toggleFloatingActionButton();
              _cancelarContaPagar(_currentContaPagar);
            },
            icon: Icons.cancel,
            text: S.of(context).cancel_account,
            heroTag: 'cancelarContaPagar',
          ),
      ],


    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}