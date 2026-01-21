import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_profile.dart';
import '../services/user_profile_service.dart';

/// Screen for selecting user profile type (Produtor/Comprador).
/// Shown after first login when no profile is set.
class ProfileSelectionScreen extends StatefulWidget {
  /// Callback when profile is selected and saved.
  final VoidCallback onProfileSelected;

  const ProfileSelectionScreen({
    super.key,
    required this.onProfileSelected,
  });

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  UserProfileType? _selectedType;
  bool _isLoading = false;

  Future<void> _saveProfile() async {
    if (_selectedType == null) return;

    setState(() => _isLoading = true);

    try {
      await UserProfileService.instance.setProfile(
        profileType: _selectedType!,
      );
      widget.onProfileSelected();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 1),

              // Title
              Text(
                l10n.profileSelectionTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                l10n.profileSelectionSubtitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Produtor Card
              _ProfileCard(
                icon: Icons.agriculture,
                iconColor: Colors.green,
                title: l10n.profileProdutor,
                description: l10n.profileProdutorDesc,
                isSelected: _selectedType == UserProfileType.produtor,
                onTap: () {
                  setState(() => _selectedType = UserProfileType.produtor);
                },
              ),
              const SizedBox(height: 16),

              // Comprador Card
              _ProfileCard(
                icon: Icons.store,
                iconColor: Colors.blue,
                title: l10n.profileComprador,
                description: l10n.profileCompradorDesc,
                isSelected: _selectedType == UserProfileType.comprador,
                onTap: () {
                  setState(() => _selectedType = UserProfileType.comprador);
                },
              ),

              const Spacer(flex: 2),

              // Continue Button
              FilledButton(
                onPressed:
                    _selectedType != null && !_isLoading ? _saveProfile : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        l10n.profileContinue,
                        style: const TextStyle(fontSize: 18),
                      ),
              ),

              if (_selectedType == null) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.profileSelectOne,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card widget for profile selection.
class _ProfileCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Icon Container
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
