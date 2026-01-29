import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm.dart';
import '../models/farm_permissions.dart';
import '../models/farm_role.dart';
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
  static const String _prefsBoxName = 'agro_farm_prefs';
  static const String _activeFarmKey = 'activeFarmId';

  // Singleton pattern
  static final FarmService _instance = FarmService._internal();
  static FarmService get instance => _instance;
  factory FarmService() => _instance;
  FarmService._internal();

  late Box<Farm> _box;
  late Box<String> _prefsBox;
  bool _initialized = false;

  /// The currently active farm ID (persisted across sessions).
  /// If null, falls back to the default farm.
  String? _activeFarmId;

  /// Initialize Hive box
  /// Must be called from main.dart during app initialization
  /// Note: FarmAdapter and FarmRoleAdapter must be registered BEFORE calling this
  Future<void> init() async {
    if (_initialized) return;
    _box = await Hive.openBox<Farm>(_boxName);
    _prefsBox = await Hive.openBox<String>(_prefsBoxName);
    _activeFarmId = _prefsBox.get(_activeFarmKey);
    _initialized = true;
    debugPrint('[FarmService] Initialized. Active farm: $_activeFarmId');
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
  /// Returns null if farm doesn't exist or user doesn't have access.
  /// Includes both owned and joined farms.
  Farm? getFarmById(String id) {
    final farm = _box.get(id);
    if (farm == null) return null;
    // Allow access to owned farms and joined farms
    if (farm.ownerId == _currentUserId || farm.isJoined) {
      return farm;
    }
    return null;
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
      myRole: farm.myRole,
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
        myRole: farm.myRole,
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

  /// Check if the active farm is in shared (multi-user) mode.
  ///
  /// Returns `true` if the active farm has `isShared == true`.
  /// Returns `false` if no active farm exists or isShared is false.
  ///
  /// Used by GenericSyncService to determine if Tier 3 data should
  /// be synchronized to Firestore.
  bool isActiveFarmShared() {
    final farm = getActiveFarm();
    return farm?.isShared ?? false;
  }

  /// Set the shared (multi-user) mode on the active farm.
  ///
  /// This is called when a multi-user license is activated or deactivated.
  /// When `shared = true`, GenericSyncService (Tier 3) will begin syncing
  /// this farm's data to Firestore.
  Future<void> setFarmShared(bool shared) async {
    final farm = getActiveFarm();
    if (farm == null) {
      throw Exception('No active farm found. Cannot set shared mode.');
    }

    farm.setShared(shared);
    await _box.put(farm.id, farm);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CORE-90: Multi-Farm Support
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get all farms accessible to the current user (owned + joined).
  ///
  /// Returns owned farms (`ownerId == currentUser`) plus joined farms
  /// (`myRole != null && myRole != owner`), sorted by creation date.
  List<Farm> getAccessibleFarms() {
    if (_currentUserId == null) return [];
    return _box.values.where((f) =>
        f.ownerId == _currentUserId ||
        (f.myRole != null && f.myRole != FarmRole.owner),
    ).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get the currently active farm.
  ///
  /// Resolution order:
  /// 1. Farm matching `_activeFarmId` (if set and still accessible)
  /// 2. Default farm (`isDefault == true`)
  /// 3. First accessible farm
  /// 4. null (no farms)
  Farm? getActiveFarm() {
    if (_currentUserId == null) return null;

    // 1. Try stored active farm ID
    if (_activeFarmId != null) {
      final farm = _box.get(_activeFarmId);
      if (farm != null &&
          (farm.ownerId == _currentUserId || farm.isJoined)) {
        return farm;
      }
      // Stale ID — clear it
      _activeFarmId = null;
      _prefsBox.delete(_activeFarmKey);
    }

    // 2. Fall back to default farm
    final defaultFarm = getDefaultFarm();
    if (defaultFarm != null) return defaultFarm;

    // 3. Fall back to first accessible
    final accessible = getAccessibleFarms();
    return accessible.isNotEmpty ? accessible.first : null;
  }

  /// Get the active farm's ID.
  ///
  /// Convenience for quick access. Falls back to default farm if no active.
  String? get activeFarmId => getActiveFarm()?.id;

  /// Set the active farm by ID.
  ///
  /// Persists across sessions. The active farm determines the context
  /// for all data operations (reading/writing records, reports, etc.)
  Future<void> setActiveFarm(String farmId) async {
    final farm = _box.get(farmId);
    if (farm == null) {
      throw Exception('Farm not found: $farmId');
    }

    _activeFarmId = farmId;
    await _prefsBox.put(_activeFarmKey, farmId);
    debugPrint('[FarmService] Active farm set to: $farmId (${farm.name})');
  }

  /// Add a joined farm to local storage.
  ///
  /// Called when the current user accepts an invitation to another user's farm.
  /// Creates a local Farm object with the original owner's data but `myRole`
  /// set to the invited role.
  Future<Farm> addJoinedFarm({
    required String farmId,
    required String farmName,
    required String ownerId,
    required FarmRole role,
    FarmType type = FarmType.agro,
    String? description,
    bool isShared = true,
  }) async {
    // Check if farm already exists locally
    final existing = _box.get(farmId);
    if (existing != null) {
      debugPrint('[FarmService] Farm $farmId already exists locally');
      return existing;
    }

    final farm = Farm(
      id: farmId,
      name: farmName,
      ownerId: ownerId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDefault: false, // Joined farms are never default
      description: description,
      isShared: isShared,
      type: type,
      myRole: role,
    );

    await _box.put(farm.id, farm);
    debugPrint('[FarmService] Added joined farm: $farmId (role: ${role.name})');
    return farm;
  }

  /// Remove a joined farm from local storage.
  ///
  /// Called when the current user leaves a farm they had joined.
  /// If the active farm was the removed farm, resets to default.
  Future<void> removeJoinedFarm(String farmId) async {
    final farm = _box.get(farmId);
    if (farm == null) return;

    // Only allow removing joined farms (not owned)
    if (farm.isOwned && farm.ownerId == _currentUserId) {
      throw Exception('Cannot remove owned farm via removeJoinedFarm. '
          'Use deleteFarm instead.');
    }

    await _box.delete(farmId);
    debugPrint('[FarmService] Removed joined farm: $farmId');

    // Reset active farm if it was the removed one
    if (_activeFarmId == farmId) {
      _activeFarmId = null;
      await _prefsBox.delete(_activeFarmKey);
      debugPrint('[FarmService] Reset active farm (removed farm was active)');
    }
  }

  /// Get permissions for the active farm.
  ///
  /// Returns [FarmPermissions] based on the current user's role
  /// in the active farm. Defaults to owner permissions if no farm is active.
  FarmPermissions getActivePermissions() {
    final farm = getActiveFarm();
    if (farm == null) return const FarmPermissions(FarmRole.owner);
    return FarmPermissions(farm.effectiveRole);
  }

  /// Get permissions for a specific farm.
  FarmPermissions getPermissionsForFarm(String farmId) {
    final farm = _box.get(farmId);
    if (farm == null) return const FarmPermissions(FarmRole.worker);
    return FarmPermissions(farm.effectiveRole);
  }

  /// Whether the current user has multiple accessible farms.
  bool get hasMultipleFarms => getAccessibleFarms().length > 1;
}

/// Exception thrown when a user tries to create more farms
/// than their subscription tier allows.
class FarmLimitException implements Exception {
  final String message;
  const FarmLimitException(this.message);

  @override
  String toString() => 'FarmLimitException: $message';
}
