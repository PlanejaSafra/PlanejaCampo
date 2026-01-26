import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/centro_custo.dart';
import '../services/centro_custo_service.dart';
import '../widgets/cash_drawer.dart';

/// Screen for managing cost centers.
class CentroCustoScreen extends StatelessWidget {
  const CentroCustoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = CashLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.centroCustoTitle),
      ),
      drawer: buildCashDrawer(context: context, l10n: l10n),
      body: Consumer<CentroCustoService>(
        builder: (context, service, _) {
          final centros = service.centros;

          if (centros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.centroCustoEmpty,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: centros.length,
            itemBuilder: (context, index) {
              final centro = centros[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: centro.cor.withValues(alpha: 0.2),
                    child: Icon(Icons.folder, color: centro.cor),
                  ),
                  title: Text(
                    centro.nome,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: centro.appVinculado != null
                      ? Text(centro.appVinculado!)
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDelete(context, centro, l10n),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, l10n),
        backgroundColor: Colors.green,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(BuildContext context, CashLocalizations l10n) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.centroCustoAdd,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.centroCustoNome,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.centroCustoNomeRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    CentroCustoService.instance.createCentroCusto(
                      nome: controller.text.trim(),
                    );
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(l10n.centroCustoSave),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, CentroCusto centro, CashLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.centroCustoDelete),
        content: Text(l10n.centroCustoDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelarButton),
          ),
          TextButton(
            onPressed: () {
              CentroCustoService.instance.deleteCentroCusto(centro.id);
              Navigator.pop(ctx);
            },
            child: Text(
              l10n.despesaDeleteConfirm,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
