import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/shared/widgets/app_button.dart';

/// A standardized error presentation component adhering to the QDS design language.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryText = 'Try Again',
    this.icon = Icons.error_outline_rounded,
    this.isCentered = true,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryText;
  final IconData icon;
  final bool isCentered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: securityColors.criticalContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: securityColors.criticalBorder,
                width: AppDimensions.borderWidthThin,
              ),
            ),
            child: Icon(
              icon,
              color: securityColors.critical,
              size: AppDimensions.iconMd,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.sectionHeading.copyWith(
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: retryText,
              variant: AppButtonVariant.outline,
              size: AppButtonSize.small,
              fullWidth: false,
              icon: Icons.refresh_rounded,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );

    if (isCentered) {
      return Center(child: content);
    }
    return content;
  }
}
