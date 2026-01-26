import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/conta_pagar.dart';
import '../services/conta_pagar_service.dart';
import '../services/parceiro_service.dart';
import '../widgets/rubber_drawer.dart';

/// Screen for managing accounts payable (contas a pagar).
///
/// Displays a summary card with totals, a list of contas sorted by
/// due date, status chips (paid/pending/overdue), swipe-to-pay,
/// and batch payment functionality.
///
/// See RUBBER-19 for architecture.
class ContasPagarScreen extends StatefulWidget {
  const ContasPagarScreen({super.key});

  @override
  State<ContasPagarScreen> createState() => _ContasPagarScreenState();
}

class _ContasPagarScreenState extends State<ContasPagarScreen> {
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.contasPagarTitle),
        actions: [
          if (_selectionMode && _selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.payment),
              tooltip: l10n.contaPagarBaixaLote,
              onPressed: () => _showBatchPaymentDialog(context, l10n),
            ),
          if (!_selectionMode)
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: l10n.contaPagarBaixaLote,
              onPressed: () {
                setState(() {
                  _selectionMode = true;
                });
              },
            ),
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectedIds.clear();
                });
              },
            ),
        ],
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: Consumer2<ContaPagarService, ParceiroService>(
        builder: (context, contaService, parceiroService, child) {
          final contas = contaService.contas;

          if (contas.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.contasPagarEmpty,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, l10n, theme, contaService),
              const SizedBox(height: 16),
              ...contas.map((conta) => _buildContaCard(
                    context,
                    l10n,
                    theme,
                    conta,
                    parceiroService,
                  )),
            ],
          );
        },
      ),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  /// Summary card showing total pending, total paid, and overdue count.
  Widget _buildSummaryCard(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    ContaPagarService contaService,
  ) {
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final vencidasCount = contaService.vencidas.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  l10n.contasPagarTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: l10n.contaPagarPendente,
                    value: nf.format(contaService.totalPendente),
                    color: Colors.orange,
                    icon: Icons.schedule,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: l10n.contaPagarPago,
                    value: nf.format(contaService.totalPago),
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                ),
              ],
            ),
            if (vencidasCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$vencidasCount ${l10n.contaPagarVencido.toLowerCase()}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Individual conta card with status chip, parceiro name, value, and due date.
  Widget _buildContaCard(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    ContaPagar conta,
    ParceiroService parceiroService,
  ) {
    final nf = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final parceiro = parceiroService.getParceiro(conta.parceiroId);
    final parceiroNome = parceiro?.nome ?? l10n.unknownPartner;

    final statusLabel = conta.pago
        ? l10n.contaPagarPago
        : conta.isVencido
            ? l10n.contaPagarVencido
            : l10n.contaPagarPendente;
    final statusColor = conta.pago
        ? Colors.green
        : conta.isVencido
            ? Colors.red
            : Colors.orange;

    final isSelected = _selectedIds.contains(conta.id);

    Widget card = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _selectionMode
            ? () {
                setState(() {
                  if (!conta.pago) {
                    if (isSelected) {
                      _selectedIds.remove(conta.id);
                    } else {
                      _selectedIds.add(conta.id);
                    }
                  }
                });
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (_selectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: conta.pago
                        ? null
                        : (value) {
                            setState(() {
                              if (value == true) {
                                _selectedIds.add(conta.id);
                              } else {
                                _selectedIds.remove(conta.id);
                              }
                            });
                          },
                  ),
                ),
              CircleAvatar(
                backgroundColor: statusColor.withValues(alpha: 0.15),
                child: Text(
                  parceiroNome.isNotEmpty
                      ? parceiroNome[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      parceiroNome,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nf.format(conta.valor),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conta.pago
                          ? '${l10n.contaPagarVencimento}: ${dateFormat.format(conta.vencimento)}'
                          : l10n.contaPagarVenceEm(conta.diasParaVencer),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: conta.isVencido
                            ? Colors.red
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (conta.pago && conta.formaPagamento != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '${l10n.contaPagarFormaPagamento}: ${_formaLabel(l10n, conta.formaPagamento!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
                backgroundColor: statusColor.withValues(alpha: 0.1),
                side: BorderSide.none,
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ],
          ),
        ),
      ),
    );

    // Swipe right to mark as paid (only for unpaid contas, not in selection mode)
    if (!conta.pago && !_selectionMode) {
      card = Dismissible(
        key: ValueKey(conta.id),
        direction: DismissDirection.startToEnd,
        confirmDismiss: (_) async {
          return await _showPaymentDialog(context, l10n, conta.id);
        },
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 24),
          child: Row(
            children: [
              const Icon(Icons.check, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                l10n.contaPagarMarcarPago,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child: card,
      );
    }

    return card;
  }

  /// Shows dialog to select payment method and marks a single conta as paid.
  Future<bool> _showPaymentDialog(
    BuildContext context,
    BorrachaLocalizations l10n,
    String contaId,
  ) async {
    final forma = await _selectFormaPagamento(context, l10n);
    if (forma == null) return false;

    if (context.mounted) {
      await context.read<ContaPagarService>().marcarPago(
            contaId,
            forma: forma,
          );
    }
    return false; // Don't dismiss the card, the list will rebuild
  }

  /// Shows dialog for batch payment of selected contas.
  Future<void> _showBatchPaymentDialog(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) async {
    final forma = await _selectFormaPagamento(context, l10n);
    if (forma == null) return;

    if (context.mounted) {
      await context.read<ContaPagarService>().baixaEmLote(
            _selectedIds.toList(),
            forma: forma,
          );
      setState(() {
        _selectionMode = false;
        _selectedIds.clear();
      });
    }
  }

  /// Shows a dialog to select FormaPagamento.
  Future<FormaPagamento?> _selectFormaPagamento(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) async {
    return showDialog<FormaPagamento>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.contaPagarFormaPagamento),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pix),
              title: Text(l10n.contaPagarPix),
              onTap: () => Navigator.pop(context, FormaPagamento.pix),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance),
              title: Text(l10n.contaPagarTed),
              onTap: () => Navigator.pop(context, FormaPagamento.ted),
            ),
            ListTile(
              leading: const Icon(Icons.money),
              title: Text(l10n.contaPagarDinheiro),
              onTap: () => Navigator.pop(context, FormaPagamento.dinheiro),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns the localized label for a FormaPagamento.
  String _formaLabel(BorrachaLocalizations l10n, FormaPagamento forma) {
    switch (forma) {
      case FormaPagamento.pix:
        return l10n.contaPagarPix;
      case FormaPagamento.ted:
        return l10n.contaPagarTed;
      case FormaPagamento.dinheiro:
        return l10n.contaPagarDinheiro;
    }
  }
}

/// Small widget for summary card items.
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
