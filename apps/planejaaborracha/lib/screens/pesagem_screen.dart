import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'fechamento_entrega_screen.dart';
import 'lista_entregas_screen.dart';
import '../services/parceiro_service.dart';
import '../services/entrega_service.dart';
import '../widgets/big_calculator_keypad.dart';
import '../widgets/tape_view_widget.dart';

class PesagemScreen extends StatefulWidget {
  const PesagemScreen({super.key});

  @override
  State<PesagemScreen> createState() => _PesagemScreenState();
}

class _PesagemScreenState extends State<PesagemScreen> {
  String? _selectedParceiroId;
  String _currentInput = '';

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pesagemTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const ListaEntregasScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: l10n.fechamentoTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const FechamentoEntregaScreen()),
              );
            },
          )
        ],
      ),
      drawer: AgroDrawer(
          appName: 'PlanejaBorracha',
          versionText: '1.0.0',
          onNavigate: (route) {
            if (route == 'home') route = 'pesagem';
            if (route == 'properties')
              route =
                  'parceiros'; // Map properties to partners? Or keep distinct?
            // For now, map simple keys. The drawer callback expects us to handle keys.
            // Standard keys: home, properties, settings, about.
            // We can just push named routes.
            if (route == 'home')
              Navigator.pushReplacementNamed(context, '/pesagem');
            if (route == 'properties')
              Navigator.pushReplacementNamed(context, '/parceiros');
            if (route == 'mercado')
              Navigator.pushReplacementNamed(context, '/mercado');
          },
          extraItems: [
            AgroDrawerItem(icon: Icons.store, title: l10n.drawerMercado, key: 'mercado'),
          ]),
      body: Consumer2<ParceiroService, EntregaService>(
        builder: (context, parceiroService, entregaService, child) {
          final parceiros = parceiroService.parceiros;

          if (parceiros.isEmpty) {
            return Center(child: Text(l10n.pesagemNoPartnersError));
          }

          // Auto-select first if none selected
          if (_selectedParceiroId == null) {
            _selectedParceiroId = parceiros.first.id;
          }

          final currentWeighings =
              entregaService.getPesagensForParceiro(_selectedParceiroId!);

          return Column(
            children: [
              // 1. Partner Select Header
              Container(
                color: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: parceiros.length,
                    itemBuilder: (context, index) {
                      final p = parceiros[index];
                      final isSelected = p.id == _selectedParceiroId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedParceiroId = p.id;
                            _currentInput = ''; // Clear input on switch
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: isSelected
                                ? Border.all(color: Colors.orange, width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    isSelected ? Colors.orange : Colors.grey,
                                child: Text(p.nome[0],
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.nome,
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.black : Colors.white,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. Tape View / Accumulator
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: TapeViewWidget(
                          entries: currentWeighings,
                          onDeleteLast: () => entregaService
                              .undoLastPesagem(_selectedParceiroId!),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Current Input Display
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              _currentInput.isEmpty ? '0' : _currentInput,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 32,
                                fontFamily: 'Monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              ' kg',
                              style: TextStyle(
                                  color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Keypad
              Expanded(
                flex: 5,
                child: BigCalculatorKeypad(
                  onDigitPress: (digit) {
                    setState(() {
                      if (_currentInput.length < 6) {
                        // Max 6 digits
                        if (digit == '.' && _currentInput.contains('.')) {
                          return;
                        }
                        _currentInput += digit;
                      }
                    });
                  },
                  onClear: () {
                    setState(() {
                      if (_currentInput.isNotEmpty) {
                        // Backspace logic instead of clear all?
                        // User wants "C" usually clearing current entry
                        _currentInput = '';
                      }
                    });
                  },
                  onAdd: () {
                    if (_currentInput.isEmpty) {
                      return;
                    }
                    final weight = double.tryParse(_currentInput);
                    if (weight != null && weight > 0) {
                      entregaService.addPesagem(_selectedParceiroId!, weight);
                      setState(() {
                        _currentInput = '';
                      });
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
