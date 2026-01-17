// lancamento_contabil_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:planejacampo/l10n/l10n.dart';
import 'package:planejacampo/models/contabil/conta_contabil.dart';
import 'package:planejacampo/models/contabil/lancamento_contabil.dart';
import 'package:planejacampo/services/app_state_manager.dart';
import 'package:planejacampo/services/contabil/conta_contabil_service.dart';
import 'package:planejacampo/services/contabil/lancamento_contabil_service.dart';
import 'package:planejacampo/utils/formatacao_util.dart';
import 'package:planejacampo/widgets/object_template.dart';
import 'package:planejacampo/widgets/single_screen_template.dart';
import 'package:provider/provider.dart';

import 'lancamento_contabil_form_screen.dart';

class LancamentoContabilScreen extends StatefulWidget {
  final LancamentoContabil lancamento;

  const LancamentoContabilScreen({
    Key? key,
    required this.lancamento,
  }) : super(key: key);

  @override
  _LancamentoContabilScreenState createState() => _LancamentoContabilScreenState();
}

class _LancamentoContabilScreenState extends State<LancamentoContabilScreen> {
  final String _moduleName = 'contabil';
  final LancamentoContabilService _lancamentoService = LancamentoContabilService();
  final ContaContabilService _contaContabilService = ContaContabilService();

  late Future<LancamentoContabil?> _futureLancamento;
  late bool _canEdit;
  late bool _canDelete;
  late LancamentoContabil _currentLancamento;
  Object _returnObject = '';
  bool _showTutorial = false;

  ContaContabil? _conta;
  List<LancamentoContabil>? _lancamentosLote;

  @override
  void initState() {
    super.initState();
    _currentLancamento = widget.lancamento;
    _loadData();
    _checkPermissions();

    final appStateManager = Provider.of<AppStateManager>(context, listen: false);
    _showTutorial = appStateManager.showTutorial('lancamentoContabilScreen');
    appStateManager.setShowTutorial('lancamentoContabilScreen', false);
  }

  void _loadData() {
    _loadLancamento();
    _loadRelatedData();
  }

  void _loadLancamento() {
    setState(() {
      _futureLancamento = _lancamentoService.getById(_currentLancamento.id);
    });
  }

  Future<void> _loadRelatedData() async {
    try {
      // Carregar conta contábil
      final conta = await _contaContabilService.getById(_currentLancamento.contaContabilId);
      if (mounted) setState(() => _conta = conta);

      // Carregar outros lançamentos do mesmo lote
      if (_currentLancamento.loteId != null) {
        final lancamentos = await _lancamentoService.getByAttributes({
          'loteId': _currentLancamento.loteId,
          'ativo': true,
        });
        if (mounted) setState(() => _lancamentosLote = lancamentos);
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

  void _navigateToFormScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LancamentoContabilFormScreen(lancamento: _currentLancamento),
      ),
    ).then((updatedLancamento) {
      if (updatedLancamento != null) {
        _returnObject = true;
        if (updatedLancamento is LancamentoContabil) {
          setState(() {
            _currentLancamento = updatedLancamento;
          });
        }
        _loadData();
      }
    });
  }

  Future<void> _estornarLancamento() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirm_reversal),
          content: Text(S.of(context).confirm_entry_reversal_message),
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

        // TODO: Implementar estorno via LancamentoContabilProjetadoService
        // await _lancamentoProjetadoService.registrarLancamentosOperacao(
        //   operacao: 'EstornoLancamento',
        //   ...
        // );

        Navigator.of(context).pop(); // Fechar diálogo de processamento

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).entry_reversed_successfully),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _returnObject = true;
        });

        Navigator.of(context).pop(true);
      } catch (e) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).error_reversing_entry(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getTipoColor(String tipo) {
    return tipo == 'Debito' ? Colors.red.shade700 : Colors.green.shade700;
  }

  IconData _getTipoIcon(String tipo) {
    return tipo == 'Debito' ? Icons.arrow_upward : Icons.arrow_downward;
  }

  Widget _buildLancamentoDetails(LancamentoContabil lancamento) {
    final theme = Theme.of(context);
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card principal com valor e tipo
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
                  // Ícone e tipo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getTipoIcon(lancamento.tipo),
                        color: _getTipoColor(lancamento.tipo),
                        size: 32,
                      ),
                      SizedBox(width: 8),
                      Text(
                        lancamento.tipo == 'Debito'
                            ? S.of(context).debit
                            : S.of(context).credit,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: _getTipoColor(lancamento.tipo),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Valor
                  Text(
                    '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(lancamento.valor)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getTipoColor(lancamento.tipo),
                    ),
                  ),
                  SizedBox(height: 8),

                  // Saldo após lançamento
                  Text(
                    '${S.of(context).balance_after}: $currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(lancamento.saldoAtual)}',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Informações da conta
            Text(
              S.of(context).account_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            if (_conta != null) ...[
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.account_balance,
                label: S.of(context).account,
                value: _conta!.nome,
              ),
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.tag,
                label: S.of(context).account_code,
                value: _conta!.codigo,
              ),
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.category,
                label: S.of(context).account_nature,
                value: _conta!.natureza,
              ),
            ],

            SizedBox(height: 24),

            // Informações do lançamento
            Text(
              S.of(context).entry_information,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.calendar_today,
              label: S.of(context).date,
              value: FormatacaoUtil.formatDate(lancamento.data),
            ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.access_time,
              label: S.of(context).timestamp,
              value: DateFormat('dd/MM/yyyy HH:mm:ss').format(lancamento.timestamp),
            ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.source,
              label: S.of(context).origin_type,
              value: lancamento.origemTipo,
            ),

            ObjectTemplate.buildInfoRow(
              context: context,
              icon: Icons.fingerprint,
              label: S.of(context).origin_id,
              value: lancamento.origemId,
            ),

            if (lancamento.loteId != null)
              ObjectTemplate.buildInfoRow(
                context: context,
                icon: Icons.group_work,
                label: S.of(context).batch,
                value: lancamento.loteId!,
              ),

            if (lancamento.descricao != null && lancamento.descricao!.isNotEmpty) ...[
              SizedBox(height: 24),
              Text(
                S.of(context).description,
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
                  lancamento.descricao!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],

            // Outros lançamentos do lote
            if (_lancamentosLote != null && _lancamentosLote!.length > 1) ...[
              SizedBox(height: 24),
              Text(
                S.of(context).related_entries,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 12),
              ..._lancamentosLote!
                  .where((l) => l.id != lancamento.id)
                  .map((l) => _buildLancamentoRelacionadoCard(l, theme))
                  .toList(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLancamentoRelacionadoCard(LancamentoContabil lancamento, ThemeData theme) {
    final locale = AppStateManager().appLocale.toString();
    final currencySymbol = NumberFormat.simpleCurrency(locale: locale).currencySymbol;

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _getTipoIcon(lancamento.tipo),
          color: _getTipoColor(lancamento.tipo),
        ),
        title: Text(
          '$currencySymbol ${FormatacaoUtil.formatNumberWithTwoDecimalPlaces(lancamento.valor)}',
          style: TextStyle(
            color: _getTipoColor(lancamento.tipo),
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(lancamento.descricao ?? ''),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LancamentoContabilScreen(lancamento: lancamento),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummarySection() {
    return FutureBuilder<LancamentoContabil?>(
      future: _futureLancamento,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text(S.of(context).error_loading));
        } else if (!snapshot.hasData) {
          return Center(child: Text(S.of(context).not_found));
        } else {
          final lancamento = snapshot.data!;
          return _buildLancamentoDetails(lancamento);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Não permitir edição de lançamentos automáticos
    final bool canEditThisEntry = _canEdit && _currentLancamento.origemTipo == 'manual';

    return SingleScreenTemplate(
      title: S.of(context).accounting_entry_details,
      moduleName: _moduleName,
      returnObject: _returnObject,
      onWillPop: () async => true,
      canEdit: canEditThisEntry,
      canDelete: false, // Usar estorno ao invés de deletar
      showTutorial: _showTutorial,
      onEditPressed: canEditThisEntry ? _navigateToFormScreen : null,
      summarySection: _buildSummarySection(),
      serviceName: _lancamentoService,
      itemIdValue: widget.lancamento.id,
      itemName: S.of(context).accounting_entry,
      fieldReference: 'lancamentoContabilId',
      cardSections: [],

      // Botão de estorno apenas para lançamentos que podem ser estornados
      additionalFloatingActionButtons: _currentLancamento.estornoId == null
          ? (BuildContext context) => [
        if (_canDelete)
          ObjectTemplate.buildCustomFloatingActionButton(
            context: context,
            onPressed: _estornarLancamento,
            icon: Icons.undo,
            text: S.of(context).reverse_entry,
            heroTag: 'estornarLancamento',
          ),
      ]
          : null,
    );
  }
}