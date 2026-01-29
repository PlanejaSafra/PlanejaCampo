import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm.dart';
import '../models/farm_member.dart';
import '../models/farm_permissions.dart';
import '../models/farm_role.dart';
import '../services/farm_member_service.dart';
import '../services/farm_service.dart';
import 'farm_invite_screen.dart';

/// Screen for viewing and managing farm members.
///
/// Owner can: view members, change roles, remove members, invite new.
/// Manager can: view members, invite workers.
/// Worker can: view members, leave farm.
///
/// See CORE-90 for architecture.
class FarmMembersScreen extends StatefulWidget {
  /// The farm to manage members for. Defaults to active farm.
  final String? farmId;

  const FarmMembersScreen({super.key, this.farmId});

  @override
  State<FarmMembersScreen> createState() => _FarmMembersScreenState();
}

class _FarmMembersScreenState extends State<FarmMembersScreen> {
  List<FarmMember> _members = [];
  bool _loading = true;

  Farm? get _farm {
    if (widget.farmId != null) {
      return FarmService.instance.getFarmById(widget.farmId!);
    }
    return FarmService.instance.getActiveFarm();
  }

  FarmPermissions get _permissions =>
      FarmService.instance.getActivePermissions();

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final farm = _farm;
    if (farm == null) return;

    setState(() => _loading = true);
    try {
      _members = await FarmMemberService.instance.getMembersForFarm(farm.id);
    } catch (_) {
      // Non-fatal
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _removeMember(FarmMember member) async {
    final l10n = AgroLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.farmMembersRemove),
        content: Text(l10n.farmMembersRemoveConfirm(member.userDisplayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.farmMembersRemove),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FarmMemberService.instance.removeMember(
        member.farmId,
        member.userId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmMembersRemoved)),
        );
      }
      _loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _changeRole(FarmMember member) async {
    final l10n = AgroLocalizations.of(context)!;

    final newRole = await showDialog<FarmRole>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.farmMembersChangeRole),
        children: FarmRole.values
            .where((r) => r != FarmRole.owner && r != member.role)
            .map((role) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, role),
                  child: ListTile(
                    leading: Icon(role.icon, color: role.color),
                    title: Text(role.localizedName(l10n)),
                    subtitle: Text(role.localizedDescription(l10n)),
                  ),
                ))
            .toList(),
      ),
    );

    if (newRole == null) return;

    try {
      await FarmMemberService.instance.updateMemberRole(
        member.farmId,
        member.userId,
        newRole,
      );
      _loadMembers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _leaveFarm() async {
    final l10n = AgroLocalizations.of(context)!;
    final farm = _farm;
    if (farm == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.farmLeave),
        content: Text(l10n.farmLeaveConfirm(farm.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.farmLeave),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FarmMemberService.instance.leaveFarm(farm.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmLeaveSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);
    final farm = _farm;
    final permissions = _permissions;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.farmMembersTitle),
        actions: [
          if (permissions.canLeaveFarm)
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: l10n.farmLeave,
              onPressed: _leaveFarm,
            ),
        ],
      ),
      floatingActionButton: permissions.canInviteMembers
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FarmInviteScreen(farmId: farm?.id),
                  ),
                );
                _loadMembers();
              },
              icon: const Icon(Icons.person_add),
              label: Text(l10n.farmInviteTitle),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? Center(
                  child: Text(
                    l10n.farmMembersEmpty,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMembers,
                  child: ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      return _MemberTile(
                        member: member,
                        permissions: permissions,
                        onRemove: permissions.canRemoveMemberWithRole(member.role)
                            ? () => _removeMember(member)
                            : null,
                        onChangeRole: permissions.canChangeRoleTo(
                                member.role, FarmRole.worker)
                            ? () => _changeRole(member)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final FarmMember member;
  final FarmPermissions permissions;
  final VoidCallback? onRemove;
  final VoidCallback? onChangeRole;

  const _MemberTile({
    required this.member,
    required this.permissions,
    this.onRemove,
    this.onChangeRole,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMMMd();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: member.role.color.withValues(alpha: 0.15),
        child: Icon(member.role.icon, color: member.role.color),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.userDisplayName.isNotEmpty
                  ? member.userDisplayName
                  : member.userEmail,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: member.role.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              member.role.localizedName(l10n),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: member.role.color,
              ),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.farmMembersSince(dateFormat.format(member.joinedAt))),
          if (member.invitedBy != null)
            Text(
              l10n.farmMembersInvitedBy(member.invitedBy!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
        ],
      ),
      trailing: (onRemove != null || onChangeRole != null)
          ? PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (onChangeRole != null)
                  PopupMenuItem(
                    value: 'role',
                    child: ListTile(
                      leading: const Icon(Icons.swap_horiz),
                      title: Text(l10n.farmMembersChangeRole),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (onRemove != null)
                  PopupMenuItem(
                    value: 'remove',
                    child: ListTile(
                      leading: Icon(Icons.person_remove,
                          color: theme.colorScheme.error),
                      title: Text(l10n.farmMembersRemove,
                          style: TextStyle(color: theme.colorScheme.error)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
              onSelected: (value) {
                if (value == 'role') onChangeRole?.call();
                if (value == 'remove') onRemove?.call();
              },
            )
          : null,
      isThreeLine: member.invitedBy != null,
    );
  }
}
