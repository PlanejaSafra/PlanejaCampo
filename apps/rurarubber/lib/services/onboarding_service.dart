import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:agro_core/agro_core.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Service for managing the onboarding flow.
///
/// Coordinates between FarmService (agro_core), UserProfileService,
/// and a Hive settings box to track onboarding completion.
class OnboardingService {
  static const String _boxName = 'settings';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _tapperCountKey = 'tapper_count';
  static const String _bossNameKey = 'boss_name';

  Box? _box;

  /// Singleton instance.
  static final OnboardingService _instance = OnboardingService._internal();
  static OnboardingService get instance => _instance;
  OnboardingService._internal();

  /// Factory constructor for Provider compatibility.
  factory OnboardingService() => _instance;

  /// Initialize the service and open Hive box.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox(_boxName);
  }

  /// Whether the onboarding has been completed.
  bool get isOnboardingComplete {
    if (_box == null || !_box!.isOpen) return false;
    return _box!.get(_onboardingCompleteKey, defaultValue: false) as bool;
  }

  /// Get stored tapper count selection (for Produtor profile).
  /// Returns null if not set.
  String? get tapperCount {
    if (_box == null || !_box!.isOpen) return null;
    return _box!.get(_tapperCountKey) as String?;
  }

  /// Get stored boss name (for Sangrador profile).
  /// Returns null if not set.
  String? get bossName {
    if (_box == null || !_box!.isOpen) return null;
    return _box!.get(_bossNameKey) as String?;
  }

  /// Complete the onboarding process.
  ///
  /// Creates/updates the default farm with the user-provided name,
  /// sets the user profile, and marks onboarding as complete.
  ///
  /// Parameters:
  /// - [seringalName]: The name the user gave their plantation.
  /// - [profileType]: The selected profile type (produtor/sangrador/comprador).
  /// - [tapperCountSelection]: For Produtor - how many tappers (e.g., "just_me", "1-2", "3-5", "6+").
  /// - [bossNameValue]: For Sangrador - the name of their boss/producer.
  Future<void> completeOnboarding({
    required String seringalName,
    required UserProfileType profileType,
    String? tapperCountSelection,
    String? bossNameValue,
  }) async {
    await _ensureInitialized();

    final name = seringalName.trim().isEmpty ? 'Meu Seringal' : seringalName.trim();

    // 1. Create or update the default farm with the user-provided name
    try {
      final existingFarm = FarmService.instance.getDefaultFarm();
      if (existingFarm != null) {
        // Update existing default farm name
        existingFarm.updateName(name);
        await FarmService.instance.updateFarm(existingFarm);
        debugPrint('[Onboarding] Updated existing farm: ${existingFarm.id} -> $name');
      } else {
        // Create new default farm
        final farm = await FarmService.instance.createFarm(
          name: name,
          isDefault: true,
        );
        debugPrint('[Onboarding] Created new farm: ${farm.id} -> $name');
      }
    } catch (e) {
      debugPrint('[Onboarding] Farm operation failed: $e');
      // Continue onboarding even if farm creation fails
      // (user may not be authenticated yet)
    }

    // 2. Set the user profile
    await UserProfileService.instance.setProfile(
      profileType: profileType,
      displayName: bossNameValue,
    );
    debugPrint('[Onboarding] Profile set: $profileType');

    // 3. Store additional onboarding data
    if (tapperCountSelection != null) {
      await _box!.put(_tapperCountKey, tapperCountSelection);
    }
    if (bossNameValue != null) {
      await _box!.put(_bossNameKey, bossNameValue);
    }

    // 4. Mark onboarding as complete
    await _box!.put(_onboardingCompleteKey, true);
    debugPrint('[Onboarding] Onboarding completed successfully');
  }

  /// Reset onboarding state (for testing or profile reset).
  Future<void> resetOnboarding() async {
    await _ensureInitialized();
    await _box!.delete(_onboardingCompleteKey);
    await _box!.delete(_tapperCountKey);
    await _box!.delete(_bossNameKey);
    debugPrint('[Onboarding] Onboarding state reset');
  }

  /// Ensure the service is initialized.
  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
}
