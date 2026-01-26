import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/user_profile.dart';
import '../services/onboarding_service.dart';

/// Onboarding screen with a PageView of 2-3 pages.
///
/// Page 1: Welcome + Seringal name input
/// Page 2: Profile selection (Produtor/Sangrador/Comprador)
/// Page 3 (conditional):
///   - Produtor: "How many tappers?" chip buttons
///   - Sangrador: Boss name input
///   - Comprador: Skipped
///
/// Takes a [VoidCallback] [onComplete] that is called after onboarding finishes.
class OnboardingScreen extends StatefulWidget {
  /// Callback when onboarding is completed and data is saved.
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _seringalNameController = TextEditingController();
  final TextEditingController _bossNameController = TextEditingController();

  int _currentPage = 0;
  UserProfileType? _selectedProfile;
  String? _selectedTapperCount;
  bool _isLoading = false;

  /// Total number of pages depends on profile selection.
  int get _totalPages {
    if (_selectedProfile == UserProfileType.comprador) return 2;
    return 3;
  }

  /// Whether the current page allows advancing.
  bool get _canAdvance {
    switch (_currentPage) {
      case 0:
        // Page 1: Always can advance (name has default)
        return true;
      case 1:
        // Page 2: Must select a profile
        return _selectedProfile != null;
      case 2:
        // Page 3: Produtor needs tapper count; Sangrador always can advance
        if (_selectedProfile == UserProfileType.produtor) {
          return _selectedTapperCount != null;
        }
        return true; // Sangrador: boss name is optional
      default:
        return false;
    }
  }

  /// Whether we're on the last page.
  bool get _isLastPage => _currentPage == _totalPages - 1;

  void _nextPage() {
    if (_isLastPage) {
      _completeOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      await OnboardingService.instance.completeOnboarding(
        seringalName: _seringalNameController.text,
        profileType: _selectedProfile!,
        tapperCountSelection: _selectedTapperCount,
        bossNameValue: _selectedProfile == UserProfileType.sangrador
            ? _bossNameController.text.trim().isNotEmpty
                ? _bossNameController.text.trim()
                : null
            : null,
      );
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        final l10n = BorrachaLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.errorLabel}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _seringalNameController.dispose();
    _bossNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = BorrachaLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
              child: _PageIndicator(
                currentPage: _currentPage,
                totalPages: _totalPages,
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _WelcomePage(
                    nameController: _seringalNameController,
                    l10n: l10n,
                  ),
                  _ProfilePage(
                    selectedProfile: _selectedProfile,
                    onProfileSelected: (type) {
                      setState(() {
                        _selectedProfile = type;
                        // Reset page 3 selections when profile changes
                        _selectedTapperCount = null;
                        _bossNameController.clear();
                      });
                    },
                    l10n: l10n,
                  ),
                  // Page 3: conditional based on profile
                  if (_selectedProfile == UserProfileType.produtor)
                    _TapperCountPage(
                      selectedCount: _selectedTapperCount,
                      onCountSelected: (count) {
                        setState(() => _selectedTapperCount = count);
                      },
                      l10n: l10n,
                    )
                  else if (_selectedProfile == UserProfileType.sangrador)
                    _BossNamePage(
                      bossNameController: _bossNameController,
                      l10n: l10n,
                    )
                  else
                    // Fallback (Comprador - should not reach page 3)
                    const SizedBox.shrink(),
                ],
              ),
            ),

            // Bottom button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: FilledButton(
                onPressed: _canAdvance && !_isLoading ? _nextPage : null,
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
                        _isLastPage ? l10n.onboardingStart : l10n.profileContinue,
                        style: const TextStyle(fontSize: 18),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Page indicator dots at the top.
class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int totalPages;

  const _PageIndicator({
    required this.currentPage,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 12,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Page 1: Welcome + Seringal name input.
class _WelcomePage extends StatelessWidget {
  final TextEditingController nameController;
  final BorrachaLocalizations l10n;

  const _WelcomePage({
    required this.nameController,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),

          // Welcome icon
          Icon(
            Icons.forest,
            size: 80,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),

          // Welcome title
          Text(
            l10n.onboardingWelcome,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),

          // Seringal name input
          Text(
            l10n.onboardingSeringalName,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: l10n.onboardingSeringalHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.agriculture),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Page 2: Profile selection (Produtor/Sangrador/Comprador).
class _ProfilePage extends StatelessWidget {
  final UserProfileType? selectedProfile;
  final ValueChanged<UserProfileType> onProfileSelected;
  final BorrachaLocalizations l10n;

  const _ProfilePage({
    required this.selectedProfile,
    required this.onProfileSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),

          // Title
          Text(
            l10n.onboardingYouAre,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Produtor card
          _OnboardingProfileCard(
            icon: Icons.agriculture,
            iconColor: Colors.green,
            title: l10n.profileProdutor,
            isSelected: selectedProfile == UserProfileType.produtor,
            onTap: () => onProfileSelected(UserProfileType.produtor),
          ),
          const SizedBox(height: 12),

          // Sangrador card
          _OnboardingProfileCard(
            icon: Icons.water_drop,
            iconColor: Colors.brown,
            title: l10n.profileSangrador,
            isSelected: selectedProfile == UserProfileType.sangrador,
            onTap: () => onProfileSelected(UserProfileType.sangrador),
          ),
          const SizedBox(height: 12),

          // Comprador card
          _OnboardingProfileCard(
            icon: Icons.store,
            iconColor: Colors.blue,
            title: l10n.profileComprador,
            isSelected: selectedProfile == UserProfileType.comprador,
            onTap: () => onProfileSelected(UserProfileType.comprador),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Simplified profile card for onboarding.
class _OnboardingProfileCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _OnboardingProfileCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 16),

              // Title
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Check indicator
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

/// Page 3 (Produtor): "How many tappers?" with chip buttons.
class _TapperCountPage extends StatelessWidget {
  final String? selectedCount;
  final ValueChanged<String> onCountSelected;
  final BorrachaLocalizations l10n;

  const _TapperCountPage({
    required this.selectedCount,
    required this.onCountSelected,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final options = [
      _TapperOption(key: 'just_me', label: l10n.onboardingJustMe),
      _TapperOption(key: '1-2', label: l10n.onboardingOneTwoTappers),
      _TapperOption(key: '3-5', label: l10n.onboardingThreeFiveTappers),
      _TapperOption(key: '6+', label: l10n.onboardingSixPlusTappers),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 1),

          // Title
          Text(
            l10n.onboardingHowManyTappers,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Chip buttons
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: options.map((option) {
              final isSelected = selectedCount == option.key;
              return ChoiceChip(
                label: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                selected: isSelected,
                onSelected: (_) => onCountSelected(option.key),
                selectedColor: theme.colorScheme.primaryContainer,
                showCheckmark: false,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              );
            }).toList(),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

/// Helper data class for tapper count options.
class _TapperOption {
  final String key;
  final String label;

  const _TapperOption({required this.key, required this.label});
}

/// Page 3 (Sangrador): Boss name input.
class _BossNamePage extends StatelessWidget {
  final TextEditingController bossNameController;
  final BorrachaLocalizations l10n;

  const _BossNamePage({
    required this.bossNameController,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),

          // Icon
          Icon(
            Icons.person,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            l10n.onboardingTapperBossName,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Boss name input
          TextField(
            controller: bossNameController,
            decoration: InputDecoration(
              hintText: l10n.onboardingTapperBossHint,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.badge),
            ),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
          ),

          const Spacer(flex: 3),
        ],
      ),
    );
  }
}
