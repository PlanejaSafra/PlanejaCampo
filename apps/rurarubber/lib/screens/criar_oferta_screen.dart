import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agro_core/agro_core.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/market_offer.dart';
import '../widgets/rubber_drawer.dart';

class CriarOfertaScreen extends StatefulWidget {
  const CriarOfertaScreen({super.key});

  @override
  State<CriarOfertaScreen> createState() => _CriarOfertaScreenState();
}

class _CriarOfertaScreenState extends State<CriarOfertaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _priceDrcController = TextEditingController();
  final _priceWetController = TextEditingController();
  final _conditionsController = TextEditingController();
  final _regionController = TextEditingController(text: 'Rio Preto');
  final _phoneController = TextEditingController();
  final _availableKgController = TextEditingController();
  final _validityDaysController = TextEditingController(text: '7');

  // Additional fields for sell offers
  final _municipalityController = TextEditingController();
  final _treesInTappingController = TextEditingController();
  final _estimatedWeightController = TextEditingController();

  bool _isLoading = false;
  OfferType _selectedOfferType = OfferType.buy;

  @override
  void dispose() {
    _userNameController.dispose();
    _priceDrcController.dispose();
    _priceWetController.dispose();
    _conditionsController.dispose();
    _regionController.dispose();
    _phoneController.dispose();
    _availableKgController.dispose();
    _validityDaysController.dispose();
    _municipalityController.dispose();
    _treesInTappingController.dispose();
    _estimatedWeightController.dispose();
    super.dispose();
  }

  Future<void> _publishOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = BorrachaLocalizations.of(context)!;
    try {
      // Parse prices - can be null for sell offers
      final drc = _priceDrcController.text.isNotEmpty
          ? double.parse(_priceDrcController.text.replaceAll(',', '.'))
          : null;
      final wet = _priceWetController.text.isNotEmpty
          ? double.parse(_priceWetController.text.replaceAll(',', '.'))
          : null;

      // Parse available kg (for sell offers)
      final availableKg = _availableKgController.text.isNotEmpty
          ? double.parse(_availableKgController.text.replaceAll(',', '.'))
          : null;

      // Parse additional sell offer fields
      final treesInTapping = _treesInTappingController.text.isNotEmpty
          ? int.tryParse(_treesInTappingController.text)
          : null;
      final estimatedWeight = _estimatedWeightController.text.isNotEmpty
          ? double.tryParse(_estimatedWeightController.text.replaceAll(',', '.'))
          : null;

      // Parse validity days
      final validityDays = int.tryParse(_validityDaysController.text) ?? 7;
      final validUntil = DateTime.now().add(Duration(days: validityDays));

      final userId = AuthService.currentUser?.uid ?? 'anonymous';
      final offerData = {
        'userId': userId,
        'userName': _userNameController.text,
        'offerType': _selectedOfferType == OfferType.sell ? 'sell' : 'buy',
        'regions': [_regionController.text],
        'priceDrc': drc,
        'priceWet': wet,
        'availableKg': availableKg,
        'conditions': _conditionsController.text,
        'contactPhone': _phoneController.text,
        'createdAt': FieldValue.serverTimestamp(),
        'validUntil': Timestamp.fromDate(validUntil),
        // Additional sell offer fields
        'municipality': _municipalityController.text.isNotEmpty
            ? _municipalityController.text
            : null,
        'treesInTapping': treesInTapping,
        'estimatedWeight': estimatedWeight,
        // Legacy fields for backwards compatibility
        'buyerId': userId,
        'buyerName': _userNameController.text,
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
    final isSellOffer = _selectedOfferType == OfferType.sell;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.criarOfertaTitle)),
      drawer: buildRubberDrawer(context: context, l10n: l10n),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Offer Type Selection
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.criarOfertaTypeLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildOfferTypeCard(
                            type: OfferType.buy,
                            icon: Icons.shopping_cart,
                            label: l10n.criarOfertaTypeBuy,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOfferTypeCard(
                            type: OfferType.sell,
                            icon: Icons.sell,
                            label: l10n.criarOfertaTypeSell,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // User Info Card
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isSellOffer
                            ? l10n.mercadoSellerRole
                            : l10n.mercadoBuyerRole,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _userNameController,
                      decoration: InputDecoration(
                          labelText: l10n.criarOfertaNameLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? l10n.criarOfertaNameRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                          labelText: l10n.criarOfertaPhone,
                          border: const OutlineInputBorder()),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          v!.isEmpty ? l10n.criarOfertaPhoneRequired : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _regionController,
                      decoration: InputDecoration(
                          labelText: l10n.mercadoFilterLabel,
                          border: const OutlineInputBorder()),
                      validator: (v) =>
                          v!.isEmpty ? l10n.criarOfertaTitleRequired : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Production Details (for sell offers only)
            if (isSellOffer)
              CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.criarOfertaProductionDetails,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Municipality
                      TextFormField(
                        controller: _municipalityController,
                        decoration: InputDecoration(
                          labelText: l10n.criarOfertaMunicipality,
                          hintText: l10n.criarOfertaMunicipalityHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.location_city),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Trees and Estimated Weight row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _treesInTappingController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: l10n.criarOfertaTreesInTapping,
                                hintText: l10n.criarOfertaTreesInTappingHint,
                                border: const OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return null;
                                final val = int.tryParse(v);
                                if (val == null || val <= 0) {
                                  return l10n.criarOfertaTreesInTappingInvalid;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _estimatedWeightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: l10n.criarOfertaEstimatedWeight,
                                hintText: l10n.criarOfertaEstimatedWeightHint,
                                border: const OutlineInputBorder(),
                                suffixText: 'kg',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Available Quantity
                      TextFormField(
                        controller: _availableKgController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: l10n.criarOfertaAvailableKg,
                          hintText: l10n.criarOfertaAvailableKgHint,
                          border: const OutlineInputBorder(),
                          suffixText: 'kg',
                          prefixIcon: const Icon(Icons.scale),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return null; // Optional
                          final val = double.tryParse(v.replaceAll(',', '.'));
                          if (val == null || val <= 0) {
                            return l10n.criarOfertaAvailableKgInvalid;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            if (isSellOffer) const SizedBox(height: 16),

            // Price Card
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isSellOffer
                            ? l10n.criarOfertaPriceOptional
                            : l10n.mercadoOfferConditions,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    if (isSellOffer) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 16, color: Colors.amber[800]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.mercadoPriceNegotiable,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.amber[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                            validator: (v) {
                              // For buy offers, price is required
                              if (!isSellOffer && (v == null || v.isEmpty)) {
                                return l10n.criarOfertaPriceDrcInvalid;
                              }
                              // For sell offers, price is optional
                              if (v != null && v.isNotEmpty) {
                                final val =
                                    double.tryParse(v.replaceAll(',', '.'));
                                if (val == null || val <= 0) {
                                  return l10n.criarOfertaPriceDrcInvalid;
                                }
                              }
                              return null;
                            },
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
                            validator: (v) {
                              if (v != null && v.isNotEmpty) {
                                final val =
                                    double.tryParse(v.replaceAll(',', '.'));
                                if (val == null || val <= 0) {
                                  return l10n.criarOfertaPriceWetInvalid;
                                }
                              }
                              return null;
                            },
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
                      validator: (v) =>
                          v!.isEmpty ? l10n.criarOfertaTitleRequired : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Validity Card
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.criarOfertaValidityDays,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _validityDaysController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.criarOfertaValidityDays,
                        hintText: l10n.criarOfertaValidityDaysHint,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return l10n.criarOfertaValidityInvalid;
                        }
                        final days = int.tryParse(v);
                        if (days == null || days < 1 || days > 90) {
                          return l10n.criarOfertaValidityInvalid;
                        }
                        return null;
                      },
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

  Widget _buildOfferTypeCard({
    required OfferType type,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedOfferType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedOfferType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
