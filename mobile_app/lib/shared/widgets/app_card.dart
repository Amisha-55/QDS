import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';

/// A standardized card component adhering to the QDS design language.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppDimensions.cardPadding),
    this.margin,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
    this.borderRadius,
    this.securityStatus,
    this.title,
    this.subtitle,
    this.trailing,
    this.isElevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;
  final BorderRadiusGeometry? borderRadius;
  final QdsSecurityStatus? securityStatus;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool isElevated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final securityColors = context.securityColors;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppDimensions.cardRadius);

    Color effectiveBorderColor = borderColor ?? theme.colorScheme.outline;
    Color effectiveBgColor = backgroundColor ??
        (isElevated ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface);

    if (securityStatus != null) {
      effectiveBorderColor = securityColors.borderForStatus(securityStatus!);
    }

    Widget content = child;

    if (title != null || subtitle != null || trailing != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title != null)
                      Text(
                        title!,
                        style: AppTypography.cardTitle.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      );
    }

    final cardContent = InkWell(
      onTap: onTap,
      borderRadius: effectiveRadius as BorderRadius,
      child: Padding(
        padding: padding,
        child: content,
      ),
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: securityStatus != null
              ? AppDimensions.borderWidthFocus
              : AppDimensions.borderWidthThin,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: cardContent,
      ),
    );
  }
}
