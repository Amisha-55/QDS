import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';
import 'package:qds/shared/animations/pulse_animation.dart';

enum SecurityBadgeVariant {
  compact,
  regular,
  detailed,
}

/// A standardized badge communicating semantic security state with icon, label, and colors.
class SecurityBadge extends StatelessWidget {
  const SecurityBadge({
    super.key,
    required this.status,
    this.variant = SecurityBadgeVariant.regular,
    this.customLabel,
    this.supportingText,
    this.showPulse = false,
  });

  final QdsSecurityStatus status;
  final SecurityBadgeVariant variant;
  final String? customLabel;
  final String? supportingText;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    final securityColors = context.securityColors;
    final color = securityColors.colorForStatus(status);
    final bg = securityColors.containerForStatus(status);
    final border = securityColors.borderForStatus(status);
    final labelText = customLabel ?? status.label;

    if (variant == SecurityBadgeVariant.detailed) {
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
            _buildIcon(color, AppDimensions.iconMd),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    labelText,
                    style: AppTypography.cardTitle.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    supportingText ?? status.description,
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final isCompact = variant == SecurityBadgeVariant.compact;
    final horizontalPad = isCompact ? AppSpacing.sm : AppSpacing.md;
    final verticalPad = isCompact ? AppSpacing.xs : AppSpacing.sm;
    final iconSize = isCompact ? AppDimensions.iconXs : AppDimensions.iconSm;

    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.badgeRadius),
        border: Border.all(color: border, width: AppDimensions.borderWidthThin),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIcon(color, iconSize),
          SizedBox(width: isCompact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            labelText,
            style: isCompact
                ? AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  )
                : AppTypography.label.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
          ),
        ],
      ),
    );

    if (showPulse) {
      return PulseAnimation(
        isActive: true,
        child: badge,
      );
    }

    return badge;
  }

  Widget _buildIcon(Color color, double size) {
    return Icon(
      status.icon,
      size: size,
      color: color,
    );
  }
}
