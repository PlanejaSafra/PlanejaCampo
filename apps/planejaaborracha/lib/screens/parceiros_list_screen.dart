import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../services/parceiro_service.dart';
import 'parceiro_form_screen.dart';

class ParceirosListScreen extends StatefulWidget {
  const ParceirosListScreen({super.key});

  @override
  State<ParceirosListScreen> createState() => _ParceirosListScreenState();
}

class _ParceirosListScreenState extends State<ParceirosListScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.parceirosTitle),
      ),
      drawer: AgroDrawer(
        appName: 'PlanejaBorracha',
        versionText: '1.0.0',
        onNavigate: (route) =>
            Navigator.pushReplacementNamed(context, '/$route'),
      ),
      body: Consumer<ParceiroService>(
        builder: (context, service, child) {
          final parceiros = service.parceiros;

          if (parceiros.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.parceirosEmpty,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    label: l10n.parceiroAddButton,
                    onPressed: () => _navigateToForm(context),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: parceiros.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final parceiro = parceiros[index];
              return CustomCard(
                onTap: () => _navigateToForm(context, parceiroId: parceiro.id),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(parceiro.nome[0].toUpperCase()),
                  ),
                  title: Text(parceiro.nome),
                  subtitle:
                      Text('${parceiro.percentualPadrao.toStringAsFixed(0)}%'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const AgroBannerWidget(),
    );
  }

  void _navigateToForm(BuildContext context, {String? parceiroId}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ParceiroFormScreen(parceiroId: parceiroId),
      ),
    );
  }
}
