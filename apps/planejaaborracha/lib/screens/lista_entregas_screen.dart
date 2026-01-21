import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:intl/intl.dart';
import '../services/entrega_service.dart';
import '../models/entrega.dart';
import 'fechamento_entrega_screen.dart';

class ListaEntregasScreen extends StatelessWidget {
  const ListaEntregasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Entregas'),
      ),
      body: Consumer<EntregaService>(
        builder: (context, service, child) {
          final entregas = service.entregas;

          if (entregas.isEmpty) {
            return const Center(
              child: Text('Nenhuma entrega registrada.'),
            );
          }

          final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

          return ListView.builder(
            itemCount: entregas.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final entrega = entregas[index];
              final isOpen = entrega.status == 'Aberto';

              return CustomCard(
                onTap: () {
                  // If open, go to closing? Or details?
                  // For now, simple view or re-open logic could go here
                  // Showing dialog for simplicity
                  _showEntregaDetails(context, entrega, dateFormat);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isOpen ? Colors.orange : Colors.green,
                    child: Icon(isOpen ? Icons.edit : Icons.check,
                        color: Colors.white),
                  ),
                  title: Text(dateFormat.format(entrega.data)),
                  subtitle: Text('${entrega.itens.length} parceiros atendidos'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${entrega.pesoTotalGeral.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        entrega.status,
                        style: TextStyle(
                          color: isOpen ? Colors.orange : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showEntregaDetails(
      BuildContext context, Entrega entrega, DateFormat fmt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Entrega ${fmt.format(entrega.data)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${entrega.status}'),
            Text('Total Peso: ${entrega.pesoTotalGeral.toStringAsFixed(1)} kg'),
            const SizedBox(height: 16),
            const Text('Parceiros:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...entrega.itens.map(
                (i) => Text('- ???: ${i.pesoTotal.toStringAsFixed(1)} kg')),
            // Note: To show names here we need ParceiroService, skipping for brevity in dialog
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
          if (entrega.status == 'Aberto')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Set as current and go to Weighing?
                // Or go to Closing directly
                // Ideally EntregaService should support 'resumeEntrega(id)'
                // For now let's just go to Closing for review
                // We need to set it as active in service first?
                // Current simple service uses _currentEntrega.
                // Let's assume user wants to reprint receipt or check values.
                // We can navigate to Fechamento with this entrega if we pass it,
                // but Fechamento uses provider.currentEntrega.
                // GAP: FechamentoScreen depends on 'currentEntrega'.
                // Let's fix this in EntregaService to allow setting active.
                context.read<EntregaService>().resumeEntrega(entrega);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const FechamentoEntregaScreen()));
              },
              child: const Text('Continuar/Fechar'),
            )
        ],
      ),
    );
  }
}
