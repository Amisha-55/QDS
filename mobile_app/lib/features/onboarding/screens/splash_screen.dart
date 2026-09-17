import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/shared/animations/pulse_animation.dart';

/// Entry point splash screen featuring QDS branding and a clean security mark.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    await LocalStorage.instance.init();

    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) return;

      final isOnboardingCompleted = LocalStorage.instance.isOnboardingCompleted;
      final isSetupCompleted = LocalStorage.instance.isSetupCompleted;

      final String targetRoute;
      if (!isOnboardingCompleted) {
        targetRoute = AppRoutes.onboarding;
      } else if (!isSetupCompleted) {
        targetRoute = AppRoutes.setup;
      } else {
        targetRoute = AppRoutes.home;
      }

      Navigator.pushReplacementNamed(context, targetRoute);
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.isDarkMode;

    return Scaffold(
      body: SafeArea(
        child: SizedBox.expand(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  _buildSecurityLogo(context, isDark),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'QDS',
                    style: AppTypography.largeTitle.copyWith(
                      color: theme.colorScheme.onSurface,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Secure communication. Verified by design.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'Quantum-Inspired Digital Signature Security',
                    style: AppTypography.caption.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityLogo(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return PulseAnimation(
      isActive: true,
      minScale: 0.96,
      maxScale: 1.0,
      duration: const Duration(milliseconds: 1600),
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.16 : 0.08),
          shape: BoxShape.circle,
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.35 : 0.2),
            width: AppDimensions.borderWidthThin,
          ),
        ),
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 42,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
