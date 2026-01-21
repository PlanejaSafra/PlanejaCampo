import 'package:hive/hive.dart';

part 'user_profile.g.dart';

/// Type of user profile - determines app behavior and available features.
@HiveType(typeId: 20)
enum UserProfileType {
  /// Producer/Farmer - sees dashboard with weighing history, partners, and market offers.
  @HiveField(0)
  produtor,

  /// Buyer - sees dashboard with their offers, statistics, and producer connections.
  @HiveField(1)
  comprador,

  /// Tapper/Rubber collector - sees simplified weighing interface and partner tracking.
  @HiveField(2)
  sangrador,
}

/// User profile stored locally to determine app behavior.
@HiveType(typeId: 21)
class UserProfile extends HiveObject {
  /// The type of profile (produtor or comprador).
  @HiveField(0)
  UserProfileType profileType;

  /// Display name (optional, can be synced from Google account).
  @HiveField(1)
  String? displayName;

  /// Whether the profile setup is complete.
  @HiveField(2)
  bool profileComplete;

  /// When the profile was created.
  @HiveField(3)
  DateTime createdAt;

  /// When the profile was last updated.
  @HiveField(4)
  DateTime? updatedAt;

  UserProfile({
    required this.profileType,
    this.displayName,
    this.profileComplete = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Copy with method for immutable updates.
  UserProfile copyWith({
    UserProfileType? profileType,
    String? displayName,
    bool? profileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      profileType: profileType ?? this.profileType,
      displayName: displayName ?? this.displayName,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether this is a producer profile.
  bool get isProdutor => profileType == UserProfileType.produtor;

  /// Whether this is a buyer profile.
  bool get isComprador => profileType == UserProfileType.comprador;

  /// Whether this is a tapper profile.
  bool get isSangrador => profileType == UserProfileType.sangrador;
}
