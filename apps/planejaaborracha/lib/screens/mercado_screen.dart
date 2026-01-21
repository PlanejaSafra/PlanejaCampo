import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/market_offer.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen> {
  // Simulate GeoHash filtering by region string matching for now
  // In a real app, this would come from PropertyService or LocationHelper
  final String _userRegion = "Rio Preto";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercado de Borracha'),
      ),
      drawer: AgroDrawer(
        appName: 'PlanejaBorracha',
        versionText: '1.0.0',
        onNavigate: (route) {
          if (route == 'home')
            Navigator.pushReplacementNamed(context, '/pesagem');
          if (route == 'properties')
            Navigator.pushReplacementNamed(context, '/parceiros');
          if (route == 'mercado')
            Navigator.pushReplacementNamed(context, '/mercado');
        },
      ),
      body: Column(
        children: [
          // Filter Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.green[50],
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ofertas próximas a $_userRegion',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                    onPressed: () {
                      // Change location filter
                    },
                    child: const Text('Alterar')),
              ],
            ),
          ),

          // List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('market_offers')
                  .where('validUntil', isGreaterThan: DateTime.now())
                  .orderBy('validUntil', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // Client-side filtering for complex Geo Queries if not using simple equality
                // Here we just show all active offers for the demo as the collection starts empty
                if (docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final offer = MarketOffer.fromFirestore(docs[index]);
                    return _buildOfferCard(offer);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to Create Offer (if buyer)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Funcionalidade para Compradores em breve')));
        },
        label: const Text('Anunciar Compra'),
        icon: const Icon(Icons.campaign),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Nenhuma oferta na sua região agora.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Notify me when offers appear
            },
            child: const Text('Avise-me quando chegar'),
          )
        ],
      ),
    );
  }

  Widget _buildOfferCard(MarketOffer offer) {
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    offer.buyerName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Chip(
                  label: const Text('Indústria'),
                  backgroundColor: Colors.blue[100],
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriceBox(
                    'DRC (53%)', currency.format(offer.priceDrc), true),
                const SizedBox(width: 12),
                if (offer.priceWet != null)
                  _buildPriceBox(
                      'Úmido/Banca', currency.format(offer.priceWet), false),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            Text(
              offer.conditions,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                label: const Text('Tenho Interesse'),
                icon: const Icon(Icons.chat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _launchWhatsApp(offer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceBox(String label, String price, bool highlight) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: highlight ? Colors.green[50] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: highlight ? Colors.green.shade200 : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(
              price,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: highlight ? Colors.green[800] : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(MarketOffer offer) async {
    final phone = offer.contactPhone.replaceAll(RegExp(r'[^\d]'), '');
    final text =
        'Olá, vi sua oferta no PlanejaBorracha (${offer.buyerName}). Tenho produção em $_userRegion.';
    final url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Fallback or error
    }
  }
}
