import 'package:flutter/material.dart';
import 'package:qds/app/routes.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/core/storage/local_storage.dart';
import 'package:qds/shared/widgets/app_button.dart';
import 'package:qds/shared/widgets/app_card.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Screen displaying the current local identity profile for the demonstration.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = LocalStorage.instance.displayName ?? 'Demonstration User';
    final role = LocalStorage.instance.role;
    final roleLabel = role != null ? '${role.code} • ${role.label}' : 'Unassigned';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity Profile'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: AppDimensions.borderWidthThin,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          role?.code ?? '?',
                          style: AppTypography.pageHeading.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: AppTypography.cardTitle.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roleLabel,
                            style: AppTypography.bodySmall.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SecurityBadge(
                      status: QdsSecurityStatus.trusted,
                      variant: SecurityBadgeVariant.compact,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                title: 'Demonstration Role',
                child: Text(
                  role?.description ?? 'No prototype role selected yet.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                text: 'Change Role / Reset Identity',
                variant: AppButtonVariant.outline,
                icon: Icons.sync_rounded,
                onPressed: () => _handleReset(context, displayName, roleLabel),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReset(BuildContext context, String displayName, String roleLabel) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset Identity & Role?'),
          content: Text(
            'This will clear your assigned identity ($displayName, $roleLabel). '
            'You will return to the setup screen to select role X or Y again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.securityColors.critical,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Reset Identity'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await LocalStorage.instance.clearIdentity();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.setup,
        (route) => false,
      );
    }
  }
}
