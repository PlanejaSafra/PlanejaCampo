import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/farm_invitation.dart';
import '../models/farm_member.dart';
import '../models/farm_role.dart';
import 'farm_service.dart';

/// Service for managing farm members and invitations via Firestore.
///
/// All member/invitation data lives exclusively in Firestore (not Hive)
/// because it's inherently cross-user data.
///
/// Firestore Collections:
/// - `farm_members`: One document per membership (`{farmId}_{userId}`)
/// - `farm_invitations`: One document per invitation (auto-ID)
///
/// See CORE-90 for architecture.
class FarmMemberService {
  static final FarmMemberService _instance = FarmMemberService._internal();
  static FarmMemberService get instance => _instance;
  factory FarmMemberService() => _instance;
  FarmMemberService._internal();

  final _firestore = FirebaseFirestore.instance;

  static const String _membersCollection = 'farm_members';
  static const String _invitationsCollection = 'farm_invitations';

  /// Current Firebase Auth user ID.
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Current user display name.
  String get _currentDisplayName =>
      FirebaseAuth.instance.currentUser?.displayName ?? '';

  /// Current user email.
  String get _currentEmail =>
      FirebaseAuth.instance.currentUser?.email ?? '';

  // ═══════════════════════════════════════════════════════════════════════════
  // Member Registration
  // ═══════════════════════════════════════════════════════════════════════════

  /// Register the current user as owner of a farm.
  ///
  /// Called when a farm's sharing is activated for the first time.
  /// Creates a FarmMember document in Firestore with [FarmRole.owner].
  Future<FarmMember> registerOwner(String farmId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final member = FarmMember.owner(
      farmId: farmId,
      userId: userId,
      displayName: _currentDisplayName,
      email: _currentEmail,
    );

    await _firestore
        .collection(_membersCollection)
        .doc(member.documentId)
        .set(member.toFirestore());

    debugPrint('[FarmMemberService] Registered owner for farm: $farmId');
    return member;
  }

  /// Get all members of a farm.
  Future<List<FarmMember>> getMembersForFarm(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_membersCollection)
          .where('farmId', isEqualTo: farmId)
          .get();

      return snapshot.docs
          .map((doc) => FarmMember.fromFirestore(doc.data()))
          .toList()
        ..sort((a, b) => a.role.index.compareTo(b.role.index));
    } catch (e) {
      debugPrint('[FarmMemberService] Error getting members: $e');
      return [];
    }
  }

  /// Get all farm memberships for the current user.
  ///
  /// Returns all FarmMember documents where `userId == currentUser`.
  Future<List<FarmMember>> getMyMemberships() async {
    final userId = _currentUserId;
    if (userId == null) return [];

    try {
      final snapshot = await _firestore
          .collection(_membersCollection)
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => FarmMember.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('[FarmMemberService] Error getting memberships: $e');
      return [];
    }
  }

  /// Get a specific member document.
  Future<FarmMember?> getMember(String farmId, String userId) async {
    try {
      final docId = '${farmId}_$userId';
      final doc = await _firestore
          .collection(_membersCollection)
          .doc(docId)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return FarmMember.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('[FarmMemberService] Error getting member: $e');
      return null;
    }
  }

  /// Update a member's role.
  Future<void> updateMemberRole(
    String farmId,
    String userId,
    FarmRole newRole,
  ) async {
    final docId = '${farmId}_$userId';
    await _firestore
        .collection(_membersCollection)
        .doc(docId)
        .update({'role': newRole.index});
    debugPrint('[FarmMemberService] Updated role for $userId to ${newRole.name}');
  }

  /// Remove a member from a farm.
  Future<void> removeMember(String farmId, String userId) async {
    final docId = '${farmId}_$userId';
    await _firestore
        .collection(_membersCollection)
        .doc(docId)
        .delete();
    debugPrint('[FarmMemberService] Removed member $userId from farm $farmId');
  }

  /// Leave a farm (current user removes themselves).
  ///
  /// Also removes the local Farm object via FarmService.
  Future<void> leaveFarm(String farmId) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    // Remove from Firestore
    await removeMember(farmId, userId);

    // Remove local farm copy
    await FarmService.instance.removeJoinedFarm(farmId);
    debugPrint('[FarmMemberService] Left farm: $farmId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Invitations
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create an invitation to join a farm.
  ///
  /// Returns the created invitation with a generated 6-char code.
  Future<FarmInvitation> createInvitation({
    required String farmId,
    required String farmName,
    required FarmRole role,
  }) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    final invitation = FarmInvitation.create(
      farmId: farmId,
      farmName: farmName,
      invitedBy: userId,
      inviterName: _currentDisplayName,
      role: role,
    );

    final docRef = await _firestore
        .collection(_invitationsCollection)
        .add(invitation.toFirestore());

    debugPrint(
        '[FarmMemberService] Created invitation: ${invitation.code} '
        'for farm $farmId (role: ${role.name})');

    // Return with Firestore-assigned ID
    return FarmInvitation.fromFirestore(
      invitation.toFirestore(),
      docRef.id,
    );
  }

  /// Look up an invitation by its 6-character code.
  ///
  /// Returns null if not found or already used/expired.
  Future<FarmInvitation?> lookupInvitationByCode(String code) async {
    final normalizedCode = code.trim().toUpperCase();
    if (normalizedCode.length != 6) return null;

    try {
      final snapshot = await _firestore
          .collection(_invitationsCollection)
          .where('code', isEqualTo: normalizedCode)
          .where('status', isEqualTo: InvitationStatus.pending.index)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final invitation = FarmInvitation.fromFirestore(doc.data(), doc.id);

      // Check expiration
      if (invitation.isExpired) {
        // Mark as expired in Firestore
        await doc.reference.update({
          'status': InvitationStatus.expired.index,
          'resolvedAt': DateTime.now().toIso8601String(),
        });
        return null;
      }

      return invitation;
    } catch (e) {
      debugPrint('[FarmMemberService] Error looking up invitation: $e');
      return null;
    }
  }

  /// Accept an invitation.
  ///
  /// Creates a FarmMember for the current user and adds a local Farm copy.
  /// Returns the created FarmMember.
  Future<FarmMember> acceptInvitation(FarmInvitation invitation) async {
    final userId = _currentUserId;
    if (userId == null) throw Exception('User not authenticated');

    if (!invitation.isUsable) {
      throw Exception('Invitation is no longer valid');
    }

    // Check if already a member
    final existing = await getMember(invitation.farmId, userId);
    if (existing != null) {
      throw Exception('Already a member of this farm');
    }

    // Create membership in Firestore
    final member = FarmMember.fromInvitation(
      farmId: invitation.farmId,
      userId: userId,
      displayName: _currentDisplayName,
      email: _currentEmail,
      role: invitation.role,
      invitedBy: invitation.invitedBy,
    );

    await _firestore
        .collection(_membersCollection)
        .doc(member.documentId)
        .set(member.toFirestore());

    // Update invitation status
    await _firestore
        .collection(_invitationsCollection)
        .doc(invitation.id)
        .update({
      'status': InvitationStatus.accepted.index,
      'acceptedBy': userId,
      'resolvedAt': DateTime.now().toIso8601String(),
    });

    // Add local farm copy
    await FarmService.instance.addJoinedFarm(
      farmId: invitation.farmId,
      farmName: invitation.farmName,
      ownerId: invitation.invitedBy,
      role: invitation.role,
      isShared: true,
    );

    debugPrint(
        '[FarmMemberService] Accepted invitation ${invitation.code} '
        'for farm ${invitation.farmId}');
    return member;
  }

  /// Revoke a pending invitation (by the inviter or farm owner).
  Future<void> revokeInvitation(String invitationId) async {
    await _firestore
        .collection(_invitationsCollection)
        .doc(invitationId)
        .update({
      'status': InvitationStatus.revoked.index,
      'resolvedAt': DateTime.now().toIso8601String(),
    });
    debugPrint('[FarmMemberService] Revoked invitation: $invitationId');
  }

  /// Get all pending invitations for a farm.
  Future<List<FarmInvitation>> getPendingInvitations(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_invitationsCollection)
          .where('farmId', isEqualTo: farmId)
          .where('status', isEqualTo: InvitationStatus.pending.index)
          .get();

      final invitations = <FarmInvitation>[];
      for (final doc in snapshot.docs) {
        final invitation = FarmInvitation.fromFirestore(doc.data(), doc.id);
        if (invitation.isExpired) {
          // Auto-expire
          await doc.reference.update({
            'status': InvitationStatus.expired.index,
            'resolvedAt': DateTime.now().toIso8601String(),
          });
        } else {
          invitations.add(invitation);
        }
      }

      return invitations
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('[FarmMemberService] Error getting invitations: $e');
      return [];
    }
  }

  /// Get member count for a farm.
  Future<int> getMemberCount(String farmId) async {
    try {
      final snapshot = await _firestore
          .collection(_membersCollection)
          .where('farmId', isEqualTo: farmId)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('[FarmMemberService] Error counting members: $e');
      return 0;
    }
  }
}
