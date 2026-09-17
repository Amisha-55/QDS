import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/widgets/app_button.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// A standardized dialog following the QDS design foundation.
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.securityStatus,
    this.confirmText = 'Confirm',
    this.cancelText = 'Cancel',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  final String title;
  final String? message;
  final Widget? content;
  final QdsSecurityStatus? securityStatus;
  final String confirmText;
  final String cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  static Future<bool?> showConfirmation({
    required BuildContext context,
    required String title,
    String? message,
    QdsSecurityStatus? securityStatus,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AppDialog(
        title: title,
        message: message,
        securityStatus: securityStatus,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: AppDimensions.borderWidthThin,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (securityStatus != null) ...[
              SecurityBadge(
                status: securityStatus!,
                variant: SecurityBadgeVariant.compact,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(
              title,
              style: AppTypography.sectionHeading.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: AppTypography.bodyMedium.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: AppSpacing.md),
              content!,
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: cancelText,
                    variant: AppButtonVariant.outline,
                    size: AppButtonSize.small,
                    onPressed: onCancel ?? () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: confirmText,
                    variant: isDestructive
                        ? AppButtonVariant.destructive
                        : AppButtonVariant.primary,
                    size: AppButtonSize.small,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
