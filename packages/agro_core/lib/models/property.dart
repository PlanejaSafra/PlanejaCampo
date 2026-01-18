import 'package:hive/hive.dart';

part 'property.g.dart';

/// Model representing a farm/property where agricultural activities take place.
/// Properties are shared across all PlanejaSafra apps (PlanejaChuva, PlanejaBorracha, etc.)
/// and associated with a userId for multi-device sync.
@HiveType(typeId: 10)
class Property extends HiveObject {
  /// Unique identifier (timestamp-based)
  @HiveField(0)
  final String id;

  /// User ID from Firebase Auth (for cross-app and multi-device access)
  @HiveField(1)
  final String userId;

  /// Property name (ex: "Fazenda Primavera", "Sítio do Vale")
  @HiveField(2)
  String name;

  /// Total area in hectares (optional)
  @HiveField(3)
  double? totalArea;

  /// Latitude for regional statistics and weather forecasts (optional)
  @HiveField(4)
  double? latitude;

  /// Longitude for regional statistics and weather forecasts (optional)
  @HiveField(5)
  double? longitude;

  /// Whether this is the default property for new records
  /// (only one property per user can be default)
  @HiveField(6)
  bool isDefault;

  /// Creation timestamp
  @HiveField(7)
  final DateTime createdAt;

  /// Last update timestamp
  @HiveField(8)
  DateTime updatedAt;

  Property({
    required this.id,
    required this.userId,
    required this.name,
    this.totalArea,
    this.latitude,
    this.longitude,
    this.isDefault = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory for creating a new property with auto-generated ID
  factory Property.create({
    required String userId,
    required String name,
    double? totalArea,
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) {
    final now = DateTime.now();
    return Property(
      id: now.millisecondsSinceEpoch.toString(),
      userId: userId,
      name: name,
      totalArea: totalArea,
      latitude: latitude,
      longitude: longitude,
      isDefault: isDefault,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Update property name
  void updateName(String newName) {
    name = newName;
    updatedAt = DateTime.now();
  }

  /// Update total area
  void updateTotalArea(double? newArea) {
    totalArea = newArea;
    updatedAt = DateTime.now();
  }

  /// Update location coordinates
  void updateLocation(double? lat, double? lng) {
    latitude = lat;
    longitude = lng;
    updatedAt = DateTime.now();
  }

  /// Convert to Map for Firestore sync
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'totalArea': totalArea,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from Firestore Map
  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      userId: map['userId'] as String,
      name: map['name'] as String,
      totalArea: map['totalArea'] as double?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Display string with area if available
  String get displayName {
    if (totalArea != null && totalArea! > 0) {
      return '$name (${totalArea!.toStringAsFixed(1)} ha)';
    }
    return name;
  }

  /// Check if property has location coordinates
  bool get hasLocation => latitude != null && longitude != null;
}
