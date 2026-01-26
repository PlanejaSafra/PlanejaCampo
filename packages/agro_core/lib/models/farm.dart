import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'farm.g.dart';

/// Model representing a farm in the RuraCamp ecosystem.
///
/// Farm is the central entity for multi-user preparation:
/// - All data (Pesagem, Entrega, etc.) belongs to a Farm via farmId
/// - Owner is the primary user who created/owns the farm
/// - Future: Multiple members with different roles (Manager, Worker)
///
/// Key Design Decisions:
/// - farmId uses UUID (NOT userId) to allow multiple farms per user
/// - Farm is stored locally (Hive) and included in cloud backups
/// - No Firestore direct integration (offline-first)
@HiveType(typeId: 20)
class Farm extends HiveObject {
  /// Unique identifier (UUID-based: "farm-{uuid}")
  /// Example: "farm-a1b2c3d4-e5f6-7890-abcd-ef1234567890"
  @HiveField(0)
  final String id;

  /// Farm name (ex: "Seringal Santa Fé", "Fazenda Primavera")
  @HiveField(1)
  String name;

  /// User ID of the farm owner (Firebase Auth UID)
  /// This is the primary owner who has full control
  @HiveField(2)
  final String ownerId;

  /// Creation timestamp
  @HiveField(3)
  final DateTime createdAt;

  /// Last update timestamp
  @HiveField(4)
  DateTime updatedAt;

  /// Whether this is the default farm for the user
  /// (only one farm per user can be default)
  @HiveField(5)
  bool isDefault;

  /// Optional description or notes about the farm
  @HiveField(6)
  String? description;

  /// Subscription tier that controls farm limits.
  /// - 'free': Max 1 farm per user (default)
  /// - 'basic': Expanded limits (future)
  /// - 'premium': Unlimited farms (future)
  ///
  /// Null means 'free' (backwards compatible with existing data).
  @HiveField(8)
  String? subscriptionTier;

  // Future fields (commented for reference):
  // @HiveField(7)
  // List<FarmMember>? members;

  Farm({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.createdAt,
    required this.updatedAt,
    this.isDefault = false,
    this.description,
    this.subscriptionTier,
  });

  /// Factory for creating a new farm with auto-generated UUID
  ///
  /// Usage:
  /// ```dart
  /// final farm = Farm.create(
  ///   name: 'Seringal Santa Fé',
  ///   ownerId: currentUserId,
  ///   isDefault: true,
  /// );
  /// ```
  factory Farm.create({
    required String name,
    required String ownerId,
    bool isDefault = false,
    String? description,
    String? subscriptionTier,
  }) {
    final now = DateTime.now();
    final uuid = const Uuid().v4();
    return Farm(
      id: 'farm-$uuid',
      name: name,
      ownerId: ownerId,
      createdAt: now,
      updatedAt: now,
      isDefault: isDefault,
      description: description,
      subscriptionTier: subscriptionTier,
    );
  }

  /// Update farm name
  void updateName(String newName) {
    name = newName;
    updatedAt = DateTime.now();
  }

  /// Update farm description
  void updateDescription(String? newDescription) {
    description = newDescription;
    updatedAt = DateTime.now();
  }

  /// Set as default farm
  void setAsDefault(bool value) {
    isDefault = value;
    updatedAt = DateTime.now();
  }

  /// Convert to JSON Map for backup/export
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isDefault': isDefault,
      'description': description,
      if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
    };
  }

  /// Create from JSON Map (backup/import)
  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDefault: json['isDefault'] as bool? ?? false,
      description: json['description'] as String?,
      subscriptionTier: json['subscriptionTier'] as String?,
    );
  }

  /// Display name (just the name for now, could include member count in future)
  String get displayName => name;

  /// Check if a user is the owner of this farm
  bool isOwner(String userId) => ownerId == userId;

  @override
  String toString() => 'Farm($id, $name, owner: $ownerId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Farm && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
