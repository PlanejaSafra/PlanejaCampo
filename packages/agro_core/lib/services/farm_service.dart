import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm.dart';
import '../models/farm_type.dart';

/// Service for managing farms in the RuraCamp ecosystem.
///
/// Farm is the central entity for multi-user preparation:
/// - All data belongs to a Farm (via farmId)
/// - The owner (ownerId) is the primary user with full control
/// - Future: Multiple members with different roles
///
/// Key differences from PropertyService:
/// - Farm uses UUID-based IDs (not timestamp)
/// - Farm has ownerId (not userId) - represents ownership
/// - Farm is for multi-user preparation, Property is for location/area info
///
/// Usage:
/// ```dart
/// // Initialize in main.dart
/// await FarmService.instance.init();
///
/// // Get or create default farm for current user
/// final farm = await FarmService.instance.ensureDefaultFarm();
///
/// // Use farm.id as farmId for all data
/// final pesagem = Pesagem(farmId: farm.id, ...);
/// ```
class FarmService {
  static const String _boxName = 'farms';

  // Singleton pattern
  static final FarmService _instance = FarmService._internal();
  static FarmService get instance => _instance;
  factory FarmService() => _instance;
  FarmService._internal();

  late Box<Farm> _box;
  bool _initialized = false;

  /// Initialize Hive box
  /// Must be called from main.dart during app initialization
  /// Note: FarmAdapter must be registered BEFORE calling this method
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<Farm>(_boxName);
    _initialized = true;
  }

  /// Check if service is initialized
  bool get isInitialized => _initialized;

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all farms owned by the current user, sorted by creation date (newest first)
  List<Farm> getAllFarms() {
    if (_currentUserId == null) return [];
    return _box.values.where((f) => f.ownerId == _currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all farms for a specific user (for backup/migration)
  List<Farm> getFarmsForUser(String userId) {
    return _box.values.where((f) => f.ownerId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get farms by type for the current user
  List<Farm> getFarmsByType(FarmType type) {
    if (_currentUserId == null) return [];
    return _box.values
        .where((f) => f.ownerId == _currentUserId && f.type == type)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get the default farm for the current user
  /// Returns null if no default farm exists
  Farm? getDefaultFarm() {
    if (_currentUserId == null) return null;
    try {
      return _box.values.firstWhere(
        (f) => f.ownerId == _currentUserId && f.isDefault,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get farm by ID
  /// Returns null if farm doesn't exist or user doesn't have access
  Farm? getFarmById(String id) {
    final farm = _box.get(id);
    if (farm == null || farm.ownerId != _currentUserId) {
      return null;
    }
    return farm;
  }

  /// Get farm by ID (for internal use - no ownership check)
  /// Used when we need to verify farmId exists regardless of current user
  Farm? getFarmByIdUnchecked(String id) {
    return _box.get(id);
  }

  /// Maximum number of farms a free-tier user can own.
  static const int freeTierMaxFarms = 1;

  /// Check if the current user can create a new farm.
  ///
  /// FREE Tier:
  /// - agro: limited to [freeTierMaxFarms] (default: 1).
  /// - personal: limited to 1 (fixed).
  ///
  /// Paid tiers ('basic', 'premium'): unlimited agro farms.
  ///
  /// Returns true if the user can create another farm of the specified type.
  bool canCreateFarm({FarmType type = FarmType.agro}) {
    if (_currentUserId == null) return false;

    if (type == FarmType.personal) {
      final personalCount = getFarmsByType(FarmType.personal).length;
      return personalCount < 1;
    }

    final currentCount = getFarmsByType(FarmType.agro).length;
    final tier = getSubscriptionTier();
    if (tier == 'free') return currentCount < freeTierMaxFarms;
    return true; // paid tiers = unlimited
  }

  /// Get the subscription tier for the current user.
  ///
  /// Checks the default farm's subscriptionTier field.
  /// Returns 'free' if no tier is set (default for all users).
  String getSubscriptionTier() {
    final farm = getDefaultFarm();
    return farm?.subscriptionTier ?? 'free';
  }

  /// Create a new farm
  /// If isDefault is true, unsets other default farms first
  ///
  /// Throws if the user has reached the free-tier farm limit.
  /// Use [canCreateFarm] to check before calling.
  Future<Farm> createFarm({
    required String name,
    bool isDefault = false,
    String? description,
    FarmType type = FarmType.agro,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot create farm.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Farm name cannot be empty.');
    }

    // Check farm limit
    if (!canCreateFarm(type: type)) {
      if (type == FarmType.personal) {
        throw FarmLimitException('Personal farm limit reached (Max 1).');
      }
      throw FarmLimitException(
        'Farm limit reached. Free tier allows $freeTierMaxFarms farm(s).',
      );
    }

    final farm = Farm.create(
      name: name.trim(),
      ownerId: _currentUserId!,
      isDefault: isDefault,
      description: description,
      type: type,
    );

    // If this is set as default, unset other defaults
    if (isDefault) {
      await _unsetOtherDefaults();
    }

    await _box.put(farm.id, farm);
    return farm;
  }

  /// Import a farm from backup (preserves original ID and ownerId)
  /// Used during cloud restore
  Future<void> importFarm(Farm farm) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot import farm.');
    }

    // Update ownerId to current user (in case restoring to different account)
    final imported = Farm(
      id: farm.id,
      name: farm.name,
      ownerId: _currentUserId!,
      createdAt: farm.createdAt,
      updatedAt: farm.updatedAt,
      isDefault: farm.isDefault,
      description: farm.description,
      subscriptionTier: farm.subscriptionTier,
      isShared: farm.isShared,
      type: farm.type,
    );

    // If this is set as default, unset other defaults
    if (imported.isDefault) {
      await _unsetOtherDefaults();
    }

    await _box.put(imported.id, imported);
  }

  /// Import multiple farms from backup
  Future<void> importFarms(List<dynamic> farmsJson) async {
    for (final json in farmsJson) {
      final farm = Farm.fromJson(json as Map<String, dynamic>);
      await importFarm(farm);
    }
  }

  /// Update an existing farm
  Future<void> updateFarm(Farm farm) async {
    if (farm.ownerId != _currentUserId) {
      throw Exception('Unauthorized: Cannot update farm from another user.');
    }

    farm.updatedAt = DateTime.now();
    await _box.put(farm.id, farm);
  }

  /// Delete a farm
  /// WARNING: All data with this farmId will become orphaned!
  /// Only delete farms that have no associated data.
  Future<void> deleteFarm(String id) async {
    final farm = getFarmById(id);
    if (farm == null) {
      throw Exception('Farm not found or unauthorized.');
    }

    await _box.delete(id);
  }

  /// Clear all farms for the current user (used for restore)
  Future<void> clearAllForUser() async {
    if (_currentUserId == null) return;

    final userFarms = _box.values
        .where((f) => f.ownerId == _currentUserId)
        .map((f) => f.id)
        .toList();

    for (final id in userFarms) {
      await _box.delete(id);
    }
  }

  /// Set a farm as the default (unsets all other defaults)
  Future<void> setAsDefault(String farmId) async {
    final farm = getFarmById(farmId);
    if (farm == null) {
      throw Exception('Farm not found or unauthorized.');
    }

    await _unsetOtherDefaults();
    farm.isDefault = true;
    farm.updatedAt = DateTime.now();
    await _box.put(farmId, farm);
  }

  /// Unset all default farms for the current user
  Future<void> _unsetOtherDefaults() async {
    if (_currentUserId == null) return;

    final defaults = _box.values
        .where((f) => f.ownerId == _currentUserId && f.isDefault)
        .toList();

    for (final farm in defaults) {
      farm.isDefault = false;
      farm.updatedAt = DateTime.now();
      await _box.put(farm.id, farm);
    }
  }

  /// Ensure the user has at least one default farm
  /// Auto-creates a default farm if none exists
  /// Returns the default farm (existing or newly created)
  ///
  /// This should be called during app initialization after user login.
  /// The returned farm.id should be used as farmId for all data.
  Future<Farm> ensureDefaultFarm({
    AgroLocalizations? l10n,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot ensure default farm.');
    }

    // Check if default already exists
    var defaultFarm = getDefaultFarm();
    if (defaultFarm != null) return defaultFarm;

    // No default exists - check if user has ANY farms
    final allFarms = getAllFarms();
    if (allFarms.isNotEmpty) {
      // User has farms but no default - set first one as default
      await setAsDefault(allFarms.first.id);
      return allFarms.first;
    }

    // No farms at all - create default
    // Use localized name if available, otherwise fallback
    final defaultName = l10n?.farmDefaultName ?? 'Minha Fazenda';
    return await createFarm(
      name: defaultName,
      isDefault: true,
    );
  }

  /// Count total farms for current user
  int getFarmCount() {
    if (_currentUserId == null) return 0;
    return _box.values.where((f) => f.ownerId == _currentUserId).length;
  }

  /// Create or get the personal farm for the current user.
  ///
  /// Pass [l10n] to use localized default name. If both [name] and [l10n]
  /// are null, falls back to English default.
  Future<Farm> createPersonalFarm({
    String? name,
    AgroLocalizations? l10n,
  }) async {
    final existing = getFarmsByType(FarmType.personal);
    if (existing.isNotEmpty) return existing.first;

    final farmName = name ?? l10n?.farmDefaultNamePersonal ?? 'My Finances';
    return await createFarm(
      name: farmName,
      type: FarmType.personal,
      isDefault: false, // Don't switch context automatically
    );
  }

  /// Check if a farm name already exists (case-insensitive)
  bool farmNameExists(String name, {String? excludeId}) {
    if (_currentUserId == null) return false;
    final normalizedName = name.trim().toLowerCase();
    return _box.values.any((f) =>
        f.ownerId == _currentUserId &&
        f.id != excludeId &&
        f.name.trim().toLowerCase() == normalizedName);
  }

  /// Transfer all farms from one user to another (Data Migration)
  /// Used when merging an anonymous account into a new Google account
  Future<void> transferData(String oldUserId, String newUserId) async {
    if (oldUserId == newUserId) return;

    // Get all farms belonging to the old user
    final oldFarms = _box.values.where((f) => f.ownerId == oldUserId).toList();
    if (oldFarms.isEmpty) return;

    // Check if new user already has a default farm
    final newFarms = _box.values.where((f) => f.ownerId == newUserId).toList();
    final hasNewDefault = newFarms.any((f) => f.isDefault);

    for (final farm in oldFarms) {
      final updatedFarm = Farm(
        id: farm.id,
        name: farm.name,
        ownerId: newUserId, // Transfer ownership
        createdAt: farm.createdAt,
        updatedAt: DateTime.now(),
        isDefault: hasNewDefault ? false : farm.isDefault,
        description: farm.description,
        subscriptionTier: farm.subscriptionTier,
        isShared: farm.isShared,
        type: farm.type,
      );

      await _box.put(farm.id, updatedFarm);
    }
  }

  /// Get the default farmId for use in data creation
  /// Returns null if no default farm exists
  ///
  /// Convenience method for quick access:
  /// ```dart
  /// final farmId = FarmService.instance.defaultFarmId;
  /// if (farmId != null) {
  ///   final pesagem = Pesagem(farmId: farmId, ...);
  /// }
  /// ```
  String? get defaultFarmId => getDefaultFarm()?.id;

  /// Check if the active (default) farm is in shared (multi-user) mode.
  ///
  /// Returns `true` if the default farm has `isShared == true`.
  /// Returns `false` if no default farm exists or isShared is false.
  ///
  /// Used by GenericSyncService to determine if Tier 3 data should
  /// be synchronized to Firestore.
  bool isActiveFarmShared() {
    final farm = getDefaultFarm();
    return farm?.isShared ?? false;
  }

  /// Set the shared (multi-user) mode on the active (default) farm.
  ///
  /// This is called when a multi-user license is activated or deactivated.
  /// When `shared = true`, GenericSyncService (Tier 3) will begin syncing
  /// this farm's data to Firestore.
  Future<void> setFarmShared(bool shared) async {
    final farm = getDefaultFarm();
    if (farm == null) {
      throw Exception('No default farm found. Cannot set shared mode.');
    }

    farm.setShared(shared);
    await _box.put(farm.id, farm);
  }
}

/// Exception thrown when a user tries to create more farms
/// than their subscription tier allows.
class FarmLimitException implements Exception {
  final String message;
  const FarmLimitException(this.message);

  @override
  String toString() => 'FarmLimitException: $message';
}
