import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/recebivel.dart';
import '../services/recebivel_service.dart';
import '../widgets/rubber_drawer.dart';

/// Screen for managing receivables (recebíveis) in RuraRubber.
///
/// Displays a summary card with totals for this week/month,
/// a list of all receivables with status chips, and swipe-to-mark
/// functionality. Includes a FAB for creating new receivables.
///
/// See RUBBER-18 for architecture.
class RecebiveisScreen extends StatelessWidget {
  const RecebiveisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recebiveisTitle),
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: Consumer<RecebivelService>(
        builder: (context, service, child) {
          final recebiveis = service.recebiveis;

          if (recebiveis.isEmpty) {
            return _buildEmptyState(context, l10n, theme);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(context, l10n, theme, service),
              const SizedBox(height: 16),
              _buildReceivablesList(context, l10n, theme, service, recebiveis),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRecebivelSheet(context, l10n),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AgroBannerWidget(
        adUnitId: 'ca-app-pub-3109803084293083/5660030835',
      ),
    );
  }

  /// Empty state when no receivables exist.
  Widget _buildEmptyState(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.recebiveisEmpty,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Summary card showing totals for this week and this month.
  Widget _buildSummaryCard(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    RecebivelService service,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    final totalSemana = service.totalEstaSemana;
    final totalMes = service.totalEsteMes;
    final countSemana = service.vencidosEstaSemana.length;
    final countMes = service.vencidosEsteMes.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.aReceberCard,
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
                  child: _SummaryColumn(
                    label: l10n.estaSemana,
                    value: currencyFormat.format(totalSemana),
                    count: countSemana,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _SummaryColumn(
                    label: l10n.esteMes,
                    value: currencyFormat.format(totalMes),
                    count: countMes,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// List of all receivables with status chips and swipe-to-mark.
  Widget _buildReceivablesList(
    BuildContext context,
    BorrachaLocalizations l10n,
    ThemeData theme,
    RecebivelService service,
    List<Recebivel> recebiveis,
  ) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    return Column(
      children: recebiveis.map((recebivel) {
        final isPending = !recebivel.recebido;
        final isOverdue = isPending &&
            recebivel.dataPrevista.isBefore(
              DateTime.now().subtract(const Duration(days: 1)),
            );

        return Dismissible(
          key: Key(recebivel.id),
          direction: isPending
              ? DismissDirection.startToEnd
              : DismissDirection.none,
          confirmDismiss: (direction) async {
            if (!isPending) return false;
            return await _showConfirmReceivedDialog(context, l10n);
          },
          onDismissed: (_) {
            service.marcarRecebido(recebivel.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.recebido)),
            );
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 20),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check, color: Colors.white),
          ),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isPending
                    ? (isOverdue ? Colors.red : Colors.orange)
                    : Colors.green,
                child: Icon(
                  isPending
                      ? (isOverdue
                          ? Icons.warning_amber_rounded
                          : Icons.schedule)
                      : Icons.check,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                currencyFormat.format(recebivel.valor),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${l10n.dataPrevistaRecebimento}: ${dateFormat.format(recebivel.dataPrevista)}',
                  ),
                  if (recebivel.compradorNome != null &&
                      recebivel.compradorNome!.isNotEmpty)
                    Text(recebivel.compradorNome!),
                  if (recebivel.recebido && recebivel.dataRecebimento != null)
                    Text(
                      '${l10n.recebivelDataRecebimento}: ${dateFormat.format(recebivel.dataRecebimento!)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
              trailing: _StatusChip(
                label: isPending ? l10n.pendente : l10n.recebido,
                color: isPending
                    ? (isOverdue ? Colors.red : Colors.orange)
                    : Colors.green,
              ),
              onTap: isPending
                  ? () => _showMarkReceivedSheet(
                        context,
                        l10n,
                        recebivel,
                        service,
                      )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Confirmation dialog for swipe-to-mark.
  Future<bool?> _showConfirmReceivedDialog(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.recebivelConfirmarRecebido),
        content: Text(l10n.marcarRecebido),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.parceiroDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.recebido),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet to mark a receivable as received with optional date.
  void _showMarkReceivedSheet(
    BuildContext context,
    BorrachaLocalizations l10n,
    Recebivel recebivel,
    RecebivelService service,
  ) {
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.recebivelConfirmarRecebido,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                '${l10n.recebivelValor}: ${currencyFormat.format(recebivel.valor)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (recebivel.compradorNome != null &&
                  recebivel.compradorNome!.isNotEmpty)
                Text(
                  recebivel.compradorNome!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  service.marcarRecebido(recebivel.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.recebido)),
                  );
                },
                icon: const Icon(Icons.check),
                label: Text(l10n.marcarRecebido),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.parceiroDeleteCancel),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Bottom sheet for creating a new receivable.
  void _showCreateRecebivelSheet(
    BuildContext context,
    BorrachaLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CreateRecebivelForm(l10n: l10n),
    );
  }
}

/// Summary column widget for the summary card.
class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final int count;
  final Color color;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Status chip widget for receivable items.
class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide.none,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// Form for creating a new receivable via bottom sheet.
class _CreateRecebivelForm extends StatefulWidget {
  final BorrachaLocalizations l10n;

  const _CreateRecebivelForm({required this.l10n});

  @override
  State<_CreateRecebivelForm> createState() => _CreateRecebivelFormState();
}

class _CreateRecebivelFormState extends State<_CreateRecebivelForm> {
  final _formKey = GlobalKey<FormState>();
  final _valorController = TextEditingController();
  final _compradorController = TextEditingController();
  DateTime _dataPrevista = DateTime.now().add(const Duration(days: 30));

  @override
  void dispose() {
    _valorController.dispose();
    _compradorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final theme = Theme.of(context);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.registrarRecebivel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Value field
            TextFormField(
              controller: _valorController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: l10n.recebivelValor,
                prefixText: r'R$ ',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.fechamentoPriceRequired;
                }
                final parsed = double.tryParse(
                  value.replaceAll(',', '.'),
                );
                if (parsed == null || parsed <= 0) {
                  return l10n.fechamentoPriceInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Expected date field
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.dataPrevistaRecebimento,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(dateFormat.format(_dataPrevista)),
              ),
            ),
            const SizedBox(height: 16),

            // Buyer name (optional)
            TextFormField(
              controller: _compradorController,
              decoration: InputDecoration(
                labelText: l10n.compradorOpcional,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.pular),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _saveRecebivel,
                    child: Text(l10n.parceiroSaveButton),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dataPrevista,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _dataPrevista = picked;
      });
    }
  }

  Future<void> _saveRecebivel() async {
    if (!_formKey.currentState!.validate()) return;

    final valor = double.parse(
      _valorController.text.replaceAll(',', '.'),
    );
    final comprador = _compradorController.text.trim();

    final service = context.read<RecebivelService>();
    await service.criarRecebivel(
      entregaId: '',
      valor: valor,
      dataPrevista: _dataPrevista,
      compradorNome: comprador.isNotEmpty ? comprador : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.l10n.recebivelSalvo)),
      );
    }
  }
}
