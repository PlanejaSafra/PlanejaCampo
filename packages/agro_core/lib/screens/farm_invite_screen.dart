import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm.dart';
import '../models/farm_invitation.dart';
import '../models/farm_role.dart';
import '../services/farm_member_service.dart';
import '../services/farm_service.dart';

/// Screen for creating and managing farm invitations.
///
/// Owner/Manager can:
/// - Select a role for the invitee
/// - Generate a 6-character invitation code
/// - Copy or share the code
/// - View and revoke pending invitations
///
/// See CORE-90 for architecture.
class FarmInviteScreen extends StatefulWidget {
  /// The farm to invite members to. Defaults to active farm.
  final String? farmId;

  const FarmInviteScreen({super.key, this.farmId});

  @override
  State<FarmInviteScreen> createState() => _FarmInviteScreenState();
}

class _FarmInviteScreenState extends State<FarmInviteScreen> {
  FarmRole _selectedRole = FarmRole.worker;
  FarmInvitation? _generatedInvitation;
  List<FarmInvitation> _pendingInvitations = [];
  bool _loading = false;
  bool _loadingPending = true;

  Farm? get _farm {
    if (widget.farmId != null) {
      return FarmService.instance.getFarmById(widget.farmId!);
    }
    return FarmService.instance.getActiveFarm();
  }

  @override
  void initState() {
    super.initState();
    _loadPendingInvitations();
  }

  Future<void> _loadPendingInvitations() async {
    final farm = _farm;
    if (farm == null) return;

    setState(() => _loadingPending = true);
    try {
      _pendingInvitations = await FarmMemberService.instance
          .getPendingInvitations(farm.id);
    } catch (_) {
      // Non-fatal
    }
    if (mounted) setState(() => _loadingPending = false);
  }

  Future<void> _generateInvitation() async {
    final farm = _farm;
    if (farm == null) return;

    setState(() => _loading = true);
    try {
      final invitation = await FarmMemberService.instance.createInvitation(
        farmId: farm.id,
        farmName: farm.name,
        role: _selectedRole,
      );
      setState(() => _generatedInvitation = invitation);
      _loadPendingInvitations();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _revokeInvitation(FarmInvitation invitation) async {
    final l10n = AgroLocalizations.of(context)!;
    try {
      await FarmMemberService.instance.revokeInvitation(invitation.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmInviteRevoked)),
        );
      }
      _loadPendingInvitations();
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
    final permissions = FarmService.instance.getActivePermissions();
    final maxRole = permissions.maxInvitableRole;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.farmInviteTitle)),
      body: farm == null
          ? Center(child: Text(l10n.farmSwitcherEmpty))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Role selector
                Text(
                  l10n.farmInviteSelectRole,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...FarmRole.values
                    .where((r) => r != FarmRole.owner && r.index >= maxRole.index)
                    .map((role) => RadioListTile<FarmRole>(
                          title: Text(role.localizedName(l10n)),
                          subtitle: Text(role.localizedDescription(l10n)),
                          secondary: Icon(role.icon, color: role.color),
                          value: role,
                          groupValue: _selectedRole,
                          onChanged: (v) {
                            if (v != null) setState(() => _selectedRole = v);
                          },
                        )),
                const SizedBox(height: 16),

                // Generate button
                FilledButton.icon(
                  onPressed: _loading ? null : _generateInvitation,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_link),
                  label: Text(l10n.farmInviteGenerate),
                ),

                // Generated code
                if (_generatedInvitation != null) ...[
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            l10n.farmInviteCode,
                            style: theme.textTheme.labelMedium,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            _generatedInvitation!.code,
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.farmInviteExpires,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(
                                    text: _generatedInvitation!.code,
                                  ));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(l10n.farmInviteCodeCopied)),
                                  );
                                },
                                icon: const Icon(Icons.copy, size: 16),
                                label: Text(l10n.farmInviteCodeCopied),
                              ),
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                onPressed: () {
                                  Share.share(
                                    l10n.farmInviteShareMessage(
                                      farm.name,
                                      _generatedInvitation!.code,
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.share, size: 16),
                                label: Text(l10n.farmInviteShare),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Pending invitations
                const SizedBox(height: 24),
                Text(
                  l10n.farmInvitePending,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (_loadingPending)
                  const Center(child: CircularProgressIndicator())
                else if (_pendingInvitations.isEmpty)
                  Text(
                    l10n.farmInviteNoPending,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  )
                else
                  ..._pendingInvitations.map((inv) => Card(
                        child: ListTile(
                          leading: Icon(inv.role.icon, color: inv.role.color),
                          title: Text(inv.code,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2)),
                          subtitle: Text(inv.role.localizedName(l10n)),
                          trailing: TextButton(
                            onPressed: () => _revokeInvitation(inv),
                            child: Text(l10n.farmInviteRevoke),
                          ),
                        ),
                      )),
              ],
            ),
    );
  }
}
