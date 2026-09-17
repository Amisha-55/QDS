import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/shared/widgets/app_button.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Data model representing an onboarding step.
class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accentStatus,
    required this.secondaryIcon,
  });

  final String title;
  final String description;
  final IconData icon;
  final QdsSecurityStatus accentStatus;
  final IconData secondaryIcon;
}

/// A 3-step walkthrough introducing QDS core capabilities.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Private conversations',
      description: 'Send messages through a familiar, simple communication experience.',
      icon: Icons.chat_bubble_outline_rounded,
      accentStatus: QdsSecurityStatus.trusted,
      secondaryIcon: Icons.lock_outline_rounded,
    ),
    _OnboardingPageData(
      title: 'Verified communication',
      description: 'Messages can be checked using cryptographic verification and security measurements.',
      icon: Icons.verified_user_outlined,
      accentStatus: QdsSecurityStatus.verified,
      secondaryIcon: Icons.fact_check_outlined,
    ),
    _OnboardingPageData(
      title: 'Security when it matters',
      description: 'Suspicious activity can be surfaced with clear security information and threat details.',
      icon: Icons.shield_outlined,
      accentStatus: QdsSecurityStatus.monitoring,
      secondaryIcon: Icons.radar_rounded,
    ),
  ];

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _finishOnboarding() async {
    await LocalStorage.instance.setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.setup);
  }

  void _nextPage() {
    if (_isLastPage) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: AppDurations.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDurations.normal,
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(theme),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(context, _pages[index]);
                },
              ),
            ),
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPadding,
        vertical: AppSpacing.sm,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Previous page',
                onPressed: _previousPage,
                color: theme.colorScheme.onSurface,
              )
            else
              const SizedBox(width: 48),
            if (!_isLastPage)
              TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: AppTypography.button.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              )
            else
              const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, _OnboardingPageData data) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppDimensions.screenPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 1),
                  _buildIllustration(context, data),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    data.title,
                    style: AppTypography.pageHeading.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      data.description,
                      style: AppTypography.bodyLarge.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SecurityBadge(
                    status: data.accentStatus,
                    variant: SecurityBadgeVariant.compact,
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIllustration(BuildContext context, _OnboardingPageData data) {
    final securityColors = context.securityColors;
    final isDark = context.isDarkMode;
    final color = securityColors.colorForStatus(data.accentStatus);
    final bg = securityColors.containerForStatus(data.accentStatus);
    final border = securityColors.borderForStatus(data.accentStatus);

    return Center(
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: AppDimensions.borderWidthThin),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.2 : 0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              data.icon,
              size: 58,
              color: color,
            ),
            Positioned(
              right: 18,
              bottom: 18,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: AppDimensions.borderWidthThin),
                ),
                child: Icon(
                  data.secondaryIcon,
                  size: 16,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (index) => _buildIndicator(index, theme),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _isLastPage ? 'Get Started' : 'Continue',
            onPressed: _nextPage,
            variant: AppButtonVariant.primary,
            trailingIcon: _isLastPage ? null : Icons.arrow_forward_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index, ThemeData theme) {
    final isActive = _currentPage == index;

    return AnimatedContainer(
      duration: AppDurations.normal,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
