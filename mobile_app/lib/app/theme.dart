import 'package:flutter/material.dart';
import 'package:qds/core/constants/app_constants.dart';
import 'package:qds/core/constants/security_constants.dart';

/// Semantic color palette for the QDS design system.
abstract final class AppColors {
  // Brand Primary & Secondary
  static const Color primaryLight = Color(0xFF1E40AF); // Sapphire Blue
  static const Color primaryContainerLight = Color(0xFFDBEAFE);
  static const Color primaryDark = Color(0xFF3B82F6); // Technical Blue
  static const Color primaryContainerDark = Color(0xFF1E3A8A);

  static const Color secondaryLight = Color(0xFF0284C7); // Slate Cyan
  static const Color secondaryDark = Color(0xFF38BDF8);

  // Neutral Light
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF1F5F9); // Slate 100
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF475569); // Slate 600
  static const Color textMutedLight = Color(0xFF94A3B8); // Slate 400
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color dividerLight = Color(0xFFF1F5F9);

  // Neutral Dark
  static const Color backgroundDark = Color(0xFF0B0F19); // Deep Obsidian
  static const Color surfaceDark = Color(0xFF111827); // Dark Slate
  static const Color surfaceElevatedDark = Color(0xFF1E293B); // Elevated Slate 800
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color borderSubduedDark = Color(0xFF334155);
  static const Color dividerDark = Color(0xFF1E293B);

  // Disabled
  static const Color disabledLight = Color(0xFF94A3B8);
  static const Color disabledContainerLight = Color(0xFFE2E8F0);
  static const Color disabledDark = Color(0xFF475569);
  static const Color disabledContainerDark = Color(0xFF1E293B);

  // Security Palette - Light
  static const Color trustedLight = Color(0xFF059669); // Emerald 600
  static const Color trustedContainerLight = Color(0xFFECFDF5);
  static const Color trustedBorderLight = Color(0xFFA7F3D0);

  static const Color verifiedLight = Color(0xFF0D9488); // Teal 600
  static const Color verifiedContainerLight = Color(0xFFF0FDFA);
  static const Color verifiedBorderLight = Color(0xFF99F6E4);

  static const Color monitoringLight = Color(0xFF2563EB); // Blue 600
  static const Color monitoringContainerLight = Color(0xFFEFF6FF);
  static const Color monitoringBorderLight = Color(0xFFBFDBFE);

  static const Color warningLight = Color(0xFFD97706); // Amber 600
  static const Color warningContainerLight = Color(0xFFFFFBEB);
  static const Color warningBorderLight = Color(0xFFFDE68A);

  static const Color suspiciousLight = Color(0xFFEA580C); // Orange 600
  static const Color suspiciousContainerLight = Color(0xFFFFF7ED);
  static const Color suspiciousBorderLight = Color(0xFFFED7AA);

  static const Color criticalLight = Color(0xFFDC2626); // Red 600
  static const Color criticalContainerLight = Color(0xFFFEF2F2);
  static const Color criticalBorderLight = Color(0xFFFECACA);

  static const Color infoLight = Color(0xFF0284C7);
  static const Color infoContainerLight = Color(0xFFF0F9FF);
  static const Color infoBorderLight = Color(0xFFBAE6FD);

  // Security Palette - Dark
  static const Color trustedDark = Color(0xFF10B981); // Emerald 500
  static const Color trustedContainerDark = Color(0xFF064E3B);
  static const Color trustedBorderDark = Color(0xFF065F46);

  static const Color verifiedDark = Color(0xFF14B8A6); // Teal 500
  static const Color verifiedContainerDark = Color(0xFF134E4A);
  static const Color verifiedBorderDark = Color(0xFF115E59);

  static const Color monitoringDark = Color(0xFF60A5FA); // Blue 400
  static const Color monitoringContainerDark = Color(0xFF1E3A8A);
  static const Color monitoringBorderDark = Color(0xFF1D4ED8);

  static const Color warningDark = Color(0xFFF59E0B); // Amber 500
  static const Color warningContainerDark = Color(0xFF78350F);
  static const Color warningBorderDark = Color(0xFF92400E);

  static const Color suspiciousDark = Color(0xFFFB923C); // Orange 400
  static const Color suspiciousContainerDark = Color(0xFF7C2D12);
  static const Color suspiciousBorderDark = Color(0xFF9A3412);

  static const Color criticalDark = Color(0xFFEF4444); // Red 500
  static const Color criticalContainerDark = Color(0xFF7F1D1D);
  static const Color criticalBorderDark = Color(0xFF991B1B);

  static const Color infoDark = Color(0xFF38BDF8);
  static const Color infoContainerDark = Color(0xFF0C4A6E);
  static const Color infoBorderDark = Color(0xFF0369A1);
}

/// ThemeExtension providing security-specific semantic colors.
class AppSecurityColors extends ThemeExtension<AppSecurityColors> {
  const AppSecurityColors({
    required this.trusted,
    required this.trustedContainer,
    required this.trustedBorder,
    required this.verified,
    required this.verifiedContainer,
    required this.verifiedBorder,
    required this.monitoring,
    required this.monitoringContainer,
    required this.monitoringBorder,
    required this.warning,
    required this.warningContainer,
    required this.warningBorder,
    required this.suspicious,
    required this.suspiciousContainer,
    required this.suspiciousBorder,
    required this.critical,
    required this.criticalContainer,
    required this.criticalBorder,
    required this.informational,
    required this.informationalContainer,
    required this.informationalBorder,
    required this.disabled,
    required this.disabledContainer,
  });

  final Color trusted;
  final Color trustedContainer;
  final Color trustedBorder;

  final Color verified;
  final Color verifiedContainer;
  final Color verifiedBorder;

  final Color monitoring;
  final Color monitoringContainer;
  final Color monitoringBorder;

  final Color warning;
  final Color warningContainer;
  final Color warningBorder;

  final Color suspicious;
  final Color suspiciousContainer;
  final Color suspiciousBorder;

  final Color critical;
  final Color criticalContainer;
  final Color criticalBorder;

  final Color informational;
  final Color informationalContainer;
  final Color informationalBorder;

  final Color disabled;
  final Color disabledContainer;

  static const AppSecurityColors light = AppSecurityColors(
    trusted: AppColors.trustedLight,
    trustedContainer: AppColors.trustedContainerLight,
    trustedBorder: AppColors.trustedBorderLight,
    verified: AppColors.verifiedLight,
    verifiedContainer: AppColors.verifiedContainerLight,
    verifiedBorder: AppColors.verifiedBorderLight,
    monitoring: AppColors.monitoringLight,
    monitoringContainer: AppColors.monitoringContainerLight,
    monitoringBorder: AppColors.monitoringBorderLight,
    warning: AppColors.warningLight,
    warningContainer: AppColors.warningContainerLight,
    warningBorder: AppColors.warningBorderLight,
    suspicious: AppColors.suspiciousLight,
    suspiciousContainer: AppColors.suspiciousContainerLight,
    suspiciousBorder: AppColors.suspiciousBorderLight,
    critical: AppColors.criticalLight,
    criticalContainer: AppColors.criticalContainerLight,
    criticalBorder: AppColors.criticalBorderLight,
    informational: AppColors.infoLight,
    informationalContainer: AppColors.infoContainerLight,
    informationalBorder: AppColors.infoBorderLight,
    disabled: AppColors.disabledLight,
    disabledContainer: AppColors.disabledContainerLight,
  );

  static const AppSecurityColors dark = AppSecurityColors(
    trusted: AppColors.trustedDark,
    trustedContainer: AppColors.trustedContainerDark,
    trustedBorder: AppColors.trustedBorderDark,
    verified: AppColors.verifiedDark,
    verifiedContainer: AppColors.verifiedContainerDark,
    verifiedBorder: AppColors.verifiedBorderDark,
    monitoring: AppColors.monitoringDark,
    monitoringContainer: AppColors.monitoringContainerDark,
    monitoringBorder: AppColors.monitoringBorderDark,
    warning: AppColors.warningDark,
    warningContainer: AppColors.warningContainerDark,
    warningBorder: AppColors.warningBorderDark,
    suspicious: AppColors.suspiciousDark,
    suspiciousContainer: AppColors.suspiciousContainerDark,
    suspiciousBorder: AppColors.suspiciousBorderDark,
    critical: AppColors.criticalDark,
    criticalContainer: AppColors.criticalContainerDark,
    criticalBorder: AppColors.criticalBorderDark,
    informational: AppColors.infoDark,
    informationalContainer: AppColors.infoContainerDark,
    informationalBorder: AppColors.infoBorderDark,
    disabled: AppColors.disabledDark,
    disabledContainer: AppColors.disabledContainerDark,
  );

  Color colorForStatus(QdsSecurityStatus status) => switch (status) {
    QdsSecurityStatus.trusted => trusted,
    QdsSecurityStatus.verified => verified,
    QdsSecurityStatus.monitoring => monitoring,
    QdsSecurityStatus.warning => warning,
    QdsSecurityStatus.suspicious => suspicious,
    QdsSecurityStatus.threatDetected => critical,
    QdsSecurityStatus.verificationFailed => critical,
  };

  Color containerForStatus(QdsSecurityStatus status) => switch (status) {
    QdsSecurityStatus.trusted => trustedContainer,
    QdsSecurityStatus.verified => verifiedContainer,
    QdsSecurityStatus.monitoring => monitoringContainer,
    QdsSecurityStatus.warning => warningContainer,
    QdsSecurityStatus.suspicious => suspiciousContainer,
    QdsSecurityStatus.threatDetected => criticalContainer,
    QdsSecurityStatus.verificationFailed => criticalContainer,
  };

  Color borderForStatus(QdsSecurityStatus status) => switch (status) {
    QdsSecurityStatus.trusted => trustedBorder,
    QdsSecurityStatus.verified => verifiedBorder,
    QdsSecurityStatus.monitoring => monitoringBorder,
    QdsSecurityStatus.warning => warningBorder,
    QdsSecurityStatus.suspicious => suspiciousBorder,
    QdsSecurityStatus.threatDetected => criticalBorder,
    QdsSecurityStatus.verificationFailed => criticalBorder,
  };

  Color colorForSeverity(ThreatSeverity severity) => switch (severity) {
    ThreatSeverity.none => trusted,
    ThreatSeverity.low => monitoring,
    ThreatSeverity.medium => warning,
    ThreatSeverity.high => suspicious,
    ThreatSeverity.critical => critical,
  };

  @override
  AppSecurityColors copyWith({
    Color? trusted,
    Color? trustedContainer,
    Color? trustedBorder,
    Color? verified,
    Color? verifiedContainer,
    Color? verifiedBorder,
    Color? monitoring,
    Color? monitoringContainer,
    Color? monitoringBorder,
    Color? warning,
    Color? warningContainer,
    Color? warningBorder,
    Color? suspicious,
    Color? suspiciousContainer,
    Color? suspiciousBorder,
    Color? critical,
    Color? criticalContainer,
    Color? criticalBorder,
    Color? informational,
    Color? informationalContainer,
    Color? informationalBorder,
    Color? disabled,
    Color? disabledContainer,
  }) {
    return AppSecurityColors(
      trusted: trusted ?? this.trusted,
      trustedContainer: trustedContainer ?? this.trustedContainer,
      trustedBorder: trustedBorder ?? this.trustedBorder,
      verified: verified ?? this.verified,
      verifiedContainer: verifiedContainer ?? this.verifiedContainer,
      verifiedBorder: verifiedBorder ?? this.verifiedBorder,
      monitoring: monitoring ?? this.monitoring,
      monitoringContainer: monitoringContainer ?? this.monitoringContainer,
      monitoringBorder: monitoringBorder ?? this.monitoringBorder,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      warningBorder: warningBorder ?? this.warningBorder,
      suspicious: suspicious ?? this.suspicious,
      suspiciousContainer: suspiciousContainer ?? this.suspiciousContainer,
      suspiciousBorder: suspiciousBorder ?? this.suspiciousBorder,
      critical: critical ?? this.critical,
      criticalContainer: criticalContainer ?? this.criticalContainer,
      criticalBorder: criticalBorder ?? this.criticalBorder,
      informational: informational ?? this.informational,
      informationalContainer: informationalContainer ?? this.informationalContainer,
      informationalBorder: informationalBorder ?? this.informationalBorder,
      disabled: disabled ?? this.disabled,
      disabledContainer: disabledContainer ?? this.disabledContainer,
    );
  }

  @override
  AppSecurityColors lerp(ThemeExtension<AppSecurityColors>? other, double t) {
    if (other is! AppSecurityColors) return this;
    return AppSecurityColors(
      trusted: Color.lerp(trusted, other.trusted, t) ?? trusted,
      trustedContainer: Color.lerp(trustedContainer, other.trustedContainer, t) ?? trustedContainer,
      trustedBorder: Color.lerp(trustedBorder, other.trustedBorder, t) ?? trustedBorder,
      verified: Color.lerp(verified, other.verified, t) ?? verified,
      verifiedContainer: Color.lerp(verifiedContainer, other.verifiedContainer, t) ?? verifiedContainer,
      verifiedBorder: Color.lerp(verifiedBorder, other.verifiedBorder, t) ?? verifiedBorder,
      monitoring: Color.lerp(monitoring, other.monitoring, t) ?? monitoring,
      monitoringContainer: Color.lerp(monitoringContainer, other.monitoringContainer, t) ?? monitoringContainer,
      monitoringBorder: Color.lerp(monitoringBorder, other.monitoringBorder, t) ?? monitoringBorder,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t) ?? warningContainer,
      warningBorder: Color.lerp(warningBorder, other.warningBorder, t) ?? warningBorder,
      suspicious: Color.lerp(suspicious, other.suspicious, t) ?? suspicious,
      suspiciousContainer: Color.lerp(suspiciousContainer, other.suspiciousContainer, t) ?? suspiciousContainer,
      suspiciousBorder: Color.lerp(suspiciousBorder, other.suspiciousBorder, t) ?? suspiciousBorder,
      critical: Color.lerp(critical, other.critical, t) ?? critical,
      criticalContainer: Color.lerp(criticalContainer, other.criticalContainer, t) ?? criticalContainer,
      criticalBorder: Color.lerp(criticalBorder, other.criticalBorder, t) ?? criticalBorder,
      informational: Color.lerp(informational, other.informational, t) ?? informational,
      informationalContainer: Color.lerp(informationalContainer, other.informationalContainer, t) ?? informationalContainer,
      informationalBorder: Color.lerp(informationalBorder, other.informationalBorder, t) ?? informationalBorder,
      disabled: Color.lerp(disabled, other.disabled, t) ?? disabled,
      disabledContainer: Color.lerp(disabledContainer, other.disabledContainer, t) ?? disabledContainer,
    );
  }
}

/// Standardized typography hierarchy for QDS.
abstract final class AppTypography {
  static const TextStyle largeTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static const TextStyle pageHeading = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.25,
    height: 1.3,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.15,
    height: 1.35,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.2,
  );

  // Numerical & security metric typography
  static const TextStyle metricLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.15,
  );

  static const TextStyle metricMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.2,
  );

  static const TextStyle metricSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.25,
  );

  static const TextStyle codeMono = TextStyle(
    fontSize: 13,
    fontFamily: 'monospace',
    letterSpacing: 0.2,
    height: 1.4,
  );
}

/// Main Theme configuration builder for QDS.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primaryLight,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainerLight,
      onPrimaryContainer: AppColors.primaryLight,
      secondary: AppColors.secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFE0F2FE),
      onSecondaryContainer: AppColors.secondaryLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textPrimaryLight,
      surfaceContainerHighest: AppColors.surfaceElevatedLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.borderLight,
      outlineVariant: AppColors.dividerLight,
      error: AppColors.criticalLight,
      onError: Colors.white,
      errorContainer: AppColors.criticalContainerLight,
      onErrorContainer: AppColors.criticalLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryLight,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidthThin,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.borderLight,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.criticalLight,
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: AppDimensions.borderWidthThin,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTypography.largeTitle,
        headlineMedium: AppTypography.pageHeading,
        titleLarge: AppTypography.sectionHeading,
        titleMedium: AppTypography.cardTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      extensions: const [
        AppSecurityColors.light,
      ],
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primaryDark,
      onPrimary: AppColors.backgroundDark,
      primaryContainer: AppColors.primaryContainerDark,
      onPrimaryContainer: Colors.white,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.backgroundDark,
      secondaryContainer: Color(0xFF075985),
      onSecondaryContainer: Colors.white,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textPrimaryDark,
      surfaceContainerHighest: AppColors.surfaceElevatedDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.borderDark,
      outlineVariant: AppColors.borderSubduedDark,
      error: AppColors.criticalDark,
      onError: AppColors.backgroundDark,
      errorContainer: AppColors.criticalContainerDark,
      onErrorContainer: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
          side: const BorderSide(
            color: AppColors.borderSubduedDark,
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.backgroundDark,
          elevation: 0,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.borderSubduedDark,
            width: AppDimensions.borderWidthThin,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
          textStyle: AppTypography.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: AppTypography.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevatedDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.borderSubduedDark,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.borderSubduedDark,
            width: AppDimensions.borderWidthThin,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryDark,
            width: AppDimensions.borderWidthFocus,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(
            color: AppColors.criticalDark,
            width: AppDimensions.borderWidthThin,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: AppDimensions.borderWidthThin,
        space: 1,
      ),
      textTheme: const TextTheme(
        headlineLarge: AppTypography.largeTitle,
        headlineMedium: AppTypography.pageHeading,
        titleLarge: AppTypography.sectionHeading,
        titleMedium: AppTypography.cardTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.button,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      extensions: const [
        AppSecurityColors.dark,
      ],
    );
  }
}

/// Convenience extensions on [BuildContext] for ergonomic access.
extension ThemeContextX on BuildContext {
  AppSecurityColors get securityColors =>
      Theme.of(this).extension<AppSecurityColors>() ?? AppSecurityColors.light;

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
