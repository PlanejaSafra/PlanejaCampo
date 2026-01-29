import 'farm_role.dart';

/// Permission matrix for farm operations based on [FarmRole].
///
/// Pure Dart class (no Hive, no Firestore) — used to check whether the
/// current user is allowed to perform a given action on the active farm.
///
/// See CORE-90 for architecture.
class FarmPermissions {
  final FarmRole role;

  const FarmPermissions(this.role);

  // ═══════════════════════════════════════════════════════════════════════════
  // Data Access
  // ═══════════════════════════════════════════════════════════════════════════

  /// Can view farm data (records, reports, etc.)
  bool get canViewData => true;

  /// Can create new records (lancamentos, entregas, etc.)
  bool get canCreateRecords => true;

  /// Can edit records created by other members.
  /// Workers can only edit their own records.
  bool get canEditOthersRecords {
    switch (role) {
      case FarmRole.owner:
      case FarmRole.manager:
        return true;
      case FarmRole.worker:
        return false;
    }
  }

  /// Can delete records.
  /// Workers cannot delete any records; managers can delete any.
  bool get canDeleteRecords {
    switch (role) {
      case FarmRole.owner:
      case FarmRole.manager:
        return true;
      case FarmRole.worker:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Backup & Restore
  // ═══════════════════════════════════════════════════════════════════════════

  /// Can perform backup and restore operations.
  bool get canBackupRestore {
    switch (role) {
      case FarmRole.owner:
        return true;
      case FarmRole.manager:
      case FarmRole.worker:
        return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Member Management
  // ═══════════════════════════════════════════════════════════════════════════

  /// Can invite new members to the farm.
  bool get canInviteMembers {
    switch (role) {
      case FarmRole.owner:
      case FarmRole.manager:
        return true;
      case FarmRole.worker:
        return false;
    }
  }

  /// Can remove members from the farm.
  /// Managers can remove workers; owner can remove anyone.
  bool get canRemoveMembers {
    switch (role) {
      case FarmRole.owner:
        return true;
      case FarmRole.manager:
      case FarmRole.worker:
        return false;
    }
  }

  /// Can change roles of other members.
  bool get canChangeRoles {
    switch (role) {
      case FarmRole.owner:
        return true;
      case FarmRole.manager:
      case FarmRole.worker:
        return false;
    }
  }

  /// Can leave the farm (non-owners only).
  bool get canLeaveFarm {
    switch (role) {
      case FarmRole.owner:
        return false; // Owner must transfer or delete
      case FarmRole.manager:
      case FarmRole.worker:
        return true;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Farm Settings
  // ═══════════════════════════════════════════════════════════════════════════

  /// Can toggle sharing (isShared) on the farm.
  bool get canToggleSharing {
    switch (role) {
      case FarmRole.owner:
        return true;
      case FarmRole.manager:
      case FarmRole.worker:
        return false;
    }
  }

  /// Can edit farm name, description, etc.
  bool get canEditFarmSettings {
    switch (role) {
      case FarmRole.owner:
      case FarmRole.manager:
        return true;
      case FarmRole.worker:
        return false;
    }
  }

  /// Can delete the farm entirely.
  bool get canDeleteFarm {
    switch (role) {
      case FarmRole.owner:
        return true;
      case FarmRole.manager:
      case FarmRole.worker:
        return false;
    }
  }

  /// Check if this role can remove a member with [targetRole].
  bool canRemoveMemberWithRole(FarmRole targetRole) {
    if (!canRemoveMembers) return false;
    // Owner can remove anyone (except themselves — handled elsewhere)
    if (role == FarmRole.owner) return targetRole != FarmRole.owner;
    return false;
  }

  /// Check if this role can change [targetRole] to [newRole].
  bool canChangeRoleTo(FarmRole targetRole, FarmRole newRole) {
    if (!canChangeRoles) return false;
    // Cannot change own role
    // Owner can promote/demote managers and workers
    if (role == FarmRole.owner) {
      return targetRole != FarmRole.owner;
    }
    return false;
  }

  /// Returns the maximum role that can be assigned when inviting.
  /// Owner can invite managers; managers can only invite workers.
  FarmRole get maxInvitableRole {
    switch (role) {
      case FarmRole.owner:
        return FarmRole.manager;
      case FarmRole.manager:
        return FarmRole.worker;
      case FarmRole.worker:
        return FarmRole.worker; // Cannot invite
    }
  }
}
