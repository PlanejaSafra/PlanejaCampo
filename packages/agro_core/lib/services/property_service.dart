import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/property.dart';

/// Service for managing properties (farms/rural properties).
/// Properties are stored locally in Hive and shared across all PlanejaCampo apps
/// via userId (Firebase Auth).
class PropertyService {
  static const String _boxName = 'properties';

  // Singleton pattern
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();

  late Box<Property> _box;

  /// Initialize Hive box
  /// Must be called from main.dart during app initialization
  /// Note: PropertyAdapter must be registered BEFORE calling this method
  Future<void> init() async {
    _box = await Hive.openBox<Property>(_boxName);
  }

  /// Get current user ID from Firebase Auth
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Get all properties for the current user, sorted by creation date (newest first)
  List<Property> getAllProperties() {
    if (_currentUserId == null) return [];
    return _box.values.where((p) => p.userId == _currentUserId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get the default property for the current user
  /// Returns null if no default property exists
  Property? getDefaultProperty() {
    if (_currentUserId == null) return null;
    try {
      return _box.values.firstWhere(
        (p) => p.userId == _currentUserId && p.isDefault,
      );
    } catch (_) {
      // No default property found
      return null;
    }
  }

  /// Get property by ID
  /// Returns null if property doesn't exist or belongs to another user
  Property? getPropertyById(String id) {
    final property = _box.get(id);
    if (property == null || property.userId != _currentUserId) {
      return null;
    }
    return property;
  }

  /// Create a new property
  /// If isDefault is true, unsets other default properties first
  Future<Property> createProperty({
    required String name,
    double? totalArea,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated. Cannot create property.');
    }

    if (name.trim().isEmpty) {
      throw Exception('Property name cannot be empty.');
    }

    final property = Property.create(
      userId: _currentUserId!,
      name: name.trim(),
      totalArea: totalArea,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
    );

    // If this is set as default, unset other defaults
    if (isDefault) {
      await _unsetOtherDefaults();
    }

    await _box.put(property.id, property);
    return property;
  }

  /// Update an existing property
  /// The property object is already modified, just save it to Hive
  Future<void> updateProperty(Property property) async {
    if (property.userId != _currentUserId) {
      throw Exception(
          'Unauthorized: Cannot update property from another user.');
    }

    property.updatedAt = DateTime.now();
    await _box.put(property.id, property);
  }

  /// Delete a property
  /// If the property has associated records, they should be migrated first
  /// (handled by the calling code, typically a confirmation dialog)
  Future<void> deleteProperty(String id) async {
    final property = getPropertyById(id);
    if (property == null) {
      throw Exception('Property not found or unauthorized.');
    }

    await _box.delete(id);
  }

  /// Set a property as the default (unsets all other defaults)
  Future<void> setAsDefault(String propertyId) async {
    final property = getPropertyById(propertyId);
    if (property == null) {
      throw Exception('Property not found or unauthorized.');
    }

    await _unsetOtherDefaults();
    property.isDefault = true;
    property.updatedAt = DateTime.now();
    await _box.put(propertyId, property);
  }

  /// Unset all default properties for the current user
  /// Called internally when setting a new default
  Future<void> _unsetOtherDefaults() async {
    if (_currentUserId == null) return;

    final defaults = _box.values
        .where((p) => p.userId == _currentUserId && p.isDefault)
        .toList();

    for (final prop in defaults) {
      prop.isDefault = false;
      prop.updatedAt = DateTime.now();
      await _box.put(prop.id, prop);
    }
  }

  /// Ensure the user has at least one default property
  /// Auto-creates a default property if none exists
  /// Returns the default property (existing or newly created)
  ///
  /// This is called during app initialization to guarantee a default property
  /// always exists for new records (rainfall, rubber harvest, etc.)
  Future<Property> ensureDefaultProperty({
    AgroLocalizations? l10n,
  }) async {
    if (_currentUserId == null) {
      throw Exception(
          'User not authenticated. Cannot ensure default property.');
    }

    // Check if default already exists
    var defaultProp = getDefaultProperty();
    if (defaultProp != null) return defaultProp;

    // No default exists - check if user has ANY properties
    final allProps = getAllProperties();
    if (allProps.isNotEmpty) {
      // User has properties but no default - set first one as default
      await setAsDefault(allProps.first.id);
      return allProps.first;
    }

    // No properties at all - create default
    // Use localized name if available, otherwise fallback
    final defaultName = l10n?.propertyDefaultName ?? 'Minha Propriedade';
    return await createProperty(
      name: defaultName,
      isDefault: true,
    );
  }

  /// Count total properties for current user
  int getPropertyCount() {
    if (_currentUserId == null) return 0;
    return _box.values.where((p) => p.userId == _currentUserId).length;
  }

  /// Check if a property name already exists (case-insensitive)
  /// Useful for validation before creating/updating
  bool propertyNameExists(String name, {String? excludeId}) {
    if (_currentUserId == null) return false;
    final normalizedName = name.trim().toLowerCase();
    return _box.values.any((p) =>
        p.userId == _currentUserId &&
        p.id != excludeId &&
        p.name.trim().toLowerCase() == normalizedName);
  }

  /// Transfer all properties from one user to another (Data Migration)
  /// Used when merging an anonymous account into a new Google account
  Future<void> transferData(String oldUserId, String newUserId) async {
    if (oldUserId == newUserId) return;

    // Get all properties belonging to the old user
    final oldProps = _box.values.where((p) => p.userId == oldUserId).toList();
    if (oldProps.isEmpty) return;

    // Check if new user already has a default property
    final newProps = _box.values.where((p) => p.userId == newUserId).toList();
    final hasNewDefault = newProps.any((p) => p.isDefault);

    for (final prop in oldProps) {
      // Update User ID
      // We can't modify 'userId' directly because it's final in hive object?
      // Check Property model. userId is final.
      // We must create a copy or use reflection/modification (Hive supports field updates?)
      // Since it's final in Dart model, we should technically create a new object.
      // However, Hive objects are mutable if we just write them back.
      // Let's create a new object to be safe and cleaner.

      final updatedProp = Property(
        id: prop.id,
        userId: newUserId, // New User ID
        name: prop.name,
        totalArea: prop.totalArea,
        latitude: prop.latitude,
        longitude: prop.longitude,
        isDefault:
            hasNewDefault ? false : prop.isDefault, // Avoid multiple defaults
        createdAt: prop.createdAt,
        updatedAt: DateTime.now(),
      );

      await _box.put(prop.id, updatedProp);
    }
  }
}
