import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/conta.dart';
import '../services/conta_service.dart';

/// CASH-23: Account management screen.
class ContasScreen extends StatefulWidget {
  const ContasScreen({super.key});

  @override
  State<ContasScreen> createState() => _ContasScreenState();
}

class _ContasScreenState extends State<ContasScreen> {
  final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final contas = ContaService.instance.contas;
    final ativos = ContaService.instance.contasAtivo;
    final passivos = ContaService.instance.contasPassivo;
    final patrimonio = ContaService.instance.patrimonioLiquido;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cashContasTitle),
      ),
      body: contas.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(l10n.cashContasEmpty, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddContaDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.cashContaNovaTitleDialog),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Net worth card
                Card(
                  color: patrimonio >= 0 ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.cashContaPatrimonio(_currencyFormat.format(patrimonio)),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: patrimonio >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Assets
                if (ativos.isNotEmpty) ...[
                  Text(l10n.cashContaAtivos,
                      style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...ativos.map((c) => _buildContaTile(c)),
                  const SizedBox(height: 16),
                ],

                // Liabilities
                if (passivos.isNotEmpty) ...[
                  Text(l10n.cashContaPassivos,
                      style: TextStyle(fontSize: 12, color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...passivos.map((c) => _buildContaTile(c)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContaDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContaTile(Conta conta) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: conta.cor.withValues(alpha: 0.15),
          child: Icon(conta.icone, color: conta.cor),
        ),
        title: Text(conta.nome),
        subtitle: conta.banco != null ? Text(conta.banco!) : null,
        trailing: Text(
          _currencyFormat.format(conta.saldoAtual),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: conta.saldoAtual >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  Future<void> _showAddContaDialog(BuildContext context) async {
    final l10n = CashLocalizations.of(context)!;
    final nomeController = TextEditingController();
    final bancoController = TextEditingController();
    final saldoController = TextEditingController();
    TipoConta selectedTipo = TipoConta.contaCorrente;

    final tipoLabels = {
      TipoConta.carteira: l10n.cashContaTipoCarteira,
      TipoConta.contaCorrente: l10n.cashContaTipoCorrente,
      TipoConta.poupanca: l10n.cashContaTipoPoupanca,
      TipoConta.cartaoCredito: l10n.cashContaTipoCartao,
      TipoConta.investimento: l10n.cashContaTipoInvestimento,
      TipoConta.emprestimo: l10n.cashContaTipoEmprestimo,
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.cashContaNovaTitleDialog),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nomeController,
                  decoration: InputDecoration(labelText: l10n.cashContaNome),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TipoConta>(
                  value: selectedTipo,
                  decoration: InputDecoration(labelText: l10n.cashContaTipo),
                  items: TipoConta.values.map((t) {
                    return DropdownMenuItem(value: t, child: Text(tipoLabels[t]!));
                  }).toList(),
                  onChanged: (v) => setDialogState(() => selectedTipo = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: saldoController,
                  decoration: InputDecoration(
                    labelText: l10n.cashContaSaldoInicial,
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bancoController,
                  decoration: InputDecoration(labelText: l10n.cashContaBanco),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancelarButton),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.salvarButton),
            ),
          ],
        ),
      ),
    );

    if (result == true && nomeController.text.isNotEmpty) {
      final saldo = double.tryParse(saldoController.text.replaceAll(',', '.')) ?? 0.0;
      final conta = Conta.create(
        nome: nomeController.text.trim(),
        tipo: selectedTipo,
        saldoInicial: saldo,
        banco: bancoController.text.isNotEmpty ? bancoController.text.trim() : null,
      );
      await ContaService.instance.add(conta);
      if (mounted) setState(() {});
    }
  }
}
