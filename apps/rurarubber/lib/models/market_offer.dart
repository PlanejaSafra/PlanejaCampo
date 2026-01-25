import 'package:cloud_firestore/cloud_firestore.dart';

class MarketOffer {
  final String id;
  final String buyerId;
  final String buyerName; // Display name
  final List<String> regions; // List of GeoHashes
  final double priceDrc; // R$/kg for DRC 53%
  final double? priceWet; // Optional R$/kg for wet/banca
  final String conditions; // Payment terms, logistics, etc.
  final DateTime validUntil;
  final DateTime createdAt;
  final String contactPhone; // For WhatsApp link

  MarketOffer({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.regions,
    required this.priceDrc,
    this.priceWet,
    required this.conditions,
    required this.validUntil,
    required this.createdAt,
    required this.contactPhone,
  });

  factory MarketOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MarketOffer(
      id: doc.id,
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'Comprador',
      regions: List<String>.from(data['regions'] ?? []),
      priceDrc: (data['priceDrc'] ?? 0).toDouble(),
      priceWet: data['priceWet']?.toDouble(),
      conditions: data['conditions'] ?? '',
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      contactPhone: data['contactPhone'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'buyerName': buyerName,
      'regions': regions,
      'priceDrc': priceDrc,
      'priceWet': priceWet,
      'conditions': conditions,
      'validUntil': Timestamp.fromDate(validUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'contactPhone': contactPhone,
    };
  }
}
