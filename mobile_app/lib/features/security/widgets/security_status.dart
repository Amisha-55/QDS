import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/widgets/security_badge.dart';

/// Full-width or inline banner communicating an active security state with technical details.
class SecurityStatusBanner extends StatelessWidget {
  const SecurityStatusBanner({
    super.key,
    required this.status,
    this.title,
    this.description,
    this.action,
  });

  final QdsSecurityStatus status;
  final String? title;
  final String? description;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final color = securityColors.colorForStatus(status);
    final bg = securityColors.containerForStatus(status);
    final border = securityColors.borderForStatus(status);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: border, width: AppDimensions.borderWidthThin),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(status.icon, color: color, size: AppDimensions.iconMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title ?? status.label,
                  style: AppTypography.cardTitle.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  description ?? status.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  action!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact chip representation of security status for message bubbles, app bars, or list items.
class SecurityStatusChip extends StatelessWidget {
  const SecurityStatusChip({
    super.key,
    required this.status,
    this.onTap,
  });

  final QdsSecurityStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SecurityBadge(
        status: status,
        variant: SecurityBadgeVariant.compact,
      ),
    );
  }
}
