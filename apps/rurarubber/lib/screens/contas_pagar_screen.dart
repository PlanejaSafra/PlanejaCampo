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
/// swipe-to-delete, long-press-to-edit, FAB for creating new contas,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateContaSheet(context, l10n),
        tooltip: l10n.contaPagarAddButton,
        child: const Icon(Icons.add),
      ),
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
        onLongPress: (!_selectionMode && !conta.pago)
            ? () => _showEditContaSheet(context, l10n, conta)
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

    // Swipe right to mark as paid, swipe left to delete (only for unpaid contas, not in selection mode)
    if (!conta.pago && !_selectionMode) {
      card = Dismissible(
        key: ValueKey(conta.id),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            return await _showPaymentDialog(context, l10n, conta.id);
          } else {
            final confirmed = await _showDeleteContaDialog(context, l10n);
            if (confirmed && context.mounted) {
              await context.read<ContaPagarService>().deleteConta(conta.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.contaPagarDeleted)),
                );
              }
            }
            return false; // Don't dismiss, the list rebuilds
          }
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
        secondaryBackground: Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                l10n.excluirLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.delete, color: Colors.white),
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

  /// Shows confirmation dialog for deleting a conta.
  Future<bool> _showDeleteContaDialog(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.contaPagarDeleteTitle),
        content: Text(l10n.contaPagarDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parceiroDeleteCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l10n.parceiroDeleteConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Opens bottom sheet to create a new conta a pagar.
  void _showCreateContaSheet(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const _CreateContaForm(),
      ),
    );
  }

  /// Opens bottom sheet to edit an existing conta a pagar.
  void _showEditContaSheet(
    BuildContext context,
    BorrachaLocalizations l10n,
    ContaPagar conta,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _EditContaForm(conta: conta),
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

/// Form widget for creating a new conta a pagar.
class _CreateContaForm extends StatefulWidget {
  const _CreateContaForm();

  @override
  State<_CreateContaForm> createState() => _CreateContaFormState();
}

class _CreateContaFormState extends State<_CreateContaForm> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  String? _selectedParceiroId;
  DateTime _vencimento = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vencimento,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _vencimento = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParceiroId == null) return;

    final valor = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    if (valor == null || valor <= 0) return;

    await context.read<ContaPagarService>().criarConta(
          parceiroId: _selectedParceiroId!,
          valor: valor,
          vencimento: _vencimento,
        );

    if (mounted) {
      final l10n = BorrachaLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contaPagarSaved)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final parceiros = context.read<ParceiroService>().parceiros;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.contaPagarAddButton,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedParceiroId,
              decoration: InputDecoration(
                labelText: l10n.parceirosTitle,
                border: const OutlineInputBorder(),
              ),
              items: parceiros
                  .map((p) => DropdownMenuItem(
                        value: p.id,
                        child: Text(p.nome),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedParceiroId = value;
                });
              },
              validator: (value) =>
                  value == null ? l10n.parceiroNomeRequired : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: l10n.contaPagarValorLabel,
                prefixText: 'R\$ ',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.parceiroNomeRequired;
                }
                final parsed =
                    double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return l10n.parceiroNomeRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.contaPagarVencimento,
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat.format(_vencimento)),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancelarButton),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.salvarButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Form widget for editing an existing conta a pagar.
class _EditContaForm extends StatefulWidget {
  final ContaPagar conta;

  const _EditContaForm({required this.conta});

  @override
  State<_EditContaForm> createState() => _EditContaFormState();
}

class _EditContaFormState extends State<_EditContaForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valorController;
  late DateTime _vencimento;

  @override
  void initState() {
    super.initState();
    _valorController = TextEditingController(
      text: widget.conta.valor.toStringAsFixed(2),
    );
    _vencimento = widget.conta.vencimento;
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _vencimento,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _vencimento = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.tryParse(
      _valorController.text.replaceAll(',', '.'),
    );
    if (valor == null || valor <= 0) return;

    await context.read<ContaPagarService>().updateConta(
          id: widget.conta.id,
          valor: valor,
          vencimento: _vencimento,
        );

    if (mounted) {
      final l10n = BorrachaLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contaPagarUpdated)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.contaPagarEditTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _valorController,
              decoration: InputDecoration(
                labelText: l10n.contaPagarValorLabel,
                prefixText: 'R\$ ',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.parceiroNomeRequired;
                }
                final parsed =
                    double.tryParse(value.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return l10n.parceiroNomeRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.contaPagarVencimento,
                  border: const OutlineInputBorder(),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateFormat.format(_vencimento)),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancelarButton),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _save,
                  child: Text(l10n.salvarButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
