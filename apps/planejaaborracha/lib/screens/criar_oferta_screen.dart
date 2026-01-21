import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:uuid/uuid.dart';

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
          const SnackBar(content: Text('Oferta publicada com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao publicar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anunciar Compra')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AgroCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Dados do Comprador',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _buyerNameController,
                      decoration: const InputDecoration(
                          labelText: 'Nome da Empresa/Comprador',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                          labelText: 'WhatsApp para Contato',
                          border: OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                          labelText: 'Região de Atuação',
                          border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            AgroCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Detalhes da Oferta',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _priceDrcController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Preço DRC (R\$)',
                                border: OutlineInputBorder()),
                            validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _priceWetController,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: const InputDecoration(
                                labelText: 'Preço Banca (Op)',
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _conditionsController,
                      decoration: const InputDecoration(
                          labelText: 'Condições (Pagamento, Retirada...)',
                          border: OutlineInputBorder()),
                      maxLines: 3,
                      validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            AgroButton(
              text: 'Publicar Oferta',
              isLoading: _isLoading,
              onPressed: _publishOffer,
            )
          ],
        ),
      ),
    );
  }
}
