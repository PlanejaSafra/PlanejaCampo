import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/user_profile.dart';

/// Service for managing user profile (Produtor/Comprador).
class UserProfileService extends ChangeNotifier {
  static const String _boxName = 'user_profile';
  static const String _profileKey = 'current_profile';

  Box<UserProfile>? _box;
  UserProfile? _currentProfile;

  /// Singleton instance.
  static final UserProfileService _instance = UserProfileService._internal();
  static UserProfileService get instance => _instance;
  UserProfileService._internal();

  /// Factory constructor for Provider compatibility.
  factory UserProfileService() => _instance;

  /// Initialize the service and open Hive box.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;

    _box = await Hive.openBox<UserProfile>(_boxName);
    _currentProfile = _box!.get(_profileKey);
  }

  /// Whether the user has selected a profile.
  bool get hasProfile => _currentProfile != null;

  /// Get the current profile (null if not set).
  UserProfile? get currentProfile => _currentProfile;

  /// Whether the current user is a producer.
  bool get isProdutor => _currentProfile?.isProdutor ?? false;

  /// Whether the current user is a buyer.
  bool get isComprador => _currentProfile?.isComprador ?? false;

  /// Set the user profile type.
  Future<void> setProfile({
    required UserProfileType profileType,
    String? displayName,
  }) async {
    await _ensureInitialized();

    final profile = UserProfile(
      profileType: profileType,
      displayName: displayName,
      profileComplete: true,
      createdAt: DateTime.now(),
    );

    await _box!.put(_profileKey, profile);
    _currentProfile = profile;
    notifyListeners();
  }

  /// Update the current profile.
  Future<void> updateProfile({
    UserProfileType? profileType,
    String? displayName,
    bool? profileComplete,
  }) async {
    await _ensureInitialized();

    if (_currentProfile == null) {
      throw StateError('No profile to update. Call setProfile first.');
    }

    final updated = _currentProfile!.copyWith(
      profileType: profileType,
      displayName: displayName,
      profileComplete: profileComplete,
      updatedAt: DateTime.now(),
    );

    await _box!.put(_profileKey, updated);
    _currentProfile = updated;
    notifyListeners();
  }

  /// Clear the profile (for logout or reset).
  Future<void> clearProfile() async {
    await _ensureInitialized();

    await _box!.delete(_profileKey);
    _currentProfile = null;
    notifyListeners();
  }

  /// Ensure the service is initialized.
  Future<void> _ensureInitialized() async {
    if (_box == null || !_box!.isOpen) {
      await init();
    }
  }
}
