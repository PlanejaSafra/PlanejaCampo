import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of market offer - buy (comprador) or sell (produtor)
enum OfferType { buy, sell }

class MarketOffer {
  final String id;
  final String userId; // User who created the offer
  final String userName; // Display name
  final OfferType offerType; // buy or sell
  final List<String> regions; // List of GeoHashes or region names
  final double? priceDrc; // R$/kg for DRC 53% - nullable for "preço a combinar"
  final double? priceWet; // Optional R$/kg for wet/banca
  final double? availableKg; // For sell offers: quantity available
  final String conditions; // Payment terms, logistics, etc.
  final DateTime validUntil;
  final DateTime createdAt;
  final String contactPhone; // For WhatsApp link

  // Additional fields for sell offers
  final String? municipality; // Município where the rubber is located
  final int? treesInTapping; // Number of trees being tapped (em sangria)
  final double? estimatedWeight; // Estimated total weight available

  MarketOffer({
    required this.id,
    required this.userId,
    required this.userName,
    required this.offerType,
    required this.regions,
    this.priceDrc,
    this.priceWet,
    this.availableKg,
    required this.conditions,
    required this.validUntil,
    required this.createdAt,
    required this.contactPhone,
    this.municipality,
    this.treesInTapping,
    this.estimatedWeight,
  });

  /// Check if offer is expiring soon (within 2 days)
  bool get isExpiringSoon {
    final daysUntilExpiry = validUntil.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 2 && daysUntilExpiry >= 0;
  }

  /// Check if offer has expired
  bool get isExpired => validUntil.isBefore(DateTime.now());

  /// Days remaining until expiration
  int get daysRemaining {
    final days = validUntil.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  /// Returns true if price is "a combinar" (both prices null)
  bool get isPriceNegotiable => priceDrc == null && priceWet == null;

  // Legacy getter for backwards compatibility
  String get buyerId => userId;
  String get buyerName => userName;

  factory MarketOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse offerType - default to 'buy' for backwards compatibility
    OfferType type = OfferType.buy;
    if (data['offerType'] != null) {
      type = data['offerType'] == 'sell' ? OfferType.sell : OfferType.buy;
    }

    return MarketOffer(
      id: doc.id,
      userId: data['userId'] ?? data['buyerId'] ?? '',
      userName: data['userName'] ?? data['buyerName'] ?? 'Usuário',
      offerType: type,
      regions: List<String>.from(data['regions'] ?? []),
      priceDrc: data['priceDrc']?.toDouble(),
      priceWet: data['priceWet']?.toDouble(),
      availableKg: data['availableKg']?.toDouble(),
      conditions: data['conditions'] ?? '',
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      contactPhone: data['contactPhone'] ?? '',
      municipality: data['municipality'],
      treesInTapping: data['treesInTapping']?.toInt(),
      estimatedWeight: data['estimatedWeight']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'offerType': offerType == OfferType.sell ? 'sell' : 'buy',
      'regions': regions,
      'priceDrc': priceDrc,
      'priceWet': priceWet,
      'availableKg': availableKg,
      'conditions': conditions,
      'validUntil': Timestamp.fromDate(validUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'contactPhone': contactPhone,
      'municipality': municipality,
      'treesInTapping': treesInTapping,
      'estimatedWeight': estimatedWeight,
      // Legacy fields for backwards compatibility
      'buyerId': userId,
      'buyerName': userName,
    };
  }
}
