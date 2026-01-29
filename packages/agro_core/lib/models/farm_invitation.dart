import 'dart:math';

import 'farm_role.dart';

/// Status of a farm invitation.
enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
  revoked;

  /// Whether this invitation can still be used.
  bool get isActionable => this == InvitationStatus.pending;
}

/// An invitation to join a farm (Firestore-only — NOT stored in Hive).
///
/// Created by an owner or manager to invite new members.
/// Uses a 6-character alphanumeric code for easy sharing.
///
/// Stored in Firestore collection `farm_invitations`.
///
/// See CORE-90 for architecture.
class FarmInvitation {
  /// Firestore document ID.
  final String id;

  /// Farm being invited to.
  final String farmId;

  /// Farm name (cached for display on join screen).
  final String farmName;

  /// User ID of who created the invitation.
  final String invitedBy;

  /// Display name of the inviter (cached).
  final String inviterName;

  /// Role to assign when invitation is accepted.
  final FarmRole role;

  /// 6-character uppercase alphanumeric code.
  final String code;

  /// Current status of the invitation.
  final InvitationStatus status;

  /// When the invitation was created.
  final DateTime createdAt;

  /// When the invitation expires (default: 7 days after creation).
  final DateTime expiresAt;

  /// User ID of who accepted (set when accepted).
  final String? acceptedBy;

  /// When the invitation was accepted/declined/revoked.
  final DateTime? resolvedAt;

  const FarmInvitation({
    required this.id,
    required this.farmId,
    required this.farmName,
    required this.invitedBy,
    required this.inviterName,
    required this.role,
    required this.code,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.acceptedBy,
    this.resolvedAt,
  });

  /// Whether this invitation has expired based on current time.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this invitation can be used right now.
  bool get isUsable => status.isActionable && !isExpired;

  /// Generate a random 6-character uppercase alphanumeric code.
  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I,O,0,1 for clarity
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  /// Default invitation validity duration.
  static const Duration defaultValidity = Duration(days: 7);

  /// Create a new invitation.
  factory FarmInvitation.create({
    required String farmId,
    required String farmName,
    required String invitedBy,
    required String inviterName,
    required FarmRole role,
  }) {
    final now = DateTime.now();
    return FarmInvitation(
      id: '', // Set by Firestore
      farmId: farmId,
      farmName: farmName,
      invitedBy: invitedBy,
      inviterName: inviterName,
      role: role,
      code: generateCode(),
      status: InvitationStatus.pending,
      createdAt: now,
      expiresAt: now.add(defaultValidity),
    );
  }

  /// Convert to Firestore Map.
  Map<String, dynamic> toFirestore() {
    return {
      'farmId': farmId,
      'farmName': farmName,
      'invitedBy': invitedBy,
      'inviterName': inviterName,
      'role': role.index,
      'code': code,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      if (acceptedBy != null) 'acceptedBy': acceptedBy,
      if (resolvedAt != null) 'resolvedAt': resolvedAt!.toIso8601String(),
    };
  }

  /// Create from Firestore Map.
  factory FarmInvitation.fromFirestore(Map<String, dynamic> data, String docId) {
    return FarmInvitation(
      id: docId,
      farmId: data['farmId'] as String,
      farmName: data['farmName'] as String? ?? '',
      invitedBy: data['invitedBy'] as String,
      inviterName: data['inviterName'] as String? ?? '',
      role: FarmRole.values[data['role'] as int? ?? 2],
      code: data['code'] as String,
      status: InvitationStatus.values[data['status'] as int? ?? 0],
      createdAt: DateTime.parse(data['createdAt'] as String),
      expiresAt: DateTime.parse(data['expiresAt'] as String),
      acceptedBy: data['acceptedBy'] as String?,
      resolvedAt: data['resolvedAt'] != null
          ? DateTime.parse(data['resolvedAt'] as String)
          : null,
    );
  }

  /// Create a copy with updated status.
  FarmInvitation copyWith({
    InvitationStatus? status,
    String? acceptedBy,
    DateTime? resolvedAt,
  }) {
    return FarmInvitation(
      id: id,
      farmId: farmId,
      farmName: farmName,
      invitedBy: invitedBy,
      inviterName: inviterName,
      role: role,
      code: code,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  @override
  String toString() =>
      'FarmInvitation($code, farm: $farmId, role: ${role.name}, status: ${status.name})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FarmInvitation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
