import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CriarOfertaScreen extends StatefulWidget {
  const CriarOfertaScreen({super.key});

  @override
  State<CriarOfertaScreen> createState() => _CriarOfertaScreenState();
}

class _CriarOfertaScreenState extends State<CriarOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _buyerNameController = TextEditingController();
  final _priceDrcController = TextEditingController();
  final _priceWetController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _regionController = TextEditingController(text: 'Rio Preto'); // Default
  final _phoneController = TextEditingController(); // Contact for WhatsApp

  bool _isLoading = false;

  @override
  void dispose() {
    _buyerNameController.dispose();
    _priceDrcController.dispose();
    _priceWetController.dispose();
    _conditionsController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _publishOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = BorrachaLocalizations.of(context)!;
    try {
      final drc = double.parse(_priceDrcController.text.replaceAll(',', '.'));
      final wet = _priceWetController.text.isNotEmpty
          ? double.parse(_priceWetController.text.replaceAll(',', '.'))
          : null;

      final offerData = {
        'buyerId': 'mock_buyer_id', // In real app, use Auth User ID
        'buyerName': _buyerNameController.text,
        'regions': [_regionController.text], // List of regions
        'priceDrc': drc,
        'priceWet': wet,
        'conditions': _conditionsController.text,
        'contactPhone': _phoneController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'validUntil':
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
      };

      await FirebaseFirestore.instance
          .collection('market_offers')
          .add(offerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.criarOfertaSuccess)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.criarOfertaError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.criarOfertaTitle)),
      drawer: AgroDrawer(
        appName: 'RuraRubber',
        versionText: '1.0.0',
        onNavigate: (route) {
          switch (route) {
            case 'home':
              Navigator.pushReplacementNamed(context, '/pesagem');
              break;
            case 'properties':
              Navigator.pushReplacementNamed(context, '/parceiros');
              break;
            case 'mercado':
              Navigator.pushReplacementNamed(context, '/mercado');
              break;
            case 'settings':
              Navigator.pushNamed(context, '/settings');
              break;
            case 'about':
              showAboutDialog(
                context: context,
                applicationName: 'RuraRubber',
                applicationVersion: '1.0.0',
                applicationIcon: const Icon(Icons.forest, size: 48),
                children: [
                  const Text(
                      'Gerencie suas entregas e acompanhe a produção de borracha'),
                ],
              );
              break;
          }
        },
        extraItems: [
          AgroDrawerItem(
              icon: Icons.store, title: l10n.drawerMercado, key: 'mercado'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mercadoBuyerRole,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buyerNameController,
                      decoration: InputDecoration(
                          labelText: l10n.criarOfertaTitleField,
                          border: const OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? l10n.criarOfertaTitleRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                          labelText: l10n.criarOfertaPhone,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? l10n.criarOfertaPhoneRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regionController,
                      decoration: InputDecoration(
                          labelText: l10n.mercadoFilterLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? l10n.criarOfertaTitleRequired : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.mercadoOfferConditions,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceDrcController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText: l10n.criarOfertaPriceDrc,
                                border: const OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? l10n.criarOfertaPriceDrcInvalid : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceWetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                                labelText: l10n.criarOfertaPriceWet,
                                border: const OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionsController,
                      decoration: InputDecoration(
                          labelText: l10n.criarOfertaConditions,
                          hintText: l10n.criarOfertaConditionsHint,
                          border: const OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? l10n.criarOfertaTitleRequired : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: l10n.criarOfertaPublishButton,
                loading: _isLoading,
                onPressed: _publishOffer,
              ),
            )
          ],
        ),
      ),
    );
  }
}
