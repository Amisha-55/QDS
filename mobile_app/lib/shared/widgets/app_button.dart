import 'package:flutter/material.dart';
import 'package:qds/app/theme.dart';
import 'package:qds/core/constants/app_constants.dart';

enum AppButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  text,
}

enum AppButtonSize {
  regular(height: AppDimensions.buttonHeight, fontSize: 15, iconSize: 18),
  small(height: AppDimensions.buttonHeightSm, fontSize: 13, iconSize: 15);

  const AppButtonSize({
    required this.height,
    required this.fontSize,
    required this.iconSize,
  });

  final double height;
  final double fontSize;
  final double iconSize;
}

/// A standardized button component adhering to the QDS design system.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool fullWidth;

  bool get _isEnabled => onPressed != null && !isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final securityColors = context.securityColors;

    final (Color bg, Color fg, BorderSide? border) = _getColors(theme, isDark, securityColors);

    Widget content = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: size.iconSize,
            height: size.iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: size.iconSize, color: fg),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          text,
          style: AppTypography.button.copyWith(
            fontSize: size.fontSize,
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (!isLoading && trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(trailingIcon, size: size.iconSize, color: fg),
        ],
      ],
    );

    final buttonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(
        Size(fullWidth ? double.infinity : 0, size.height),
      ),
      padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(
          horizontal: size == AppButtonSize.small ? AppSpacing.sm : AppSpacing.md,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return variant == AppButtonVariant.outline || variant == AppButtonVariant.text
              ? Colors.transparent
              : (isDark ? AppColors.disabledContainerDark : AppColors.disabledContainerLight);
        }
        return bg;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isDark ? AppColors.disabledDark : AppColors.disabledLight;
        }
        return fg;
      }),
      elevation: WidgetStateProperty.all(0),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          side: border ?? BorderSide.none,
        ),
      ),
    );

    return SizedBox(
      height: size.height,
      width: fullWidth ? double.infinity : null,
      child: TextButton(
        onPressed: _isEnabled ? onPressed : null,
        style: buttonStyle,
        child: content,
      ),
    );
  }

  (Color, Color, BorderSide?) _getColors(
    ThemeData theme,
    bool isDark,
    AppSecurityColors securityColors,
  ) {
    if (!_isEnabled) {
      final disabledFg = isDark ? AppColors.disabledDark : AppColors.disabledLight;
      final disabledBg = isDark ? AppColors.disabledContainerDark : AppColors.disabledContainerLight;
      final disabledBorder = (variant == AppButtonVariant.outline)
          ? BorderSide(color: disabledFg.withValues(alpha: 0.3), width: AppDimensions.borderWidthThin)
          : null;
      return (disabledBg, disabledFg, disabledBorder);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return (
          theme.colorScheme.primary,
          theme.colorScheme.onPrimary,
          null,
        );
      case AppButtonVariant.secondary:
        return (
          theme.colorScheme.primaryContainer,
          theme.colorScheme.onPrimaryContainer,
          null,
        );
      case AppButtonVariant.outline:
        return (
          Colors.transparent,
          theme.colorScheme.onSurface,
          BorderSide(
            color: theme.colorScheme.outline,
            width: AppDimensions.borderWidthThin,
          ),
        );
      case AppButtonVariant.destructive:
        return (
          securityColors.critical,
          Colors.white,
          null,
        );
      case AppButtonVariant.text:
        return (
          Colors.transparent,
          theme.colorScheme.primary,
          null,
        );
    }
  }
}
