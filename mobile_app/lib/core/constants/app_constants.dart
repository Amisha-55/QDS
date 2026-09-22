/// Layout, spacing, and dimension constants for the QDS design system.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

abstract final class AppDimensions {
  // Screen & container paddings
  static const double screenPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double cardPaddingDense = 12.0;

  // Corner radii
  static const double cardRadius = 14.0;
  static const double cardRadiusSm = 8.0;
  static const double cardRadiusLg = 18.0;
  static const double inputRadius = 12.0;
  static const double buttonRadius = 12.0;
  static const double badgeRadius = 6.0;

  // Component heights
  static const double buttonHeight = 48.0;
  static const double buttonHeightSm = 36.0;
  static const double inputHeight = 48.0;

  // Icon sizes
  static const double iconXs = 14.0;
  static const double iconSm = 18.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;
  static const double iconXl = 40.0;

  // Border widths
  static const double borderWidthThin = 1.0;
  static const double borderWidthFocus = 1.5;
  static const double borderWidthThick = 2.0;
}

abstract final class AppDurations {
  static const Duration quick = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration medium = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
}
