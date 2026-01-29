import 'farm_role.dart';

/// A member of a farm (Firestore-only — NOT stored in Hive).
///
/// Represents a user's membership in a farm with a specific role.
/// Stored in Firestore collection `farm_members` with document ID
/// `{farmId}_{userId}` for uniqueness.
///
/// This model exists only in Firestore because membership is inherently
/// cross-user data that must be accessible from multiple devices/accounts.
///
/// See CORE-90 for architecture.
class FarmMember {
  /// Farm this membership belongs to.
  final String farmId;

  /// User ID (Firebase Auth UID) of the member.
  final String userId;

  /// Display name of the member (cached from Firebase Auth).
  final String userDisplayName;

  /// Email of the member (cached from Firebase Auth).
  final String userEmail;

  /// Role of this member in the farm.
  final FarmRole role;

  /// When this member joined the farm.
  final DateTime joinedAt;

  /// User ID of who invited this member. Null for the original owner.
  final String? invitedBy;

  const FarmMember({
    required this.farmId,
    required this.userId,
    required this.userDisplayName,
    required this.userEmail,
    required this.role,
    required this.joinedAt,
    this.invitedBy,
  });

  /// Firestore document ID: `{farmId}_{userId}`.
  String get documentId => '${farmId}_$userId';

  /// Convert to Firestore Map.
  Map<String, dynamic> toFirestore() {
    return {
      'farmId': farmId,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
      'role': role.index,
      'joinedAt': joinedAt.toIso8601String(),
      if (invitedBy != null) 'invitedBy': invitedBy,
    };
  }

  /// Create from Firestore Map.
  factory FarmMember.fromFirestore(Map<String, dynamic> data) {
    return FarmMember(
      farmId: data['farmId'] as String,
      userId: data['userId'] as String,
      userDisplayName: data['userDisplayName'] as String? ?? '',
      userEmail: data['userEmail'] as String? ?? '',
      role: FarmRole.values[data['role'] as int? ?? 2],
      joinedAt: DateTime.parse(data['joinedAt'] as String),
      invitedBy: data['invitedBy'] as String?,
    );
  }

  /// Create a new owner membership for a farm.
  factory FarmMember.owner({
    required String farmId,
    required String userId,
    required String displayName,
    required String email,
  }) {
    return FarmMember(
      farmId: farmId,
      userId: userId,
      userDisplayName: displayName,
      userEmail: email,
      role: FarmRole.owner,
      joinedAt: DateTime.now(),
    );
  }

  /// Create a new membership from an accepted invitation.
  factory FarmMember.fromInvitation({
    required String farmId,
    required String userId,
    required String displayName,
    required String email,
    required FarmRole role,
    required String invitedBy,
  }) {
    return FarmMember(
      farmId: farmId,
      userId: userId,
      userDisplayName: displayName,
      userEmail: email,
      role: role,
      joinedAt: DateTime.now(),
      invitedBy: invitedBy,
    );
  }

  /// Create a copy with updated role.
  FarmMember copyWithRole(FarmRole newRole) {
    return FarmMember(
      farmId: farmId,
      userId: userId,
      userDisplayName: userDisplayName,
      userEmail: userEmail,
      role: newRole,
      joinedAt: joinedAt,
      invitedBy: invitedBy,
    );
  }

  @override
  String toString() =>
      'FarmMember($userId, role: ${role.name}, farm: $farmId)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmMember &&
          runtimeType == other.runtimeType &&
          farmId == other.farmId &&
          userId == other.userId;

  @override
  int get hashCode => Object.hash(farmId, userId);
}
