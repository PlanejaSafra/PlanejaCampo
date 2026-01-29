import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/conta.dart';
import '../services/conta_service.dart';

/// CASH-29: Bank reconciliation screen.
/// Allows comparing app balance with bank statement balance.
class ReconciliacaoScreen extends StatefulWidget {
  const ReconciliacaoScreen({super.key});

  @override
  State<ReconciliacaoScreen> createState() => _ReconciliacaoScreenState();
}

class _ReconciliacaoScreenState extends State<ReconciliacaoScreen> {
  Conta? _selectedConta;
  final _extratoController = TextEditingController();
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR', symbol: 'R\$', decimalDigits: 2,
  );

  @override
  void dispose() {
    _extratoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final contas = ContaService.instance.contas;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cashReconciliacaoTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account selector
            DropdownButtonFormField<String>(
              value: _selectedConta?.id,
              decoration: InputDecoration(labelText: l10n.cashContasTitle),
              items: contas.map((c) => DropdownMenuItem(
                value: c.id,
                child: Text('${c.nome} - ${_currencyFormat.format(c.saldoAtual)}'),
              )).toList(),
              onChanged: (id) {
                setState(() {
                  _selectedConta = id != null ? ContaService.instance.getConta(id) : null;
                });
              },
            ),
            const SizedBox(height: 24),

            if (_selectedConta == null)
              Expanded(
                child: Center(
                  child: Text(l10n.cashReconciliacaoEmpty, style: const TextStyle(color: Colors.grey)),
                ),
              )
            else ...[
              // Current app balance
              Card(
                child: ListTile(
                  leading: Icon(_selectedConta!.icone, color: _selectedConta!.cor),
                  title: Text(_selectedConta!.nome),
                  subtitle: Text(l10n.cashContaSaldo(_currencyFormat.format(_selectedConta!.saldoAtual))),
                ),
              ),
              const SizedBox(height: 16),

              // Statement balance input
              TextField(
                controller: _extratoController,
                decoration: InputDecoration(
                  labelText: l10n.cashReconciliacaoSaldoExtrato,
                  prefixText: 'R\$ ',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Difference
              Builder(builder: (context) {
                final extratoValor = double.tryParse(
                    _extratoController.text.replaceAll(',', '.')) ?? 0;
                final diff = _selectedConta!.saldoAtual - extratoValor;

                return Card(
                  color: diff.abs() < 0.01 ? Colors.green.shade50 : Colors.orange.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.cashReconciliacaoDiferenca(_currencyFormat.format(diff)),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: diff.abs() < 0.01 ? Colors.green : Colors.orange.shade800,
                          ),
                        ),
                        if (diff.abs() < 0.01)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final extratoValor = double.tryParse(
                        _extratoController.text.replaceAll(',', '.'));
                    if (extratoValor == null || _selectedConta == null) return;

                    // Adjust balance to match statement
                    final updated = _selectedConta!.copyWith(saldoAtual: extratoValor);
                    await ContaService.instance.update(_selectedConta!.id, updated);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.cashReconciliacaoOk),
                          backgroundColor: Colors.green,
                        ),
                      );
                      setState(() {
                        _selectedConta = ContaService.instance.getConta(_selectedConta!.id);
                        _extratoController.clear();
                      });
                    }
                  },
                  icon: const Icon(Icons.check),
                  label: Text(l10n.cashReconciliacaoConfirmar),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
