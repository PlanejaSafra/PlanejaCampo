import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/market_offer.dart';
import '../widgets/rubber_drawer.dart';

class MercadoScreen extends StatefulWidget {
  const MercadoScreen({super.key});

  @override
  State<MercadoScreen> createState() => _MercadoScreenState();
}

class _MercadoScreenState extends State<MercadoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String _userRegion = "Rio Preto";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mercadoTitle),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_cart),
              text: l10n.mercadoTabBuy,
            ),
            Tab(
              icon: const Icon(Icons.sell),
              text: l10n.mercadoTabSell,
            ),
          ],
        ),
      ),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
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
                    '${l10n.mercadoFilterLabel}: $_userRegion',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(
                    onPressed: _showLocationFilterInfo,
                    child: Text(l10n.mercadoChangeLocation)),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Buy offers tab (compradores querendo comprar)
                _buildOffersList(OfferType.buy),
                // Sell offers tab (produtores querendo vender)
                _buildOffersList(OfferType.sell),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/criar-oferta');
        },
        label: Text(l10n.criarOfertaTitle),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOffersList(OfferType offerType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_offers')
          .where('validUntil', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .where('offerType', isEqualTo: offerType == OfferType.sell ? 'sell' : 'buy')
          .orderBy('validUntil', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Try without offerType filter for backwards compatibility
          return _buildOffersListFallback(offerType);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _buildEmptyState(offerType);
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
    );
  }

  // Fallback for existing data without offerType field
  Widget _buildOffersListFallback(OfferType offerType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market_offers')
          .where('validUntil', isGreaterThan: Timestamp.fromDate(DateTime.now()))
          .orderBy('validUntil', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          final l10n = BorrachaLocalizations.of(context)!;
          return Center(child: Text(l10n.mercadoFirestoreError));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        // Filter client-side by offerType (default to 'buy' for old records)
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final type = data['offerType'] ?? 'buy';
          return type == (offerType == OfferType.sell ? 'sell' : 'buy');
        }).toList();

        if (filteredDocs.isEmpty) {
          return _buildEmptyState(offerType);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final offer = MarketOffer.fromFirestore(filteredDocs[index]);
            return _buildOfferCard(offer);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(OfferType offerType) {
    final l10n = BorrachaLocalizations.of(context)!;
    final isSell = offerType == OfferType.sell;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSell ? Icons.inventory_2_outlined : Icons.shopping_bag_outlined,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSell ? l10n.mercadoNoSellOffers : l10n.mercadoNoOffers,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _showNotifyMeInfo,
            child: Text(l10n.mercadoNotifyButton),
          )
        ],
      ),
    );
  }

  Widget _buildOfferCard(MarketOffer offer) {
    final l10n = BorrachaLocalizations.of(context)!;
    final currency = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final isSellOffer = offer.offerType == OfferType.sell;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    offer.userName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Expiration warning
                    if (offer.isExpiringSoon)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              l10n.mercadoExpiringDays(offer.daysRemaining),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                    // Offer type badge
                    Chip(
                      label: Text(
                          isSellOffer ? l10n.mercadoSellerRole : l10n.mercadoBuyerRole),
                      backgroundColor:
                          isSellOffer ? Colors.green[100] : Colors.blue[100],
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Municipality for sell offers
            if (isSellOffer && offer.municipality != null && offer.municipality!.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.location_city, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    offer.municipality!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            // Production info for sell offers (trees and estimated weight)
            if (isSellOffer && (offer.treesInTapping != null || offer.estimatedWeight != null)) ...[
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (offer.treesInTapping != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.park, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.treesInTapping} ${l10n.mercadoTreesLabel}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  if (offer.estimatedWeight != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.estimatedWeight!.toStringAsFixed(0)} kg ${l10n.mercadoEstimatedLabel}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Available quantity for sell offers
            if (isSellOffer && offer.availableKg != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.scale, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      '${offer.availableKg!.toStringAsFixed(0)} kg ${l10n.mercadoAvailable}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Price section
            if (offer.isPriceNegotiable)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.handshake, color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(
                      l10n.mercadoPriceNegotiable,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  if (offer.priceDrc != null)
                    _buildPriceBox(l10n.mercadoOfferDrc,
                        currency.format(offer.priceDrc), true),
                  if (offer.priceDrc != null && offer.priceWet != null)
                    const SizedBox(width: 12),
                  if (offer.priceWet != null)
                    _buildPriceBox(l10n.mercadoOfferWet,
                        currency.format(offer.priceWet), offer.priceDrc == null),
                ],
              ),
            const SizedBox(height: 12),
            const Divider(),

            // Conditions
            Text(
              offer.conditions,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Valid until
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${l10n.mercadoOfferValidUntil}: ${DateFormat('dd/MM/yyyy').format(offer.validUntil)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                label: Text(l10n.mercadoOfferInterested),
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

  void _showLocationFilterInfo() {
    final l10n = BorrachaLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.marketLocationFilterTitle),
        content: Text(l10n.marketLocationFilterMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotifyMeInfo() {
    final l10n = BorrachaLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.notificationsComingSoon),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _launchWhatsApp(MarketOffer offer) async {
    final l10n = BorrachaLocalizations.of(context)!;
    final phone = offer.contactPhone.replaceAll(RegExp(r'[^\d]'), '');

    // Different message based on offer type
    String text;
    if (offer.offerType == OfferType.sell) {
      text = l10n.marketWhatsappMessageSell(offer.userName, _userRegion);
    } else {
      text = l10n.marketWhatsappMessage(offer.userName, _userRegion);
    }

    final url =
        Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(text)}");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
