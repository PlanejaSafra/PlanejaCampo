import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../models/farm_invitation.dart';
import '../services/farm_member_service.dart';

/// Screen for joining a farm using an invitation code.
///
/// The user enters a 6-character code, previews the farm details,
/// and confirms to join.
///
/// See CORE-90 for architecture.
class FarmJoinScreen extends StatefulWidget {
  const FarmJoinScreen({super.key});

  @override
  State<FarmJoinScreen> createState() => _FarmJoinScreenState();
}

class _FarmJoinScreenState extends State<FarmJoinScreen> {
  final _codeController = TextEditingController();
  FarmInvitation? _invitation;
  bool _lookingUp = false;
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _lookupCode() async {
    final l10n = AgroLocalizations.of(context)!;
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) return;

    setState(() {
      _lookingUp = true;
      _error = null;
      _invitation = null;
    });

    try {
      final invitation =
          await FarmMemberService.instance.lookupInvitationByCode(code);
      if (mounted) {
        setState(() {
          _invitation = invitation;
          _error = invitation == null ? l10n.farmJoinInvalidCode : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = l10n.farmJoinError);
      }
    }

    if (mounted) setState(() => _lookingUp = false);
  }

  Future<void> _acceptInvitation() async {
    if (_invitation == null) return;
    final l10n = AgroLocalizations.of(context)!;

    setState(() => _joining = true);
    try {
      await FarmMemberService.instance.acceptInvitation(_invitation!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.farmJoinSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().contains('Already a member')
            ? l10n.farmJoinAlreadyMember
            : l10n.farmJoinError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }
    if (mounted) setState(() => _joining = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AgroLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.farmJoinTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Code input
            Text(
              l10n.farmJoinEnterCode,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: theme.textTheme.headlineSmall?.copyWith(
                letterSpacing: 6,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: l10n.farmJoinCodeHint,
                border: const OutlineInputBorder(),
                counterText: '',
              ),
              onChanged: (value) {
                if (value.length == 6) _lookupCode();
              },
            ),
            const SizedBox(height: 12),

            // Lookup button
            OutlinedButton.icon(
              onPressed: _lookingUp || _codeController.text.length != 6
                  ? null
                  : _lookupCode,
              icon: _lookingUp
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: Text(l10n.farmJoinLookup),
            ),

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Preview
            if (_invitation != null) ...[
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.farmJoinPreview,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.agriculture),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.farmJoinFarmName(_invitation!.farmName),
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(_invitation!.role.icon,
                              color: _invitation!.role.color),
                          const SizedBox(width: 8),
                          Text(
                            l10n.farmJoinRole(
                                _invitation!.role.localizedName(l10n)),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.farmJoinInvitedBy(
                                  _invitation!.inviterName),
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _joining ? null : _acceptInvitation,
                icon: _joining
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(l10n.farmJoinConfirm),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
