import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// CASH-30: Premium features enum.
enum PremiumFeature {
  contasBancarias,          // CASH-23
  receitas,                 // CASH-24
  transferencias,           // CASH-25
  contasPagarReceber,       // CASH-26
  orcamento,                // CASH-27
  relatoriosAvancados,      // CASH-28
  reconciliacao,            // CASH-29
  categoriasCustom,         // CASH-22
  multiFarmAgro,            // >1 farm agrícola
}

/// CASH-30: Premium subscription plans.
enum PremiumPlan {
  monthly,  // R$ 9,90/mês
  yearly,   // R$ 79,90/ano
}

/// CASH-30: Premium service.
/// Local implementation with feature flags.
/// Ready to integrate with RevenueCat when account is configured.
class PremiumService extends ChangeNotifier {
  static final PremiumService _instance = PremiumService._internal();
  static PremiumService get instance => _instance;
  PremiumService._internal();
  factory PremiumService() => _instance;

  static const String _boxName = 'premium';
  static const String _keyIsPremium = 'is_premium';
  static const String _keyPlan = 'plan';
  static const String _keyExpiry = 'expiry';

  bool _isPremium = false;
  PremiumPlan? _activePlan;
  DateTime? _expiryDate;

  bool get isPremium => _isPremium;
  PremiumPlan? get activePlan => _activePlan;
  DateTime? get expiryDate => _expiryDate;

  /// Initialize from local storage.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);
    _isPremium = box.get(_keyIsPremium, defaultValue: false);
    final planIndex = box.get(_keyPlan);
    if (planIndex != null) {
      _activePlan = PremiumPlan.values[planIndex as int];
    }
    final expiryStr = box.get(_keyExpiry);
    if (expiryStr != null) {
      _expiryDate = DateTime.tryParse(expiryStr as String);
      // Check if expired
      if (_expiryDate != null && _expiryDate!.isBefore(DateTime.now())) {
        _isPremium = false;
        await box.put(_keyIsPremium, false);
      }
    }
  }

  /// Check if a specific feature is unlocked.
  bool hasFeature(PremiumFeature feature) {
    // Free features (always available)
    // All premium features require subscription
    return _isPremium;
  }

  /// Check feature and show paywall if locked.
  /// Returns true if feature is available.
  bool checkFeature(PremiumFeature feature) {
    return hasFeature(feature);
  }

  /// Purchase a plan (local mock — replace with RevenueCat).
  Future<bool> purchase(PremiumPlan plan) async {
    // TODO: Integrate with RevenueCat
    // For now, this is a local-only implementation.
    // In production, this would call:
    //   final offering = await Purchases.getOfferings();
    //   final result = await Purchases.purchasePackage(package);
    debugPrint('[PremiumService] Purchase requested: $plan');
    return false; // No purchase in mock mode
  }

  /// Restore purchases.
  Future<bool> restore() async {
    // TODO: Integrate with RevenueCat
    // In production:
    //   final info = await Purchases.restorePurchases();
    //   return info.entitlements.active.containsKey('premium');
    debugPrint('[PremiumService] Restore requested');
    return false;
  }

  /// Activate premium (used after successful purchase or restore).
  Future<void> activatePremium(PremiumPlan plan, {DateTime? expiry}) async {
    _isPremium = true;
    _activePlan = plan;
    _expiryDate = expiry;

    final box = await Hive.openBox(_boxName);
    await box.put(_keyIsPremium, true);
    await box.put(_keyPlan, plan.index);
    if (expiry != null) {
      await box.put(_keyExpiry, expiry.toIso8601String());
    }
    notifyListeners();
  }

  /// Deactivate premium.
  Future<void> deactivatePremium() async {
    _isPremium = false;
    _activePlan = null;
    _expiryDate = null;

    final box = await Hive.openBox(_boxName);
    await box.put(_keyIsPremium, false);
    await box.delete(_keyPlan);
    await box.delete(_keyExpiry);
    notifyListeners();
  }
}
