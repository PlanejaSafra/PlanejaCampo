import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/receita_service.dart';
import '../services/conta_service.dart';
import '../helpers/categoria_icon_helper.dart';

/// CASH-24: Revenue management screen.
class ReceitasScreen extends StatelessWidget {
  const ReceitasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;
    final currencyFormat = NumberFormat.currency(
      locale: 'pt_BR', symbol: l10n.currencySymbol, decimalDigits: 2,
    );

    return Consumer<ReceitaService>(
      builder: (context, service, _) {
        final receitas = service.receitasDoMes;
        final total = service.totalDoMes;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.cashReceitasTitle)),
          body: Column(
            children: [
              // Monthly Total
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(l10n.cashReceitaTotalMes,
                        style: const TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(currencyFormat.format(total),
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: receitas.isEmpty
                    ? Center(child: Text(l10n.cashReceitasEmpty, style: const TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: receitas.length,
                        itemBuilder: (context, index) {
                          final r = receitas[index];
                          final cat = CategoriaService().getById(r.categoriaId);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (cat?.cor ?? Colors.green).withValues(alpha: 0.15),
                                child: Icon(CategoriaIconHelper.getIcon(cat?.icone), color: cat?.cor ?? Colors.green),
                              ),
                              title: Text(cat?.nome ?? 'Receita'),
                              subtitle: r.descricao != null ? Text(r.descricao!, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                              trailing: Text(currencyFormat.format(r.valor),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddReceitaDialog(context),
            backgroundColor: Colors.green,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        );
      },
    );
  }

  Future<void> _showAddReceitaDialog(BuildContext context) async {
    final l10n = CashLocalizations.of(context)!;
    final valorController = TextEditingController();
    final descricaoController = TextEditingController();

    final categoriasReceita = CategoriaService().getCategoriasReceita();
    if (categoriasReceita.isEmpty) return;

    String selectedCategoriaId = categoriasReceita.first.id;
    String? selectedContaId;
    final contas = ContaService.instance.contas;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.cashReceitaNovaTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: valorController,
                  decoration: InputDecoration(labelText: l10n.cashReceitaValor, prefixText: 'R\$ '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCategoriaId,
                  decoration: InputDecoration(labelText: l10n.cashReceitaCategoria),
                  items: categoriasReceita.map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.nome),
                  )).toList(),
                  onChanged: (v) => setDialogState(() => selectedCategoriaId = v!),
                ),
                if (contas.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    value: selectedContaId,
                    decoration: InputDecoration(labelText: l10n.cashReceitaContaDestino),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Nenhuma')),
                      ...contas.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome))),
                    ],
                    onChanged: (v) => setDialogState(() => selectedContaId = v),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: descricaoController,
                  decoration: InputDecoration(labelText: l10n.cashReceitaDescricao),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelarButton)),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.salvarButton)),
          ],
        ),
      ),
    );

    if (result == true) {
      final valor = double.tryParse(valorController.text.replaceAll(',', '.')) ?? 0;
      if (valor > 0) {
        await ReceitaService.instance.quickAdd(
          valor: valor,
          categoriaId: selectedCategoriaId,
          descricao: descricaoController.text.isNotEmpty ? descricaoController.text.trim() : null,
          contaDestinoId: selectedContaId,
        );
      }
    }
  }
}
